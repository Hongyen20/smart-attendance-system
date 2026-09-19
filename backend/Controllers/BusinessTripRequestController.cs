using System.Security.Claims;
using AttendanceApi.DTOs;
using AttendanceApi.Models;
using AttendanceApi.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AttendanceApi.Controllers;

[ApiController]
[Route("api/business-trip-requests")]
[Authorize]
public class BusinessTripRequestController : ControllerBase
{
    private readonly BusinessTripRequestService _businessTripRequestService;
    private readonly UserService _userService;

    public BusinessTripRequestController(BusinessTripRequestService businessTripRequestService, UserService userService)
    {
        _businessTripRequestService = businessTripRequestService;
        _userService = userService;
    }

    private string? GetCompanyId() => User.FindFirst("companyId")?.Value;
    private string? GetUserId() => User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

    private static BusinessTripRequestResponse ToResponse(BusinessTripRequest r, User? employee = null) => new()
    {
        Id = r.Id,
        StartDate = r.StartDate,
        EndDate = r.EndDate,
        Destination = r.Destination,
        Reason = r.Reason,
        Status = r.Status,
        CreatedAt = r.CreatedAt,
        ApprovedAt = r.ApprovedAt,
        EmployeeName = employee?.FullName,
        EmployeeUsername = employee?.Username
    };

    [Authorize(Roles = "Employee")]
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateBusinessTripRequestRequest request)
    {
        var companyId = GetCompanyId();
        var userId = GetUserId();
        if (string.IsNullOrEmpty(companyId) || string.IsNullOrEmpty(userId))
        {
            return Forbid();
        }

        var trip = new BusinessTripRequest
        {
            CompanyId = companyId,
            UserId = userId,
            StartDate = request.StartDate.Date,
            EndDate = request.EndDate.Date,
            Destination = request.Destination,
            Reason = request.Reason,
            Status = "Pending"
        };

        await _businessTripRequestService.CreateAsync(trip);

        return Ok(ToResponse(trip));
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

        var trips = await _businessTripRequestService.GetByUserIdAsync(companyId, userId);
        return Ok(trips.Select(r => ToResponse(r)));
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

        var trips = await _businessTripRequestService.GetPendingByCompanyAsync(companyId);

        var result = new List<BusinessTripRequestResponse>();
        foreach (var r in trips)
        {
            var employee = await _userService.GetByIdAsync(companyId, r.UserId);
            result.Add(ToResponse(r, employee));
        }

        return Ok(result);
    }

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

        var trip = await _businessTripRequestService.GetByIdAsync(companyId, id);
        if (trip is null)
        {
            return NotFound(new { message = "Không tìm thấy yêu cầu." });
        }

        await _businessTripRequestService.UpdateStatusAsync(companyId, id, "Approved", adminId);

        return Ok(new { message = "Đã duyệt yêu cầu đi công tác." });
    }

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

        var trip = await _businessTripRequestService.GetByIdAsync(companyId, id);
        if (trip is null)
        {
            return NotFound(new { message = "Không tìm thấy yêu cầu." });
        }

        await _businessTripRequestService.UpdateStatusAsync(companyId, id, "Rejected", adminId);

        return Ok(new { message = "Đã từ chối yêu cầu đi công tác." });
    }
}