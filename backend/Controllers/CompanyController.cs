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

    // CONVERT COMPANY -> RESPONSE

    private static CompanyResponse ToResponse(Company c) => new()
    {
        Id = c.Id,
        CompanyCode = c.CompanyCode,
        Name = c.Name,
        Address = c.Address,
        ContactEmail = c.ContactEmail,
        ContactPhone = c.ContactPhone,
        Status = c.Status,
        CreatedAt = c.CreatedAt
    };

    // GET ALL COMPANIES
    // GET: /api/companies

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var companies =
            await _companyService.GetAllAsync();

        return Ok(companies.Select(ToResponse));
    }

    // UPDATE COMPANY STATUS
    // PUT: /api/companies/{id}/status

    [HttpPut("{id}/status")]
    public async Task<IActionResult> UpdateStatus(
        string id,
        [FromBody] UpdateCompanyStatusRequest request)
    {
        var company =
            await _companyService.GetByIdAsync(id);

        if (company is null)
        {
            return NotFound(new
            {
                message = "Không tìm thấy công ty."
            });
        }

        await _companyService.UpdateStatusAsync(
            id,
            request.Status
        );

        company.Status = request.Status;

        return Ok(ToResponse(company));
    }

    // CREATE COMPANY
    // POST: /api/companies

    [HttpPost]
    public async Task<IActionResult> Create(
        [FromBody] CreateCompanyRequest request)
    {
        // 1. Normalize company code
        var normalizedCode =
            request.CompanyCode
                .Trim()
                .ToLowerInvariant();

        // 2. Check company code already exists
        var codeExists =
            await _companyService
                .ExistsByCompanyCodeAsync(
                    normalizedCode
                );

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
            Name = request.CompanyName.Trim(),
            Address = request.Address.Trim(),
            ContactEmail =
                request.ContactEmail.Trim(),
            ContactPhone =
                request.ContactPhone.Trim(),
            Status = "Active"
        };

        await _companyService.CreateAsync(company);

        // 4. Generate Admin username
        var adminUsername =
            $"{company.CompanyCode}.admin"
                .ToLowerInvariant();

        // 5. Generate temporary password
        var temporaryPassword =
            PasswordGenerator.Generate();

        // 6. Create Admin account
        var admin = new User
        {
            CompanyId = company.Id,
            Username = adminUsername,

            PasswordHash =
                BCrypt.Net.BCrypt.HashPassword(
                    temporaryPassword
                ),

            Role = "Admin",
            Status = "Active"
        };

        await _userService.CreateAsync(admin);

        // 7. Send Admin account via company contact email
        await _emailService.SendAdminAccountEmailAsync(
            toEmail: company.ContactEmail,
            toName: company.Name,
            companyName: company.Name,
            adminUsername: admin.Username,
            temporaryPassword: temporaryPassword
        );

        // 8. Return response
        return Ok(new CreateCompanyResponse
        {
            CompanyId = company.Id,
            CompanyCode = company.CompanyCode,
            CompanyName = company.Name,

            AdminUsername = admin.Username,
            AdminFullName = admin.FullName,
            AdminTemporaryPassword =
                temporaryPassword
        });
    }

    // UPDATE COMPANY INFORMATION
    // PUT: /api/companies/{id}

    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateInfo(
        string id,
        [FromBody] UpdateCompanyRequest request)
    {
        // 1. Find company
        var company =
            await _companyService.GetByIdAsync(id);

        if (company is null)
        {
            return NotFound(new
            {
                message = "Không tìm thấy công ty."
            });
        }

        // 2. Normalize company code
        var normalizedCode =
            request.CompanyCode
                .Trim()
                .ToLowerInvariant();

        // 3. Check duplicate company code
        var codeExists =
            await _companyService
                .ExistsByCompanyCodeExceptIdAsync(
                    normalizedCode,
                    id
                );

        if (codeExists)
        {
            return Conflict(new
            {
                message = "Mã công ty đã tồn tại."
            });
        }

        // 4. Normalize information
        var companyName =
            request.CompanyName.Trim();

        var address =
            request.Address.Trim();

        var contactEmail =
            request.ContactEmail.Trim();

        var contactPhone =
            request.ContactPhone.Trim();

        // 5. Update company information
        var updated =
            await _companyService.UpdateInfoAsync(
                id,
                normalizedCode,
                companyName,
                address,
                contactEmail,
                contactPhone
            );

        if (!updated)
        {
            return BadRequest(new
            {
                message =
                    "Không thể cập nhật thông tin công ty."
            });
        }

        // 6. Update local object
        company.CompanyCode =
            normalizedCode;

        company.Name =
            companyName;

        company.Address =
            address;

        company.ContactEmail =
            contactEmail;

        company.ContactPhone =
            contactPhone;

        // 7. Return updated company
        return Ok(ToResponse(company));
    }

    // RESET ADMIN PASSWORD
    // PUT:
    // /api/companies/{id}/admin/reset-password

    [HttpPut("{id}/admin/reset-password")]
    public async Task<IActionResult> ResetAdminPassword(
        string id)
    {
        // 1. Find company
        var company =
            await _companyService.GetByIdAsync(id);

        if (company is null)
        {
            return NotFound(new
            {
                message = "Không tìm thấy công ty."
            });
        }

        // 2. Check company contact email
        if (string.IsNullOrWhiteSpace(
                company.ContactEmail))
        {
            return BadRequest(new
            {
                message =
                    "Công ty chưa có email liên hệ."
            });
        }

        // 3. Find Admin belonging to this company
        var admin =
            await _userService
                .GetAdminByCompanyIdAsync(id);

        if (admin is null)
        {
            return NotFound(new
            {
                message =
                    "Không tìm thấy tài khoản Admin của công ty."
            });
        }

        // 4. Generate new password
        var newPassword =
            PasswordGenerator.Generate();

        // 5. Hash new password
        admin.PasswordHash =
            BCrypt.Net.BCrypt.HashPassword(
                newPassword
            );

        admin.UpdatedAt =
            DateTime.UtcNow;

        // 6. Save new password
        await _userService.UpdateAsync(admin);

        // 7. Send password to COMPANY CONTACT EMAIL
        await _emailService
            .SendPasswordResetEmailAsync(
                toEmail: company.ContactEmail,
                toName: company.Name,
                companyName: company.Name,
                username: admin.Username,
                newPassword: newPassword
            );

        // 8. Do NOT return password to frontend
        return Ok(new
        {
            message =
                "Đã tạo mật khẩu mới và gửi đến email liên hệ của công ty."
        });
    }
}