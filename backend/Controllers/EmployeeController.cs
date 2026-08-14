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

    // Get companyId from claim trong JWT - Admin always have companyId (not null like SuperAdmin).
    private string? GetCompanyId() => User.FindFirst("companyId")?.Value;

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var companyId = GetCompanyId();
        if (string.IsNullOrEmpty(companyId))
        {
            return Forbid();
        }

        var employees = await _userService.GetAllByCompanyAsync(companyId);

        var result = employees.Select(u => new EmployeeSummaryResponse
        {
            Id = u.Id,
            EmployeeCode = u.EmployeeCode,
            Username = u.Username,
            FullName = u.FullName,
            Email = u.Email,
            Phone = u.Phone,
            Role = u.Role,
            Status = u.Status
        });

        return Ok(result);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateEmployeeRequest request)
    {
        var companyId = GetCompanyId();
        if (string.IsNullOrEmpty(companyId))
        {
            return Forbid();
        }

        var company = await _companyService.GetByIdAsync(companyId);
        if (company is null)
        {
            return NotFound(new { message = "Không tìm thấy thông tin công ty." });
        }

        // Username = CompanyCode + stt
        var sequence = await _counterService.GetNextSequenceAsync($"employee_seq:{companyId}");
        var username = UserService.GenerateUsername(company.CompanyCode, sequence.ToString());

        var temporaryPassword = PasswordGenerator.Generate();

        var employee = new User
        {
            CompanyId = companyId,
            EmployeeCode = request.EmployeeCode,
            Username = username,
            Email = request.Email,
            FullName = request.FullName,
            Phone = request.Phone,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(temporaryPassword),
            Role = "Employee",
            Status = "Active"
        };
        await _userService.CreateAsync(employee);

        // Send email consist of username + temporary password - not return response.
        bool emailSent;
        string? emailError = null;
        try
        {
            await _emailService.SendAccountCredentialsEmailAsync(
                employee.Email, employee.FullName, company.Name, employee.Username, temporaryPassword);
            emailSent = true;
        }
        catch (Exception ex)
        {
            emailSent = false;
            emailError = ex.Message;
        }

        return Ok(new CreateEmployeeResponse
        {
            EmployeeId = employee.Id,
            Username = employee.Username,
            FullName = employee.FullName,
            Email = employee.Email,
            EmailSent = emailSent,
            EmailErrorMessage = emailError
        });
    }
}