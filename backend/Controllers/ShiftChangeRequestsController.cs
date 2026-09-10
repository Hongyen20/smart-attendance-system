using System.Security.Claims;
using AttendanceApi.DTOs;
using AttendanceApi.Models;
using AttendanceApi.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AttendanceApi.Controllers;

[ApiController]
[Route("api/shift-change-requests")]
[Authorize]
public class ShiftChangeRequestController : ControllerBase
{
    private readonly ShiftChangeRequestService _shiftChangeRequestService;
    private readonly UserService _userService;

    public ShiftChangeRequestController(ShiftChangeRequestService shiftChangeRequestService, UserService userService)
    {
        _shiftChangeRequestService = shiftChangeRequestService;
        _userService = userService;
    }

    private string? GetCompanyId() => User.FindFirst("companyId")?.Value;
    private string? GetUserId() => User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

    private static ShiftChangeRequestResponse ToResponse(ShiftChangeRequest r, string? employeeName = null, string? employeeCode = null) => new()
    {
        Id = r.Id,
        EffectiveDate = r.EffectiveDate,
        RequestedShiftType = r.RequestedShiftType,
        RequestedStartTime = r.RequestedStartTime,
        RequestedEndTime = r.RequestedEndTime,
        RequestedHours = r.RequestedHours,
        Reason = r.Reason,
        Status = r.Status,
        CreatedAt = r.CreatedAt,
        ApprovedAt = r.ApprovedAt,
        EmployeeName = employeeName,
        EmployeeCode = employeeCode
    };

    [Authorize(Roles = "Employee")]
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateShiftChangeRequest request)
    {
        var companyId = GetCompanyId();
        var userId = GetUserId();
        if (string.IsNullOrEmpty(companyId) || string.IsNullOrEmpty(userId))
        {
            return Forbid();
        }

        var start = TimeSpan.Parse(request.RequestedStartTime);
        var end = TimeSpan.Parse(request.RequestedEndTime);
        var hours = Math.Round((end - start).TotalHours, 2);

        var shiftChangeRequest = new ShiftChangeRequest
        {
            CompanyId = companyId,
            UserId = userId,
            EffectiveDate = request.EffectiveDate.Date,
            RequestedShiftType = request.RequestedShiftType,
            RequestedStartTime = request.RequestedStartTime,
            RequestedEndTime = request.RequestedEndTime,
            RequestedHours = hours,
            Reason = request.Reason,
            Status = "Pending"
        };

        await _shiftChangeRequestService.CreateAsync(shiftChangeRequest);

        return Ok(ToResponse(shiftChangeRequest));
    }

    [Authorize(Roles = "Employee")]
    [HttpGet("me")]
    public async Task<IActionResult> GetMine()
    {
        var companyId = GetCompanyId();
        var userId = GetUserId();
        if (string.IsNullOrEmpty(companyId) || string.IsNullOrEmpty(userId))
        {
            return Forbid();
        }

        var requests = await _shiftChangeRequestService.GetByUserIdAsync(companyId, userId);
        return Ok(requests.Select(r => ToResponse(r)));
    }

    [Authorize(Roles = "Admin")]
    [HttpGet("pending")]
    public async Task<IActionResult> GetPending()
    {
        var companyId = GetCompanyId();
        if (string.IsNullOrEmpty(companyId))
        {
            return Forbid();
        }

        var requests = await _shiftChangeRequestService.GetPendingByCompanyAsync(companyId);

        var result = new List<ShiftChangeRequestResponse>();
        foreach (var r in requests)
        {
            var employee = await _userService.GetByIdAsync(companyId, r.UserId);
            result.Add(ToResponse(r, employee?.FullName, employee?.EmployeeCode));
        }

        return Ok(result);
    }

    // Duyệt yêu cầu - KHÁC với đơn nghỉ phép: ngoài đổi Status, còn cập nhật NGAY
    // ca làm việc hiện tại của nhân viên (User.CurrentShiftType/Start/End/Hours).
    [Authorize(Roles = "Admin")]
    [HttpPut("{id}/approve")]
    public async Task<IActionResult> Approve(string id)
    {
        var companyId = GetCompanyId();
        var adminId = GetUserId();
        if (string.IsNullOrEmpty(companyId) || string.IsNullOrEmpty(adminId))
        {
            return Forbid();
        }

        var request = await _shiftChangeRequestService.GetByIdAsync(companyId, id);
        if (request is null)
        {
            return NotFound(new { message = "Không tìm thấy yêu cầu." });
        }

        var employee = await _userService.GetByIdAsync(companyId, request.UserId);
        if (employee is null)
        {
            return NotFound(new { message = "Không tìm thấy nhân viên." });
        }

        employee.CurrentShiftType = request.RequestedShiftType;
        employee.CurrentShiftStart = request.RequestedStartTime;
        employee.CurrentShiftEnd = request.RequestedEndTime;
        employee.CurrentShiftHours = request.RequestedHours;
        await _userService.UpdateAsync(employee);

        await _shiftChangeRequestService.UpdateStatusAsync(companyId, id, "Approved", adminId);

        return Ok(new { message = "Đã duyệt yêu cầu đổi ca. Ca làm việc mới đã được áp dụng." });
    }

    // Từ chối - CHỈ đổi Status, không đụng gì tới ca hiện tại của nhân viên (giữ nguyên).
    [Authorize(Roles = "Admin")]
    [HttpPut("{id}/reject")]
    public async Task<IActionResult> Reject(string id)
    {
        var companyId = GetCompanyId();
        var adminId = GetUserId();
        if (string.IsNullOrEmpty(companyId) || string.IsNullOrEmpty(adminId))
        {
            return Forbid();
        }

        await _shiftChangeRequestService.UpdateStatusAsync(companyId, id, "Rejected", adminId);
        return Ok(new { message = "Đã từ chối yêu cầu. Ca làm việc hiện tại được giữ nguyên." });
    }
}