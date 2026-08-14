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
    private readonly EmailService _emailService;

    public CompanyController(
        CompanyService companyService,
        UserService userService,
        EmailService emailService)
    {
        _companyService = companyService;
        _userService = userService;
        _emailService = emailService;
    }

    [HttpPost]
    public async Task<IActionResult> Create(
        [FromBody] CreateCompanyRequest request)
    {
        // 1. Normalize company code
        var normalizedCode = request.CompanyCode.ToLowerInvariant();

        // 2. Check company code already exists
        var codeExists =
            await _companyService.ExistsByCompanyCodeAsync(normalizedCode);

        if (codeExists)
        {
            return Conflict(new
            {
                message = "Mã công ty đã tồn tại."
            });
        }

        // 3. Create Company
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

        // 4. Generate Admin username = companyCode.admin
        var adminUsername =
            UserService.GenerateUsername(
                company.CompanyCode,
                "admin");


        // 6. Generate temporary password
        var temporaryPassword =
            PasswordGenerator.Generate();
        // 7. Create Admin account
        var admin = new User
        {
            CompanyId = company.Id,
            EmployeeCode = "admin",
            Username = adminUsername,
            PasswordHash =
                BCrypt.Net.BCrypt.HashPassword(temporaryPassword),
            Role = "Admin",
            Status = "Active"
        };

        await _userService.CreateAsync(admin);

        // 8. Send Admin account information via email
        await _emailService.SendAdminAccountEmailAsync(
            toEmail: company.ContactEmail,
            toName: company.Name,
            companyName: company.Name,
            adminUsername: admin.Username,
            temporaryPassword: temporaryPassword
        );

        // 9. Return response
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

