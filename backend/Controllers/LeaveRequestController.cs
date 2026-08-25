using System.Security.Claims;
using AttendanceApi.DTOs;
using AttendanceApi.Models;
using AttendanceApi.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AttendanceApi.Controllers;

[ApiController]
[Route("api/leave-requests")]
[Authorize]
public class LeaveRequestController : ControllerBase
{
    private readonly LeaveRequestService _leaveRequestService;
    private readonly UserService _userService;

    public LeaveRequestController(LeaveRequestService leaveRequestService, UserService userService)
    {
        _leaveRequestService = leaveRequestService;
        _userService = userService;
    }

    private string? GetCompanyId() => User.FindFirst("companyId")?.Value;
    private string? GetUserId() => User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

    private static LeaveRequestResponse ToResponse(LeaveRequest r) => new()
    {
        Id = r.Id,
        Type = r.Type,
        StartDate = r.StartDate,
        EndDate = r.EndDate,
        Reason = r.Reason,
        Status = r.Status,
        CreatedAt = r.CreatedAt,
        ApprovedAt = r.ApprovedAt
    };

    [HttpPost]
    [Authorize(Roles = "Employee")]
    public async Task<IActionResult> Create([FromBody] CreateLeaveRequestRequest request)
    {
        var companyId = GetCompanyId();
        var userId = GetUserId();
        if (string.IsNullOrEmpty(companyId) || string.IsNullOrEmpty(userId))
        {
            return Forbid();
        }

        if (request.EndDate.Date < request.StartDate.Date)
        {
            return BadRequest(new { message = "Đến ngày phải sau hoặc bằng Từ ngày." });
        }

        var hasOverlap = await _leaveRequestService.HasOverlappingRequestAsync(
            companyId, userId, request.StartDate.Date, request.EndDate.Date);
        if (hasOverlap)
        {
            return Conflict(new { message = "Bạn đã có đơn nghỉ phép trùng với khoảng ngày này. Vui lòng chọn ngày khác." });
        }

        var leaveRequest = new LeaveRequest
        {
            CompanyId = companyId,
            UserId = userId,
            Type = request.Type,
            StartDate = request.StartDate.Date,
            EndDate = request.EndDate.Date,
            Reason = request.Reason,
            Status = "Pending"
        };

        await _leaveRequestService.CreateAsync(leaveRequest);

        return Ok(ToResponse(leaveRequest));
    }

    [HttpGet("me")]
    [Authorize(Roles = "Employee")]
    public async Task<IActionResult> GetMine()
    {
        var companyId = GetCompanyId();
        var userId = GetUserId();
        if (string.IsNullOrEmpty(companyId) || string.IsNullOrEmpty(userId))
        {
            return Forbid();
        }

        var requests = await _leaveRequestService.GetByUserIdAsync(companyId, userId);
        return Ok(requests.Select(ToResponse));
    }

    /// Admin xem hàng đợi đơn chờ duyệt - kèm tên nhân viên để dễ nhận diện
    /// (LeaveRequest gốc chỉ có UserId, phải join thêm với User để lấy tên hiển thị).
    [HttpGet("pending")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetPending()
    {
        var companyId = GetCompanyId();
        if (string.IsNullOrEmpty(companyId))
        {
            return Forbid();
        }

        var requests = await _leaveRequestService.GetPendingByCompanyAsync(companyId);

        var result = new List<object>();
        foreach (var r in requests)
        {
            var employee = await _userService.GetByIdAsync(companyId, r.UserId);
            result.Add(new
            {
                id = r.Id,
                type = r.Type,
                startDate = r.StartDate,
                endDate = r.EndDate,
                reason = r.Reason,
                status = r.Status,
                createdAt = r.CreatedAt,
                employeeName = employee?.FullName ?? "Không rõ",
                employeeCode = employee?.EmployeeCode ?? ""
            });
        }

        return Ok(result);
    }

    [HttpPut("{id}/approve")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Approve(string id)
    {
        var companyId = GetCompanyId();
        var adminId = GetUserId();
        if (string.IsNullOrEmpty(companyId) || string.IsNullOrEmpty(adminId))
        {
            return Forbid();
        }

        var request = await _leaveRequestService.GetByIdAsync(companyId, id);
        if (request is null)
        {
            return NotFound(new { message = "Không tìm thấy đơn." });
        }

        await _leaveRequestService.UpdateStatusAsync(companyId, id, "Approved", adminId);
        return Ok(new { message = "Đã duyệt đơn." });
    }

    [HttpPut("{id}/reject")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Reject(string id)
    {
        var companyId = GetCompanyId();
        var adminId = GetUserId();
        if (string.IsNullOrEmpty(companyId) || string.IsNullOrEmpty(adminId))
        {
            return Forbid();
        }

        var request = await _leaveRequestService.GetByIdAsync(companyId, id);
        if (request is null)
        {
            return NotFound(new { message = "Không tìm thấy đơn." });
        }

        await _leaveRequestService.UpdateStatusAsync(companyId, id, "Rejected", adminId);
        return Ok(new { message = "Đã từ chối đơn." });
    }
}