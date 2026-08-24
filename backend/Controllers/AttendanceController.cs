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

    public AttendanceController(
        AttendanceRecordService attendanceService,
        IpConfigService ipConfigService,
        AuditLogService auditLogService)
    {
        _attendanceService = attendanceService;
        _ipConfigService = ipConfigService;
        _auditLogService = auditLogService;
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

        var items = records.Select(r => new AttendanceHistoryItemResponse
        {
            WorkDate = r.WorkDate,
            CheckInTime = r.CheckInTime,
            CheckOutTime = r.CheckOutTime,
            Status = r.Status,
            WorkingHours = r.WorkingHours
        }).ToList();

        var totalHours = Math.Round(items.Sum(i => i.WorkingHours), 2);
        var daysWorked = items.Count(i => i.CheckInTime is not null);

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

        var record = new AttendanceRecord
        {
            CompanyId = companyId,
            UserId = userId,
            WorkDate = today,
            CheckInTime = DateTime.UtcNow,
            CheckInLocation = new GeoLocation { Lat = request.Lat, Lng = request.Lng },
            CheckInIp = clientIp,
            CheckInDeviceId = request.DeviceId,
            Status = "OnTime" // TODO: so sánh với ca làm việc thật khi tích hợp Shift/ShiftAssignment
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

        await _attendanceService.UpdateCheckOutAsync(
            companyId, userId, today, checkOutTime,
            new GeoLocation { Lat = request.Lat, Lng = request.Lng },
            clientIp, request.DeviceId, workingHours,
            "OnTime" // TODO: logic trạng thái thật khi tích hợp Shift
        );

        await _auditLogService.LogAsync(companyId, userId, "CHECK_OUT_SUCCESS");

        return Ok(new { message = "Check-out thành công.", checkOutTime, workingHours });
    }
}