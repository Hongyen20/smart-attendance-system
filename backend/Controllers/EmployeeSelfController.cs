using System.Security.Claims;
using AttendanceApi.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AttendanceApi.Controllers;

[ApiController]
[Route("api/employee-self")]
[Authorize(Roles = "Employee")]
public class EmployeeSelfController : ControllerBase
{
    private readonly UserService _userService;

    public EmployeeSelfController(UserService userService)
    {
        _userService = userService;
    }

    private string? GetCompanyId() =>
        User.FindFirst("companyId")?.Value;

    private string? GetUserId() =>
        User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

    // GET: /api/employee-self/face-status
    [HttpGet("face-status")]
    public async Task<IActionResult> GetFaceStatus()
    {
        var companyId = GetCompanyId();
        var userId = GetUserId();

        if (string.IsNullOrWhiteSpace(companyId) ||
            string.IsNullOrWhiteSpace(userId))
        {
            return Forbid();
        }

        var employee =
            await _userService.GetByIdAsync(
                companyId,
                userId);

        if (employee is null ||
            employee.Role != "Employee")
        {
            return NotFound(new
            {
                message = "Không tìm thấy thông tin nhân viên."
            });
        }

        return Ok(new
        {
            hasFace = !string.IsNullOrWhiteSpace(employee.FaceId)
        });
    }
}
