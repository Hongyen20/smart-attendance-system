using System.Globalization;
using AttendanceApi.Models;
using AttendanceApi.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AttendanceApi.Controllers;

// BÁO CÁO CHẤM CÔNG CHO ADMIN

//     ?mode=day&date=2026-10-01            (xem 1 ngày)
//     ?mode=month&year=2026&month=10       (xem cả tháng)
//     &status=Late                         (lọc trạng thái, bỏ trống = tất cả)
//     &search=an                           (tìm theo tên hoặc mã NV)
//     &page=1&pageSize=10
[ApiController]
[Route("api/admin/reports")]
[Authorize(Roles = "Admin")]
public class AdminReportController : ControllerBase
{
    private const int MonthsInChart = 6;

    // Các hành động chấm công được hiển thị ở "Hoạt động gần đây".
    private static readonly HashSet<string> ActivityActions = new()
    {
        "CHECK_IN_SUCCESS",
        "CHECK_IN_FAILED",
        "CHECK_OUT_SUCCESS",
        "CHECK_OUT_FAILED"
    };

    private static readonly string[] ValidStatuses =
    {
        "OnTime", "Late", "Absent", "BusinessTrip", "Leave", "Other"
    };

    // Giờ Việt Nam = UTC+7 (dùng để tính số phút đi trễ).
    private static readonly TimeSpan VnOffset = TimeSpan.FromHours(7);

    private readonly UserService _userService;
    private readonly AttendanceRecordService _attendanceService;
    private readonly LeaveRequestService _leaveRequestService;
    private readonly BusinessTripRequestService _businessTripRequestService;
    private readonly AuditLogService _auditLogService;

    public AdminReportController(
        UserService userService,
        AttendanceRecordService attendanceService,
        LeaveRequestService leaveRequestService,
        BusinessTripRequestService businessTripRequestService,
        AuditLogService auditLogService)
    {
        _userService = userService;
        _attendanceService = attendanceService;
        _leaveRequestService = leaveRequestService;
        _businessTripRequestService = businessTripRequestService;
        _auditLogService = auditLogService;
    }

    // COUNTS

    private sealed class Counts
    {
        public int OnTime;
        public int Late;
        public int Absent;
        public int BusinessTrip;
        public int Leave;
        public int Other;

        public int Total =>
            OnTime + Late + Absent + BusinessTrip + Leave + Other;

        public void Add(string status)
        {
            switch (status)
            {
                case "OnTime": OnTime++; break;
                case "Late": Late++; break;
                case "Absent": Absent++; break;
                case "BusinessTrip": BusinessTrip++; break;
                case "Leave": Leave++; break;
                default: Other++; break;
            }
        }

        public void Merge(Counts other)
        {
            OnTime += other.OnTime;
            Late += other.Late;
            Absent += other.Absent;
            BusinessTrip += other.BusinessTrip;
            Leave += other.Leave;
            Other += other.Other;
        }

        public Dictionary<string, object> ToDto(
            string? keyName = null,
            string? keyValue = null)
        {
            var dto = new Dictionary<string, object>();

            if (keyName is not null && keyValue is not null)
            {
                dto[keyName] = keyValue;
            }

            dto["onTime"] = OnTime;
            dto["late"] = Late;
            dto["absent"] = Absent;
            dto["businessTrip"] = BusinessTrip;
            dto["leave"] = Leave;
            dto["other"] = Other;

            return dto;
        }
    }

    // REPORT

    [HttpGet("attendance")]
    public async Task<IActionResult> GetAttendanceReport(
        [FromQuery] string mode = "day",
        [FromQuery] string? date = null,
        [FromQuery] int year = 0,
        [FromQuery] int month = 0,
        [FromQuery] string? status = null,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] string? search = null)
    {
        var companyId = User.FindFirst("companyId")?.Value;

        if (string.IsNullOrEmpty(companyId))
        {
            return Forbid();
        }

        // "Hôm nay" tính theo UTC để khớp với cách check-in đang lưu WorkDate.
        var today = DateTime.UtcNow.Date;

        var isDayMode =
            !string.Equals(mode, "month", StringComparison.OrdinalIgnoreCase);

        var selectedDay = today;

        if (isDayMode)
        {
            if (!string.IsNullOrWhiteSpace(date))
            {
                if (!DateTime.TryParseExact(
                        date,
                        "yyyy-MM-dd",
                        CultureInfo.InvariantCulture,
                        DateTimeStyles.None,
                        out var parsedDate))
                {
                    return BadRequest(new
                    {
                        message = "Ngày không hợp lệ."
                    });
                }

                selectedDay = parsedDate.Date;
            }

            // Không cho xem ngày tương lai.
            if (selectedDay > today)
            {
                selectedDay = today;
            }

            year = selectedDay.Year;
            month = selectedDay.Month;
        }
        else
        {
            if (year == 0 || month == 0)
            {
                year = today.Year;
                month = today.Month;
            }

            if (month < 1 || month > 12 || year < 2000 || year > 2100)
            {
                return BadRequest(new
                {
                    message = "Tháng hoặc năm không hợp lệ."
                });
            }
        }

        page = Math.Max(1, page);
        pageSize = Math.Clamp(pageSize, 1, 100);

        var statusFilter =
            ValidStatuses.FirstOrDefault(s =>
                string.Equals(s, status?.Trim(), StringComparison.OrdinalIgnoreCase));

        var selectedStart = new DateTime(year, month, 1);

        var selectedEnd = selectedStart.AddMonths(1).AddDays(-1);

        var chartStart = selectedStart.AddMonths(-(MonthsInChart - 1));

        // Khoảng dữ liệu cần lấy: phủ 6 tháng biểu đồ, hôm nay,
        // và vài ngày trước ngày được chọn (để so sánh với ngày làm việc trước đó).
        var fetchFrom =
            new[] { chartStart, today, selectedDay.AddDays(-4) }.Min();

        var fetchTo = selectedEnd > today ? selectedEnd : today;

        // 1. NHÂN VIÊN (chỉ Employee đang hoạt động, không tính Admin)

        var employees =
            (await _userService.GetAllByCompanyAsync(companyId))
                .Where(u => u.Role == "Employee" && u.Status == "Active")
                .ToList();

        // 2. DỮ LIỆU THÔ (mỗi loại 1 truy vấn)

        var records =
            await _attendanceService.GetByCompanyAndDateRangeAsync(
                companyId, fetchFrom, fetchTo);

        var leaves =
            await _leaveRequestService.GetApprovedInRangeByCompanyAsync(
                companyId, fetchFrom, fetchTo);

        var trips =
            await _businessTripRequestService.GetApprovedInRangeByCompanyAsync(
                companyId, fetchFrom, fetchTo);

        var recordMap = new Dictionary<(string UserId, DateTime Day), AttendanceRecord>();

        foreach (var r in records)
        {
            recordMap.TryAdd((r.UserId, r.WorkDate.Date), r);
        }

        var leavesByUser =
            leaves
                .GroupBy(l => l.UserId)
                .ToDictionary(g => g.Key, g => g.ToList());

        var tripsByUser =
            trips
                .GroupBy(t => t.UserId)
                .ToDictionary(g => g.Key, g => g.ToList());

        LeaveRequest? FindLeave(string userId, DateTime day)
        {
            return leavesByUser.TryGetValue(userId, out var list)
                ? list.FirstOrDefault(l =>
                    l.StartDate.Date <= day && l.EndDate.Date >= day)
                : null;
        }

        BusinessTripRequest? FindTrip(string userId, DateTime day)
        {
            return tripsByUser.TryGetValue(userId, out var list)
                ? list.FirstOrDefault(t =>
                    t.StartDate.Date <= day && t.EndDate.Date >= day)
                : null;
        }

        // Trạng thái của 1 nhân viên trong 1 ngày.
        // Trả về null nếu ngày đó không được tính.
        string? ResolveStatus(User user, DateTime day)
        {
            if (day > today)
            {
                return null;
            }

            if (recordMap.TryGetValue((user.Id, day), out var record))
            {
                return record.Status switch
                {
                    "Late" => "Late",
                    "Absent" => "Absent",
                    _ => "OnTime"
                };
            }

            if (day.DayOfWeek == DayOfWeek.Saturday ||
                day.DayOfWeek == DayOfWeek.Sunday)
            {
                return null;
            }

            if (day < user.CreatedAt.Date)
            {
                return null;
            }

            if (FindLeave(user.Id, day) is not null)
            {
                return "Leave";
            }

            if (FindTrip(user.Id, day) is not null)
            {
                return "BusinessTrip";
            }

            return day == today ? "Other" : "Absent";
        }

        Counts CountDay(DateTime day)
        {
            var counts = new Counts();

            foreach (var employee in employees)
            {
                var s = ResolveStatus(employee, day);

                if (s is not null)
                {
                    counts.Add(s);
                }
            }

            return counts;
        }

        // 3. THỐNG KÊ THEO THÁNG + THEO NGÀY

        var monthly = new List<(DateTime Month, Counts Counts)>();

        var daily = new List<(DateTime Date, Counts Counts)>();

        for (var i = 0; i < MonthsInChart; i++)
        {
            var monthStart = chartStart.AddMonths(i);

            var daysInMonth =
                DateTime.DaysInMonth(monthStart.Year, monthStart.Month);

            var monthCounts = new Counts();

            for (var d = 1; d <= daysInMonth; d++)
            {
                var day = new DateTime(monthStart.Year, monthStart.Month, d);

                if (day > today)
                {
                    break;
                }

                var dayCounts = CountDay(day);

                monthCounts.Merge(dayCounts);

                if (monthStart == selectedStart && dayCounts.Total > 0)
                {
                    daily.Add((day, dayCounts));
                }
            }

            monthly.Add((monthStart, monthCounts));
        }

        // 4. SỐ LIỆU CỦA PHẠM VI ĐƯỢC CHỌN (NGÀY HOẶC THÁNG)

        Counts summary;
        Counts previousSummary;

        if (isDayMode)
        {
            summary = CountDay(selectedDay);

            // Ngày làm việc trước đó (bỏ qua thứ 7, chủ nhật).
            var previousDay = selectedDay.AddDays(-1);

            while (previousDay.DayOfWeek == DayOfWeek.Saturday ||
                   previousDay.DayOfWeek == DayOfWeek.Sunday)
            {
                previousDay = previousDay.AddDays(-1);
            }

            previousSummary = CountDay(previousDay);
        }
        else
        {
            summary = monthly[^1].Counts;
            previousSummary = monthly[^2].Counts;
        }

        // 5. DANH SÁCH CHI TIẾT (NHÂN VIÊN x NGÀY)

        var keyword = (search ?? string.Empty).Trim().ToLowerInvariant();

        var filteredEmployees =
            employees
                .Where(u =>
                    keyword.Length == 0 ||
                    u.FullName.ToLowerInvariant().Contains(keyword) ||
                    u.Username.ToLowerInvariant().Contains(keyword))
                .OrderBy(u => u.FullName)
                .ToList();

        var days = new List<DateTime>();

        if (isDayMode)
        {
            days.Add(selectedDay);
        }
        else
        {
            var lastDay = selectedEnd < today ? selectedEnd : today;

            // Ngày mới nhất lên đầu.
            for (var d = lastDay; d >= selectedStart; d = d.AddDays(-1))
            {
                days.Add(d);
            }
        }

        var rows = new List<(User User, DateTime Day, string Status)>();

        foreach (var day in days)
        {
            foreach (var employee in filteredEmployees)
            {
                var s = ResolveStatus(employee, day);

                if (s is null)
                {
                    continue;
                }

                if (statusFilter is not null && s != statusFilter)
                {
                    continue;
                }

                rows.Add((employee, day, s));
            }
        }

        var totalItems = rows.Count;

        var totalPages =
            Math.Max(1, (int)Math.Ceiling(totalItems / (double)pageSize));

        if (page > totalPages)
        {
            page = totalPages;
        }

        var items =
            rows
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(row => BuildItem(
                    row.User,
                    row.Day,
                    row.Status,
                    recordMap.GetValueOrDefault((row.User.Id, row.Day)),
                    FindLeave(row.User.Id, row.Day),
                    FindTrip(row.User.Id, row.Day)))
                .ToList();

        // 6. RESPONSE

        return Ok(new
        {
            mode = isDayMode ? "day" : "month",
            date = isDayMode ? selectedDay.ToString("yyyy-MM-dd") : null,

            year,
            month,

            totalEmployees = employees.Count,

            summary = summary.ToDto(),
            previousSummary = previousSummary.ToDto(),

            daily = daily
                .Select(x => x.Counts.ToDto("date", x.Date.ToString("yyyy-MM-dd")))
                .ToList(),

            monthly = monthly
                .Select(x => x.Counts.ToDto("month", x.Month.ToString("yyyy-MM")))
                .ToList(),

            items,

            page,
            pageSize,
            totalItems,
            totalPages
        });
    }

    // TỔNG QUAN CHO TRANG CHỦ ADMIN
    //
    // GET /api/admin/reports/overview?days=7
    //
    // Trả về:
    // - today   : số lượt theo trạng thái của HÔM NAY (+ total).
    // - trend   : số lượt chấm công (đúng giờ + đi trễ) của từng ngày làm việc
    //             trong `days` ngày gần nhất.
    // - pending : số đơn đang chờ duyệt.
    //             shiftChange = null vì chưa kết nối ShiftChangeRequestService.

    [HttpGet("overview")]
    public async Task<IActionResult> GetOverview([FromQuery] int days = 7)
    {
        var companyId = User.FindFirst("companyId")?.Value;

        if (string.IsNullOrEmpty(companyId))
        {
            return Forbid();
        }

        days = Math.Clamp(days, 1, 60);

        var today = DateTime.UtcNow.Date;

        var from = today.AddDays(-(days - 1));

        var employees =
            (await _userService.GetAllByCompanyAsync(companyId))
                .Where(u => u.Role == "Employee" && u.Status == "Active")
                .ToList();

        var records =
            await _attendanceService.GetByCompanyAndDateRangeAsync(
                companyId, from, today);

        var leaves =
            await _leaveRequestService.GetApprovedInRangeByCompanyAsync(
                companyId, from, today);

        var trips =
            await _businessTripRequestService.GetApprovedInRangeByCompanyAsync(
                companyId, from, today);

        var resolver = new StatusResolver(today, records, leaves, trips);

        Counts CountDay(DateTime day)
        {
            var counts = new Counts();

            foreach (var employee in employees)
            {
                var status = resolver.Resolve(employee, day);

                if (status is not null)
                {
                    counts.Add(status);
                }
            }

            return counts;
        }

        // Xu hướng: chỉ lấy những ngày có dữ liệu (ngày làm việc).
        var trend = new List<object>();

        for (var d = from; d <= today; d = d.AddDays(1))
        {
            var c = CountDay(d);

            if (c.Total == 0)
            {
                continue;
            }

            trend.Add(new
            {
                date = d.ToString("yyyy-MM-dd"),
                checkedIn = c.OnTime + c.Late,
                onTime = c.OnTime,
                late = c.Late,
                absent = c.Absent
            });
        }

        var todayCounts = CountDay(today);

        var todayDto = todayCounts.ToDto("date", today.ToString("yyyy-MM-dd"));

        todayDto["total"] = todayCounts.Total;

        var pendingLeaves =
            await _leaveRequestService.GetPendingByCompanyAsync(companyId);

        var pendingTrips =
            await _businessTripRequestService.GetPendingByCompanyAsync(companyId);

        return Ok(new
        {
            totalEmployees = employees.Count,

            today = todayDto,

            trend,

            pending = new
            {
                leave = pendingLeaves.Count,
                businessTrip = pendingTrips.Count,
                shiftChange = (int?)null
            }
        });
    }

    // Xác định trạng thái của nhân viên trong 1 ngày
    // (cùng quy ước với endpoint báo cáo ở trên).

    private sealed class StatusResolver
    {
        private readonly DateTime _today;

        private readonly Dictionary<(string UserId, DateTime Day), AttendanceRecord> _records = new();

        private readonly Dictionary<string, List<LeaveRequest>> _leaves;

        private readonly Dictionary<string, List<BusinessTripRequest>> _trips;

        public StatusResolver(
            DateTime today,
            IEnumerable<AttendanceRecord> records,
            IEnumerable<LeaveRequest> leaves,
            IEnumerable<BusinessTripRequest> trips)
        {
            _today = today;

            foreach (var r in records)
            {
                _records.TryAdd((r.UserId, r.WorkDate.Date), r);
            }

            _leaves = leaves
                .GroupBy(l => l.UserId)
                .ToDictionary(g => g.Key, g => g.ToList());

            _trips = trips
                .GroupBy(t => t.UserId)
                .ToDictionary(g => g.Key, g => g.ToList());
        }

        public string? Resolve(User user, DateTime day)
        {
            if (day > _today)
            {
                return null;
            }

            if (_records.TryGetValue((user.Id, day), out var record))
            {
                return record.Status switch
                {
                    "Late" => "Late",
                    "Absent" => "Absent",
                    _ => "OnTime"
                };
            }

            if (day.DayOfWeek == DayOfWeek.Saturday ||
                day.DayOfWeek == DayOfWeek.Sunday)
            {
                return null;
            }

            if (day < user.CreatedAt.Date)
            {
                return null;
            }

            if (_leaves.TryGetValue(user.Id, out var leaveList) &&
                leaveList.Any(l => l.StartDate.Date <= day && l.EndDate.Date >= day))
            {
                return "Leave";
            }

            if (_trips.TryGetValue(user.Id, out var tripList) &&
                tripList.Any(t => t.StartDate.Date <= day && t.EndDate.Date >= day))
            {
                return "BusinessTrip";
            }

            return day == _today ? "Other" : "Absent";
        }
    }

    // HOẠT ĐỘNG GẦN ĐÂY
    //
    // GET /api/admin/reports/recent-activities?limit=5
    //
    // Lấy từ nhật ký (audit_logs): check-in / check-out thành công hoặc thất bại.
    // Không trả địa chỉ IP hay tọa độ ra ngoài.

    [HttpGet("recent-activities")]
    public async Task<IActionResult> GetRecentActivities([FromQuery] int limit = 5)
    {
        var companyId = User.FindFirst("companyId")?.Value;

        if (string.IsNullOrEmpty(companyId))
        {
            return Forbid();
        }

        limit = Math.Clamp(limit, 1, 20);

        var logs = await _auditLogService.GetByCompanyAsync(companyId, 200);

        var users = await _userService.GetAllByCompanyAsync(companyId);

        var nameById = users
            .GroupBy(u => u.Id)
            .ToDictionary(g => g.Key, g => g.First().FullName);

        var items =
            logs
                .Where(l => ActivityActions.Contains(l.Action))
                .Take(limit)
                .Select(l => BuildActivity(l, nameById))
                .ToList();

        return Ok(new { items });
    }

    private static object BuildActivity(
        AuditLog log,
        Dictionary<string, string> nameById)
    {
        var name = nameById.TryGetValue(log.UserId, out var fullName) &&
                   !string.IsNullOrWhiteSpace(fullName)
            ? fullName
            : "Nhân viên";

        var details = log.Details ?? string.Empty;

        var isTrip = details.StartsWith("Business trip", StringComparison.OrdinalIgnoreCase);

        string title;
        string tag;
        string tone;
        var note = string.Empty;

        switch (log.Action)
        {
            case "CHECK_IN_SUCCESS":
                title = isTrip ? $"{name} check-in công tác" : $"{name} đã check-in";
                tag = isTrip ? "Công tác" : "Check-in";
                tone = isTrip ? "info" : "success";
                break;

            case "CHECK_OUT_SUCCESS":
                title = isTrip ? $"{name} check-out công tác" : $"{name} đã check-out";
                tag = isTrip ? "Công tác" : "Check-out";
                tone = "info";
                break;

            case "CHECK_IN_FAILED":
                title = $"{name} check-in thất bại";
                tag = "Thất bại";
                tone = "danger";
                note = FailureReason(details);
                break;

            default: // CHECK_OUT_FAILED
                title = $"{name} check-out thất bại";
                tag = "Thất bại";
                tone = "danger";
                note = FailureReason(details);
                break;
        }

        return new
        {
            userId = log.UserId,
            action = log.Action,
            title,
            tag,
            tone,
            note,
            createdAt = ToUtcIso(log.CreatedAt)
        };
    }

    // Rút gọn lý do thất bại thành câu dễ hiểu (không lộ IP / tọa độ).
    private static string FailureReason(string details)
    {
        if (details.Contains("chưa đăng ký khuôn mặt", StringComparison.OrdinalIgnoreCase))
            return "Chưa đăng ký khuôn mặt";

        if (details.Contains("GPS không hợp lệ", StringComparison.OrdinalIgnoreCase))
            return "Ngoài phạm vi chấm công";

        if (details.Contains("IPv4 không khớp", StringComparison.OrdinalIgnoreCase))
            return "Sai Wi-Fi công ty";

        if (details.Contains("Xác thực khuôn mặt thất bại", StringComparison.OrdinalIgnoreCase))
            return "Sai khuôn mặt";

        if (details.Contains("IPv4", StringComparison.OrdinalIgnoreCase))
            return "Không xác định được mạng";

        return string.Empty;
    }

    // DETAIL ITEM

    private static object BuildItem(
        User user,
        DateTime day,
        string status,
        AttendanceRecord? record,
        LeaveRequest? leave,
        BusinessTripRequest? trip)
    {
        string note = status switch
        {
            "Leave" => leave?.IsPaid == false
                ? "Nghỉ phép (không lương)"
                : "Nghỉ phép",

            "BusinessTrip" => string.IsNullOrWhiteSpace(trip?.Destination)
                ? "Đi công tác"
                : $"Công tác {trip!.Destination}",

            "Absent" => "Không đi làm",

            "Other" => "Chưa chấm công",

            "Late" => JoinNotes(LateNote(user, record), EarlyLeaveNote(user, record)),

            _ => EarlyLeaveNote(user, record)
        };

        return new
        {
            date = day.ToString("yyyy-MM-dd"),

            // Model User chưa có mã nhân viên: tạm dùng Username làm mã.
            employeeCode = user.Username,
            fullName = user.FullName,

            status,

            checkInTime = ToUtcIso(record?.CheckInTime),
            checkOutTime = ToUtcIso(record?.CheckOutTime),

            note
        };
    }

    private static string LateNote(User user, AttendanceRecord? record)
    {
        if (record?.CheckInTime is null ||
            !TimeSpan.TryParse(user.CurrentShiftStart, out var shiftStart))
        {
            return string.Empty;
        }

        var checkInVn =
            DateTime.SpecifyKind(record.CheckInTime.Value, DateTimeKind.Utc)
                .Add(VnOffset);

        var minutes = (int)(checkInVn.TimeOfDay - shiftStart).TotalMinutes;

        return minutes > 0 ? $"Trễ {minutes} phút" : string.Empty;
    }

    // Về sớm: check-out sớm hơn giờ tan ca từ 15 phút trở lên.
    private static string EarlyLeaveNote(User user, AttendanceRecord? record)
    {
        if (record?.CheckOutTime is null ||
            user.CurrentShiftType == "Flexible" ||
            !TimeSpan.TryParse(user.CurrentShiftEnd, out var shiftEnd))
        {
            return string.Empty;
        }

        var checkOutVn =
            DateTime.SpecifyKind(record.CheckOutTime.Value, DateTimeKind.Utc)
                .Add(VnOffset);

        var minutes = (int)(shiftEnd - checkOutVn.TimeOfDay).TotalMinutes;

        return minutes >= 15 ? $"Ra sớm {minutes} phút" : string.Empty;
    }

    private static string JoinNotes(params string[] notes)
    {
        return string.Join("; ", notes.Where(n => !string.IsNullOrEmpty(n)));
    }

    private static string? ToUtcIso(DateTime? value)
    {
        if (value is null)
        {
            return null;
        }

        return DateTime
            .SpecifyKind(value.Value, DateTimeKind.Utc)
            .ToString("o");
    }
}