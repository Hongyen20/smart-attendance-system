using System.Security.Claims;
using System.Net;
using AttendanceApi.DTOs;
using AttendanceApi.Models;
using AttendanceApi.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AttendanceApi.Controllers;

[ApiController]
[Route("api/attendance")]
[Authorize(Roles = "Employee")]
public class AttendanceController : ControllerBase
{
    private readonly AttendanceRecordService _attendanceService;
    private readonly IpConfigService _ipConfigService;
    private readonly AuditLogService _auditLogService;
    private readonly LeaveRequestService _leaveRequestService;
    private readonly UserService _userService;

    public AttendanceController(
        AttendanceRecordService attendanceService,
        IpConfigService ipConfigService,
        AuditLogService auditLogService,
        LeaveRequestService leaveRequestService,
        UserService userService)
    {
        _attendanceService = attendanceService;
        _ipConfigService = ipConfigService;
        _auditLogService = auditLogService;
        _leaveRequestService = leaveRequestService;
        _userService = userService;
    }

    private string? GetCompanyId()
        => User.FindFirst("companyId")?.Value;

    private string? GetUserId()
        => User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

    // VALIDATE PUBLIC IPV4

    private static bool IsValidIPv4(string ip)
    {
        if (string.IsNullOrWhiteSpace(ip))
        {
            return false;
        }

        return IPAddress.TryParse(ip, out var parsed)
               && parsed.AddressFamily ==
                  System.Net.Sockets.AddressFamily.InterNetwork;
    }

    // KIỂM TRA IP + GPS

    private async Task<IpConfig?> FindMatchingConfigAsync(
        string companyId,
        string publicIp,
        double lat,
        double lng)
    {
        var configs =
            await _ipConfigService.GetActiveByCompanyAsync(companyId);

        return configs.FirstOrDefault(config =>
            string.Equals(
                config.AllowedIp.Trim(),
                publicIp.Trim(),
                StringComparison.OrdinalIgnoreCase)
            &&
            GeoUtils.DistanceInMeters(
                config.GpsCenter.Lat,
                config.GpsCenter.Lng,
                lat,
                lng
            ) <= config.RadiusMeters
        );
    }

    // XÁC ĐỊNH ĐÚNG GIỜ / ĐI MUỘN
    // Xác định trạng thái check-in dựa trên ca làm việc hiện tại.
    //
    // Flexible:
    //     Không bị ràng buộc giờ bắt đầu cố định
    //     -> luôn OnTime.
    //
    // Ca cố định:
    //     Check-in sau giờ bắt đầu -> Late.
    private static string DetermineCheckInStatus(
        User employee,
        DateTime checkInTimeUtc)
    {
        if (employee.CurrentShiftType == "Flexible")
        {
            return "OnTime";
        }

        if (TimeSpan.TryParse(
                employee.CurrentShiftStart,
                out var shiftStart))
        {
            var checkInTimeOfDay =
                checkInTimeUtc.TimeOfDay;

            return checkInTimeOfDay > shiftStart
                ? "Late"
                : "OnTime";
        }

        return "OnTime";
    }

    // HISTORY

    [HttpGet("history")]
    public async Task<IActionResult> GetHistory(
        [FromQuery] int year,
        [FromQuery] int month)
    {
        var companyId = GetCompanyId();
        var userId = GetUserId();

        if (string.IsNullOrEmpty(companyId) ||
            string.IsNullOrEmpty(userId))
        {
            return Forbid();
        }

        if (month < 1 || month > 12)
        {
            return BadRequest(new
            {
                message = "Tháng không hợp lệ."
            });
        }

        var fromDate = new DateTime(year, month, 1);
        var toDate = fromDate
            .AddMonths(1)
            .AddDays(-1);

        var records =
            await _attendanceService.GetHistoryByUserAsync(
                companyId,
                userId,
                fromDate,
                toDate);

        var attendanceDates =
            records
                .Select(r => r.WorkDate)
                .ToHashSet();

        var items = records
            .Select(r => new AttendanceHistoryItemResponse
            {
                WorkDate = r.WorkDate,
                CheckInTime = r.CheckInTime,
                CheckOutTime = r.CheckOutTime,
                Status = r.Status,
                WorkingHours = r.WorkingHours
            })
            .ToList();

        // GỘP NGÀY NGHỈ PHÉP ĐÃ DUYỆT

        var approvedLeaves =
            await _leaveRequestService.GetApprovedInRangeAsync(
                companyId,
                userId,
                fromDate,
                toDate);

        foreach (var leave in approvedLeaves)
        {
            var rangeStart =
                leave.StartDate > fromDate
                    ? leave.StartDate
                    : fromDate;

            var rangeEnd =
                leave.EndDate < toDate
                    ? leave.EndDate
                    : toDate;

            for (
                var d = rangeStart;
                d <= rangeEnd;
                d = d.AddDays(1))
            {
                if (attendanceDates.Contains(d))
                {
                    continue;
                }

                items.Add(
                    new AttendanceHistoryItemResponse
                    {
                        WorkDate = d,
                        Status = leave.IsPaid == true
                            ? "PaidLeave"
                            : "UnpaidLeave",
                        LeaveType = leave.Type
                    });
            }
        }

        items = items
            .OrderByDescending(i => i.WorkDate)
            .ToList();

        var totalHours =
            Math.Round(
                items.Sum(i => i.WorkingHours),
                2);

        // Nghỉ phép có lương được tính là ngày công.
        var daysWorked =
            items.Count(i =>
                i.CheckInTime is not null ||
                i.Status == "PaidLeave");

        // TỔNG NGÀY LÀM VIỆC

        var today = DateTime.UtcNow.Date;

        var countUntil =
            (year == today.Year &&
             month == today.Month)
                ? today
                : toDate;

        var totalWorkdays = 0;

        for (
            var d = fromDate;
            d <= countUntil;
            d = d.AddDays(1))
        {
            if (d.DayOfWeek != DayOfWeek.Saturday &&
                d.DayOfWeek != DayOfWeek.Sunday)
            {
                totalWorkdays++;
            }
        }

        return Ok(
            new AttendanceHistoryResponse
            {
                Items = items,
                TotalHours = totalHours,
                DaysWorked = daysWorked,
                TotalWorkdaysInMonth = totalWorkdays
            });
    }

    // TODAY STATUS

    [HttpGet("today")]
    public async Task<IActionResult> GetTodayStatus()
    {
        var companyId = GetCompanyId();
        var userId = GetUserId();

        if (string.IsNullOrEmpty(companyId) ||
            string.IsNullOrEmpty(userId))
        {
            return Forbid();
        }

        var today = DateTime.UtcNow.Date;

        var record =
            await _attendanceService.GetByUserAndDateAsync(
                companyId,
                userId,
                today);

        if (record is null)
        {
            return Ok(new
            {
                checkedIn = false,
                checkedOut = false,
                checkInTime = (string?)null,
                workingHours = (double?)null
            });
        }

        return Ok(new
        {
            checkedIn =
                record.CheckInTime is not null,

            checkedOut =
                record.CheckOutTime is not null,

            checkInTime =
                record.CheckInTime?.ToString("o"),

            workingHours =
                record.CheckOutTime is not null
                    ? record.WorkingHours
                    : (double?)null
        });
    }

    // CHECK-IN

    [HttpPost("check-in")]
    public async Task<IActionResult> CheckIn(
        [FromBody] CheckInOutRequest request)
    {
        var companyId = GetCompanyId();
        var userId = GetUserId();

        if (string.IsNullOrEmpty(companyId) ||
            string.IsNullOrEmpty(userId))
        {
            return Forbid();
        }

        // 1. KIỂM TRA IP

        var publicIp = request.PublicIp.Trim();

        if (!IsValidIPv4(publicIp))
        {
            return BadRequest(new
            {
                message =
                    "Địa chỉ IP công cộng không hợp lệ."
            });
        }

        // 2. KIỂM TRA ĐÃ CHECK-IN CHƯA

        var today = DateTime.UtcNow.Date;

        var existing =
            await _attendanceService.GetByUserAndDateAsync(
                companyId,
                userId,
                today);

        if (existing is not null &&
            existing.CheckInTime is not null)
        {
            return Conflict(new
            {
                message =
                    "Bạn đã check-in hôm nay rồi."
            });
        }

        // 3. KIỂM TRA CẤU HÌNH IP

        var configs =
            await _ipConfigService.GetActiveByCompanyAsync(
                companyId);

        if (configs.Count == 0)
        {
            return BadRequest(new
            {
                message =
                    "Công ty chưa cấu hình IP cho phép chấm công. " +
                    "Vui lòng liên hệ Admin."
            });
        }

        // 4. KIỂM TRA IP + GPS

        var matched =
            await FindMatchingConfigAsync(
                companyId,
                publicIp,
                request.Lat,
                request.Lng);

        if (matched is null)
        {
            await _auditLogService.LogAsync(
                companyId,
                userId,
                "CHECK_IN_FAILED",
                $"IP hoặc GPS không khớp cấu hình. " +
                $"IP={publicIp}, " +
                $"Lat={request.Lat}, " +
                $"Lng={request.Lng}");

            return StatusCode(403, new
            {
                message =
                    "Xác thực thất bại. Vui lòng đảm bảo " +
                    "đang kết nối đúng mạng và ở trong " +
                    "khu vực công ty."
            });
        }

        // 5. LẤY THÔNG TIN NHÂN VIÊN

        var employee =
            await _userService.GetByIdAsync(
                companyId,
                userId);

        if (employee is null)
        {
            return NotFound(new
            {
                message =
                    "Không tìm thấy thông tin nhân viên."
            });
        }

        // 6. TẠO ATTENDANCE RECORD

        var checkInTime = DateTime.UtcNow;

        var record = new AttendanceRecord
        {
            CompanyId = companyId,
            UserId = userId,
            WorkDate = today,

            CheckInTime = checkInTime,

            CheckInLocation = new GeoLocation
            {
                Lat = request.Lat,
                Lng = request.Lng
            },

            CheckInIp = publicIp,

            CheckInDeviceId = request.DeviceId,

            Status =
                DetermineCheckInStatus(
                    employee,
                    checkInTime)
        };

        await _attendanceService.CreateAsync(record);

        await _auditLogService.LogAsync(
            companyId,
            userId,
            "CHECK_IN_SUCCESS");

        return Ok(new
        {
            message = "Check-in thành công.",
            checkInTime = record.CheckInTime
        });
    }

    // CHECK-OUT

    [HttpPost("check-out")]
    public async Task<IActionResult> CheckOut(
        [FromBody] CheckInOutRequest request)
    {
        var companyId = GetCompanyId();
        var userId = GetUserId();

        if (string.IsNullOrEmpty(companyId) ||
            string.IsNullOrEmpty(userId))
        {
            return Forbid();
        }

        // 1. KIỂM TRA IP

        var publicIp = request.PublicIp.Trim();

        if (!IsValidIPv4(publicIp))
        {
            return BadRequest(new
            {
                message =
                    "Địa chỉ IP công cộng không hợp lệ."
            });
        }

        // 2. LẤY ATTENDANCE HÔM NAY

        var today = DateTime.UtcNow.Date;

        var existing =
            await _attendanceService.GetByUserAndDateAsync(
                companyId,
                userId,
                today);

        if (existing is null ||
            existing.CheckInTime is null)
        {
            return BadRequest(new
            {
                message =
                    "Bạn chưa check-in hôm nay."
            });
        }

        if (existing.CheckOutTime is not null)
        {
            return Conflict(new
            {
                message =
                    "Bạn đã check-out hôm nay rồi."
            });
        }

        // 3. KIỂM TRA IP + GPS

        var matched =
            await FindMatchingConfigAsync(
                companyId,
                publicIp,
                request.Lat,
                request.Lng);

        if (matched is null)
        {
            await _auditLogService.LogAsync(
                companyId,
                userId,
                "CHECK_OUT_FAILED",
                $"IP hoặc GPS không khớp cấu hình. " +
                $"IP={publicIp}, " +
                $"Lat={request.Lat}, " +
                $"Lng={request.Lng}");

            return StatusCode(403, new
            {
                message =
                    "Xác thực thất bại. Vui lòng đảm bảo " +
                    "đang kết nối đúng mạng và ở trong " +
                    "khu vực công ty."
            });
        }

        // 4. TÍNH THỜI GIAN LÀM VIỆC

        var checkOutTime = DateTime.UtcNow;

        var workingHours =
            Math.Round(
                (
                    checkOutTime -
                    existing.CheckInTime!.Value
                ).TotalHours,
                2);

        // Giữ nguyên Status lúc check-in.
        await _attendanceService.UpdateCheckOutAsync(
            companyId,
            userId,
            today,
            checkOutTime,

            new GeoLocation
            {
                Lat = request.Lat,
                Lng = request.Lng
            },

            publicIp,
            request.DeviceId,
            workingHours,
            existing.Status
        );

        await _auditLogService.LogAsync(
            companyId,
            userId,
            "CHECK_OUT_SUCCESS");

        return Ok(new
        {
            message = "Check-out thành công.",
            checkOutTime,
            workingHours
        });
    }
}

