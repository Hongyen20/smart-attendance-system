using AttendanceApi.DTOs;
using AttendanceApi.Models;
using AttendanceApi.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AttendanceApi.Controllers;

[ApiController]
[Route("api/employees")]
[Authorize(Roles = "Admin")]
public class EmployeeController : ControllerBase
{
private readonly UserService _userService;
private readonly CompanyService _companyService;
private readonly EmailService _emailService;
private readonly CounterService _counterService;

public EmployeeController(
    UserService userService,
    CompanyService companyService,
    EmailService emailService,
    CounterService counterService)
{
    _userService = userService;
    _companyService = companyService;
    _emailService = emailService;
    _counterService = counterService;
}

// Lấy companyId từ claim trong JWT - Admin luôn có companyId.
private string? GetCompanyId() =>
    User.FindFirst("companyId")?.Value;

private static EmployeeSummaryResponse ToSummary(User u) => new()
{
    Id = u.Id,
    Username = u.Username,
    FullName = u.FullName,
    Email = u.Email,
    Phone = u.Phone,
    Role = u.Role,
    Status = u.Status,
    AnnualLeaveDays = u.AnnualLeaveDays,
    CurrentShiftType = u.CurrentShiftType,
    CurrentShiftStart = u.CurrentShiftStart,
    CurrentShiftEnd = u.CurrentShiftEnd,
    CurrentShiftHours = u.CurrentShiftHours,

    // Chỉ trả trạng thái có khuôn mặt,
    // không trả FaceId của AWS ra frontend.
    HasFace = !string.IsNullOrWhiteSpace(u.FaceId)
};

[HttpGet]
public async Task<IActionResult> GetAll()
{
    var companyId = GetCompanyId();

    if (string.IsNullOrEmpty(companyId))
    {
        return Forbid();
    }

    var employees =
        await _userService.GetAllByCompanyAsync(companyId);

    return Ok(employees.Select(ToSummary));
}

[HttpGet("{id}")]
public async Task<IActionResult> GetById(string id)
{
    var companyId = GetCompanyId();

    if (string.IsNullOrEmpty(companyId))
    {
        return Forbid();
    }

    var employee =
        await _userService.GetByIdAsync(
            companyId,
            id);

    if (employee is null ||
        employee.Role != "Employee")
    {
        return NotFound(new
        {
            message = "Không tìm thấy nhân viên."
        });
    }

    return Ok(ToSummary(employee));
}

[HttpPost]
public async Task<IActionResult> Create(
    [FromBody] CreateEmployeeRequest request)
{
    var companyId = GetCompanyId();

    if (string.IsNullOrEmpty(companyId))
    {
        return Forbid();
    }

    var company =
        await _companyService.GetByIdAsync(companyId);

    if (company is null)
    {
        return NotFound(new
        {
            message =
                "Không tìm thấy thông tin công ty."
        });
    }

    // Không kiểm tra trùng email toàn hệ thống.
    // Một người có thể từng làm ở nhiều công ty
    // khác nhau với cùng một email cá nhân.

    var sequence =
        await _counterService.GetNextSequenceAsync(
            $"employee_seq:{companyId}");

    var username =
        $"{company.CompanyCode}.nv{sequence:D3}"
            .ToLowerInvariant();

    var temporaryPassword =
        PasswordGenerator.Generate();

    var employee = new User
    {
        CompanyId = companyId,
        Username = username,
        Email = request.Email,
        FullName = request.FullName,
        Phone = request.Phone,
        PasswordHash =
            BCrypt.Net.BCrypt.HashPassword(
                temporaryPassword),
        Role = "Employee",
        Status = "Active",
        AnnualLeaveDays =
            request.AnnualLeaveDays ?? 12
    };

    await _userService.CreateAsync(employee);

    bool emailSent;
    string? emailError = null;

    try
    {
        await _emailService
            .SendEmployeeAccountCredentialsEmailAsync(
                employee.Email,
                employee.FullName,
                company.Name,
                employee.Username,
                temporaryPassword);

        emailSent = true;
    }
    catch (Exception ex)
    {
        emailSent = false;
        emailError = ex.Message;
    }

    return Ok(
        new CreateEmployeeResponse
        {
            EmployeeId = employee.Id,
            Username = employee.Username,
            FullName = employee.FullName,
            Email = employee.Email,
            EmailSent = emailSent,
            EmailErrorMessage = emailError
        });
}

// Admin sửa thông tin nhân viên.
[HttpPut("{id}")]
public async Task<IActionResult> Update(
    string id,
    [FromBody] UpdateEmployeeRequest request)
{
    var companyId = GetCompanyId();

    if (string.IsNullOrEmpty(companyId))
    {
        return Forbid();
    }

    var employee =
        await _userService.GetByIdAsync(
            companyId,
            id);

    if (employee is null ||
        employee.Role != "Employee")
    {
        return NotFound(new
        {
            message =
                "Không tìm thấy nhân viên."
        });
    }

    // Chỉ kiểm tra trùng username nếu Admin
    // thực sự đổi sang username khác.
    if (!string.Equals(
            employee.Username,
            request.Username,
            StringComparison.Ordinal))
    {
        var usernameExists =
            await _userService
                .ExistsByUsernameAsync(
                    request.Username);

        if (usernameExists)
        {
            return Conflict(new
            {
                message =
                    "Tên đăng nhập đã tồn tại, vui lòng chọn tên khác."
            });
        }
    }

    employee.FullName = request.FullName;
    employee.Username = request.Username;
    employee.Email = request.Email;
    employee.Phone = request.Phone;
    employee.AnnualLeaveDays =
        request.AnnualLeaveDays;

    await _userService.UpdateAsync(employee);

    return Ok(ToSummary(employee));
}

// Cấp lại mật khẩu mới cho nhân viên.
[HttpPost("{id}/reset-password")]
public async Task<IActionResult> ResetPassword(
    string id)
{
    var companyId = GetCompanyId();

    if (string.IsNullOrEmpty(companyId))
    {
        return Forbid();
    }

    var employee =
        await _userService.GetByIdAsync(
            companyId,
            id);

    if (employee is null ||
        employee.Role != "Employee")
    {
        return NotFound(new
        {
            message =
                "Không tìm thấy nhân viên."
        });
    }

    var company =
        await _companyService.GetByIdAsync(
            companyId);

    if (company is null)
    {
        return NotFound(new
        {
            message =
                "Không tìm thấy thông tin công ty."
        });
    }

    var newPassword =
        PasswordGenerator.Generate();

    employee.PasswordHash =
        BCrypt.Net.BCrypt.HashPassword(
            newPassword);

    await _userService.UpdateAsync(employee);

    bool emailSent;
    string? emailError = null;

    try
    {
        await _emailService
            .SendPasswordResetEmailAsync(
                employee.Email,
                employee.FullName,
                company.Name,
                employee.Username,
                newPassword);

        emailSent = true;
    }
    catch (Exception ex)
    {
        emailSent = false;
        emailError = ex.Message;
    }

    return Ok(
        new
        {
            message =
                "Đã cấp lại mật khẩu.",
            emailSent,
            emailErrorMessage =
                emailError
        });
}
}
