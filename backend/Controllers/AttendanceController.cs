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
    private readonly AttendanceRecordService _attendanceRecordService;
    private readonly IpConfigService _ipConfigService;

    public AttendanceController(AttendanceRecordService attendanceRecordService, IpConfigService ipConfigService)
    {
        _attendanceRecordService = attendanceRecordService;
        _ipConfigService = ipConfigService;
    }

    private string? GetCompanyId() => User.FindFirst("companyId")?.Value;
    private string? GetUserId() => User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

    private string GetCallerIp()
    {
        return Request.Headers["X-Forwarded-For"].FirstOrDefault()?.Split(',').FirstOrDefault()?.Trim()
               ?? HttpContext.Connection.RemoteIpAddress?.ToString()
               ?? "unknown";
    }

    // Kiểm tra GPS + IP so với các cấu hình đang bật của công ty.
    // Điều kiện hợp lệ: tồn tại 1 cấu hình mà IP khớp VÀ khoảng cách GPS <= bán kính.
    private async Task<(bool IsValid, string? ErrorMessage)> ValidateLocationAsync(
        string companyId, double lat, double lng)
    {
        var configs = await _ipConfigService.GetActiveByCompanyAsync(companyId);
        if (configs.Count == 0)
        {
            return (false, "Công ty chưa cấu hình IP cho phép check-in. Vui lòng liên hệ Admin.");
        }

        var callerIp = GetCallerIp();
        var matchingIpConfigs = configs.Where(c => c.AllowedIp == callerIp).ToList();

        if (matchingIpConfigs.Count == 0)
        {
            return (false, $"Địa chỉ IP hiện tại ({callerIp}) không thuộc mạng công ty.");
        }

        foreach (var config in matchingIpConfigs)
        {
            var distance = GeoUtils.DistanceInMeters(lat, lng, config.GpsCenter.Lat, config.GpsCenter.Lng);
            if (distance <= config.RadiusMeters)
            {
                return (true, null);
            }
        }

        return (false, "Vị trí GPS hiện tại nằm ngoài phạm vi cho phép của công ty.");
    }

    [HttpGet("today")]
    public async Task<IActionResult> GetToday()
    {
        var companyId = GetCompanyId();
        var userId = GetUserId();
        if (string.IsNullOrEmpty(companyId) || string.IsNullOrEmpty(userId))
        {
            return Forbid();
        }

        var record = await _attendanceRecordService.GetByUserAndDateAsync(companyId, userId, DateTime.UtcNow);
        if (record is null)
        {
            return Ok(new { checkedIn = false, checkedOut = false });
        }

        return Ok(new
        {
            checkedIn = record.CheckInTime != null,
            checkedOut = record.CheckOutTime != null,
            checkInTime = record.CheckInTime,
            checkOutTime = record.CheckOutTime,
            status = record.Status,
            workingHours = record.WorkingHours
        });
    }

    [HttpPost("check-in")]
    public async Task<IActionResult> CheckIn([FromBody] CheckInRequest request)
    {
        var companyId = GetCompanyId();
        var userId = GetUserId();
        if (string.IsNullOrEmpty(companyId) || string.IsNullOrEmpty(userId))
        {
            return Forbid();
        }

        var today = DateTime.UtcNow;
        var existing = await _attendanceRecordService.GetByUserAndDateAsync(companyId, userId, today);
        if (existing is not null && existing.CheckInTime is not null)
        {
            return Conflict(new { message = "Bạn đã check-in hôm nay rồi." });
        }

        var (isValid, errorMessage) = await ValidateLocationAsync(companyId, request.Lat, request.Lng);
        if (!isValid)
        {
            return BadRequest(new { message = errorMessage });
        }

        var record = new AttendanceRecord
        {
            CompanyId = companyId,
            UserId = userId,
            WorkDate = today.Date,
            CheckInTime = today,
            CheckInLocation = new GeoLocation { Lat = request.Lat, Lng = request.Lng },
            CheckInIp = GetCallerIp(),
            CheckInDeviceId = request.DeviceId ?? string.Empty,
            Status = "OnTime", // TODO: tính OnTime/Late thật khi có ShiftAssignment (chưa xây)
            WorkingHours = 0
        };

        await _attendanceRecordService.CreateAsync(record);

        return Ok(new { message = "Check-in thành công.", checkInTime = record.CheckInTime });
    }

    [HttpPost("check-out")]
    public async Task<IActionResult> CheckOut([FromBody] CheckOutRequest request)
    {
        var companyId = GetCompanyId();
        var userId = GetUserId();
        if (string.IsNullOrEmpty(companyId) || string.IsNullOrEmpty(userId))
        {
            return Forbid();
        }

        var today = DateTime.UtcNow;
        var existing = await _attendanceRecordService.GetByUserAndDateAsync(companyId, userId, today);
        if (existing is null || existing.CheckInTime is null)
        {
            return BadRequest(new { message = "Bạn chưa check-in hôm nay, không thể check-out." });
        }
        if (existing.CheckOutTime is not null)
        {
            return Conflict(new { message = "Bạn đã check-out hôm nay rồi." });
        }

        var (isValid, errorMessage) = await ValidateLocationAsync(companyId, request.Lat, request.Lng);
        if (!isValid)
        {
            return BadRequest(new { message = errorMessage });
        }

        var workingHours = Math.Round((today - existing.CheckInTime.Value).TotalHours, 2);

        await _attendanceRecordService.UpdateCheckOutAsync(
            companyId, userId, today, today,
            new GeoLocation { Lat = request.Lat, Lng = request.Lng },
            GetCallerIp(), request.DeviceId ?? string.Empty,
            workingHours, existing.Status);

        return Ok(new { message = "Check-out thành công.", checkOutTime = today, workingHours });
    }
}