using System.Security.Claims;
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

    private string? GetCompanyId() => User.FindFirst("companyId")?.Value;
    private string? GetUserId() => User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

    private string GetClientIp()
    {
        var forwarded = Request.Headers["X-Forwarded-For"].FirstOrDefault();
        if (!string.IsNullOrEmpty(forwarded))
        {
            return forwarded.Split(',').FirstOrDefault()?.Trim() ?? "unknown";
        }
        return HttpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";
    }

    private async Task<IpConfig?> FindMatchingConfigAsync(string companyId, string clientIp, double lat, double lng)
    {
        var configs = await _ipConfigService.GetActiveByCompanyAsync(companyId);

        return configs.FirstOrDefault(c =>
            c.AllowedIp == clientIp &&
            GeoUtils.DistanceInMeters(c.GpsCenter.Lat, c.GpsCenter.Lng, lat, lng) <= c.RadiusMeters);
    }

    /// Xác định Đúng giờ/Đi muộn dựa trên ca làm việc hiện tại của nhân viên.
    /// Flexible Time không bị ràng buộc khung giờ cố định -> luôn OnTime lúc check-in.
    /// LƯU Ý: so sánh theo giờ UTC của server - chưa xử lý múi giờ công ty, coi như
    /// server và công ty cùng múi giờ (đủ dùng cho đồ án, ghi chú để cải tiến sau).
    private static string DetermineCheckInStatus(User employee, DateTime checkInTimeUtc)
    {
        if (employee.CurrentShiftType == "Flexible")
        {
            return "OnTime";
        }

        if (TimeSpan.TryParse(employee.CurrentShiftStart, out var shiftStart))
        {
            var checkInTimeOfDay = checkInTimeUtc.TimeOfDay;
            return checkInTimeOfDay > shiftStart ? "Late" : "OnTime";
        }

        return "OnTime";
    }

    [HttpGet("history")]
    public async Task<IActionResult> GetHistory([FromQuery] int year, [FromQuery] int month)
    {
        var companyId = GetCompanyId();
        var userId = GetUserId();
        if (string.IsNullOrEmpty(companyId) || string.IsNullOrEmpty(userId))
        {
            return Forbid();
        }

        if (month < 1 || month > 12)
        {
            return BadRequest(new { message = "Tháng không hợp lệ." });
        }

        var fromDate = new DateTime(year, month, 1);
        var toDate = fromDate.AddMonths(1).AddDays(-1);

        var records = await _attendanceService.GetHistoryByUserAsync(companyId, userId, fromDate, toDate);
        var attendanceDates = records.Select(r => r.WorkDate).ToHashSet();

        var items = records.Select(r => new AttendanceHistoryItemResponse
        {
            WorkDate = r.WorkDate,
            CheckInTime = r.CheckInTime,
            CheckOutTime = r.CheckOutTime,
            Status = r.Status,
            WorkingHours = r.WorkingHours
        }).ToList();

        // Gộp thêm các ngày nghỉ phép ĐÃ DUYỆT (không có bản ghi check-in thật) vào lịch sử -
        // ngày nào đã có check-in thật thì ưu tiên dữ liệu thật, bỏ qua ngày nghỉ phép trùng.
        var approvedLeaves = await _leaveRequestService.GetApprovedInRangeAsync(companyId, userId, fromDate, toDate);
        foreach (var leave in approvedLeaves)
        {
            var rangeStart = leave.StartDate > fromDate ? leave.StartDate : fromDate;
            var rangeEnd = leave.EndDate < toDate ? leave.EndDate : toDate;

            for (var d = rangeStart; d <= rangeEnd; d = d.AddDays(1))
            {
                if (attendanceDates.Contains(d))
                {
                    continue;
                }

                items.Add(new AttendanceHistoryItemResponse
                {
                    WorkDate = d,
                    Status = leave.IsPaid == true ? "PaidLeave" : "UnpaidLeave",
                    LeaveType = leave.Type
                });
            }
        }

        items = items.OrderByDescending(i => i.WorkDate).ToList();

        var totalHours = Math.Round(items.Sum(i => i.WorkingHours), 2);

        // Ngày nghỉ phép CÓ LƯƠNG vẫn tính là ngày công hợp lệ - theo đúng quy định đã thống nhất.
        var daysWorked = items.Count(i => i.CheckInTime is not null || i.Status == "PaidLeave");

        // Đếm số ngày làm việc (Thứ 2 - Thứ 6) từ đầu tháng tới hôm nay (nếu là tháng hiện
        // tại) hoặc hết tháng (nếu là tháng đã qua) - dùng làm mẫu số "X/Y ngày công".
        var today = DateTime.UtcNow.Date;
        var countUntil = (year == today.Year && month == today.Month) ? today : toDate;
        var totalWorkdays = 0;
        for (var d = fromDate; d <= countUntil; d = d.AddDays(1))
        {
            if (d.DayOfWeek != DayOfWeek.Saturday && d.DayOfWeek != DayOfWeek.Sunday)
            {
                totalWorkdays++;
            }
        }

        return Ok(new AttendanceHistoryResponse
        {
            Items = items,
            TotalHours = totalHours,
            DaysWorked = daysWorked,
            TotalWorkdaysInMonth = totalWorkdays
        });
    }

    [HttpGet("today")]
    public async Task<IActionResult> GetTodayStatus()
    {
        var companyId = GetCompanyId();
        var userId = GetUserId();
        if (string.IsNullOrEmpty(companyId) || string.IsNullOrEmpty(userId))
        {
            return Forbid();
        }

        var today = DateTime.UtcNow.Date;
        var record = await _attendanceService.GetByUserAndDateAsync(companyId, userId, today);

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
            checkedIn = record.CheckInTime is not null,
            checkedOut = record.CheckOutTime is not null,
            checkInTime = record.CheckInTime?.ToString("o"),
            workingHours = record.CheckOutTime is not null ? record.WorkingHours : (double?)null
        });
    }

    [HttpPost("check-in")]
    public async Task<IActionResult> CheckIn([FromBody] CheckInOutRequest request)
    {
        var companyId = GetCompanyId();
        var userId = GetUserId();
        if (string.IsNullOrEmpty(companyId) || string.IsNullOrEmpty(userId))
        {
            return Forbid();
        }

        var today = DateTime.UtcNow.Date;

        var existing = await _attendanceService.GetByUserAndDateAsync(companyId, userId, today);
        if (existing is not null && existing.CheckInTime is not null)
        {
            return Conflict(new { message = "Bạn đã check-in hôm nay rồi." });
        }

        var clientIp = GetClientIp();
        var configs = await _ipConfigService.GetActiveByCompanyAsync(companyId);

        if (configs.Count == 0)
        {
            return BadRequest(new { message = "Công ty chưa cấu hình IP cho phép chấm công. Vui lòng liên hệ Admin." });
        }

        var matched = await FindMatchingConfigAsync(companyId, clientIp, request.Lat, request.Lng);
        if (matched is null)
        {
            await _auditLogService.LogAsync(
                companyId, userId, "CHECK_IN_FAILED",
                $"IP hoặc GPS không khớp cấu hình. IP={clientIp}, Lat={request.Lat}, Lng={request.Lng}");

            return StatusCode(403, new
            {
                message = "Xác thực thất bại. Vui lòng đảm bảo đang kết nối đúng mạng và ở trong khu vực công ty."
            });
        }

        var employee = await _userService.GetByIdAsync(companyId, userId);
        if (employee is null)
        {
            return NotFound(new { message = "Không tìm thấy thông tin nhân viên." });
        }

        var checkInTime = DateTime.UtcNow;

        var record = new AttendanceRecord
        {
            CompanyId = companyId,
            UserId = userId,
            WorkDate = today,
            CheckInTime = checkInTime,
            CheckInLocation = new GeoLocation { Lat = request.Lat, Lng = request.Lng },
            CheckInIp = clientIp,
            CheckInDeviceId = request.DeviceId,
            Status = DetermineCheckInStatus(employee, checkInTime)
        };

        await _attendanceService.CreateAsync(record);
        await _auditLogService.LogAsync(companyId, userId, "CHECK_IN_SUCCESS");

        return Ok(new { message = "Check-in thành công.", checkInTime = record.CheckInTime });
    }

    [HttpPost("check-out")]
    public async Task<IActionResult> CheckOut([FromBody] CheckInOutRequest request)
    {
        var companyId = GetCompanyId();
        var userId = GetUserId();
        if (string.IsNullOrEmpty(companyId) || string.IsNullOrEmpty(userId))
        {
            return Forbid();
        }

        var today = DateTime.UtcNow.Date;

        var existing = await _attendanceService.GetByUserAndDateAsync(companyId, userId, today);
        if (existing is null || existing.CheckInTime is null)
        {
            return BadRequest(new { message = "Bạn chưa check-in hôm nay." });
        }
        if (existing.CheckOutTime is not null)
        {
            return Conflict(new { message = "Bạn đã check-out hôm nay rồi." });
        }

        var clientIp = GetClientIp();
        var matched = await FindMatchingConfigAsync(companyId, clientIp, request.Lat, request.Lng);
        if (matched is null)
        {
            await _auditLogService.LogAsync(
                companyId, userId, "CHECK_OUT_FAILED",
                $"IP hoặc GPS không khớp cấu hình. IP={clientIp}, Lat={request.Lat}, Lng={request.Lng}");

            return StatusCode(403, new
            {
                message = "Xác thực thất bại. Vui lòng đảm bảo đang kết nối đúng mạng và ở trong khu vực công ty."
            });
        }

        var checkOutTime = DateTime.UtcNow;
        var workingHours = Math.Round((checkOutTime - existing.CheckInTime!.Value).TotalHours, 2);

        // Giữ nguyên Status đã xác định lúc check-in (OnTime/Late) - check-out chỉ cập nhật
        // giờ ra + tổng giờ làm, KHÔNG ghi đè lại trạng thái đúng giờ/đi muộn.
        await _attendanceService.UpdateCheckOutAsync(
            companyId, userId, today, checkOutTime,
            new GeoLocation { Lat = request.Lat, Lng = request.Lng },
            clientIp, request.DeviceId, workingHours,
            existing.Status
        );

        await _auditLogService.LogAsync(companyId, userId, "CHECK_OUT_SUCCESS");

        return Ok(new { message = "Check-out thành công.", checkOutTime, workingHours });
    }
}