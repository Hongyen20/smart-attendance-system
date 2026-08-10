using AttendanceApi.DTOs;
using AttendanceApi.Models;
using AttendanceApi.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AttendanceApi.Controllers;

[ApiController]
[Route("api/companies")]
[Authorize(Roles = "SuperAdmin")]
public class CompanyController : ControllerBase
{
    private readonly CompanyService _companyService;
    private readonly UserService _userService;

    public CompanyController(CompanyService companyService, UserService userService)
    {
        _companyService = companyService;
        _userService = userService;
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateCompanyRequest request)
    {
        var normalizedCode = request.CompanyCode.ToLowerInvariant();

        var codeExists = await _companyService.ExistsByCompanyCodeAsync(normalizedCode);
        if (codeExists)
        {
            return Conflict(new { message = "Mã công ty đã tồn tại." });
        }

        var emailExists = await _userService.ExistsByEmailAsync(request.AdminEmail);
        if (emailExists)
        {
            return Conflict(new { message = "Email đã được sử dụng cho tài khoản khác trong hệ thống." });
        }

        // 1. Create company for Id use for User.CompanyId
        var company = new Company
        {
            CompanyCode = normalizedCode,
            Name = request.CompanyName,
            Address = request.Address,
            ContactEmail = request.ContactEmail,
            ContactPhone = request.ContactPhone,
            Status = "Active"
        };
        await _companyService.CreateAsync(company);

        // 2. username = companyCode.admin
        var adminUsername = UserService.GenerateUsername(company.CompanyCode, "admin");
        var usernameExists = await _userService.ExistsByUsernameAsync(adminUsername);
        if (usernameExists)
        {
            return Conflict(new { message = "Không thể sinh username cho Admin (đã tồn tại). Vui lòng thử lại." });
        }

        // 3. password random
        var temporaryPassword = PasswordGenerator.Generate();

        var admin = new User
        {
            CompanyId = company.Id,
            EmployeeCode = "admin",
            Username = adminUsername,
            Email = request.AdminEmail,
            FullName = request.AdminFullName,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(temporaryPassword),
            Role = "Admin",
            Status = "Active"
        };
        await _userService.CreateAsync(admin);

        return Ok(new CreateCompanyResponse
        {
            CompanyId = company.Id,
            CompanyCode = company.CompanyCode,
            CompanyName = company.Name,
            AdminUsername = admin.Username,
            AdminFullName = admin.FullName,
            AdminTemporaryPassword = temporaryPassword
        });
    }
}