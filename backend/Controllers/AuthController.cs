using AttendanceApi.DTOs;
using AttendanceApi.Services;
using Microsoft.AspNetCore.Mvc;

namespace AttendanceApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly UserService _userService;
    private readonly TokenService _tokenService;
    private readonly AuditLogService _auditLogService;
    private readonly CompanyService _companyService;

    public AuthController(
        UserService userService, TokenService tokenService,
        AuditLogService auditLogService, CompanyService companyService)
    {
        _userService = userService;
        _tokenService = tokenService;
        _auditLogService = auditLogService;
        _companyService = companyService;
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequest request)
    {
        var user = await _userService.GetByUsernameAsync(request.Username);

        if (user is null )
        {
            return Unauthorized(new { message = "Tên đăng nhập không đúng" });
        }

        if (!BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
        {
            return Unauthorized(new { message = "Sai mật khẩu" });
        }

        if (user.Status != "Active")
        {
            return Unauthorized(new { message = "Tài khoản đã bị khóa. Vui lòng liên hệ quản trị viên." });
        }

        // SuperAdmin không thuộc công ty nào (CompanyId null) nên bỏ qua bước kiểm tra này.
        if (!string.IsNullOrEmpty(user.CompanyId))
        {
            var company = await _companyService.GetByIdAsync(user.CompanyId);
            if (company is null || company.Status != "Active")
            {
                return Unauthorized(new { message = "Công ty của bạn đã bị tạm khóa. Vui lòng liên hệ nhà cung cấp dịch vụ." });
            }
        }

        var token = _tokenService.GenerateAccessToken(user);

        // companyId truyền thẳng (có thể null nếu là SuperAdmin) - AuditLogService đã hỗ trợ null.
        await _auditLogService.LogAsync(user.CompanyId, user.Id, "LOGIN_SUCCESS");

        return Ok(new LoginResponse
        {
            Token = token,
            UserId = user.Id,
            Username = user.Username,
            FullName = user.FullName,
            Role = user.Role,
            CompanyId = user.CompanyId,
            AvatarUrl = user.AvatarUrl
        });
    }
}