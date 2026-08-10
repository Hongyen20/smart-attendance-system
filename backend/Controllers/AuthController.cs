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

    public AuthController(UserService userService, TokenService tokenService, AuditLogService auditLogService)
    {
        _userService = userService;
        _tokenService = tokenService;
        _auditLogService = auditLogService;
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequest request)
    {
        var user = await _userService.GetByUsernameAsync(request.Username);
        //Avoid brute force attack
        if (user is null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
        {
            return Unauthorized(new { message = "Tên đăng nhập hoặc mật khẩu không đúng." });
        }

        if (user.Status != "Active")
        {
            return Unauthorized(new { message = "Tài khoản đã bị khóa. Vui lòng liên hệ quản trị viên." });
        }

        var token = _tokenService.GenerateAccessToken(user);

        // companyId (null if SuperAdmin) 
        await _auditLogService.LogAsync(user.CompanyId, user.Id, "LOGIN_SUCCESS");

        return Ok(new LoginResponse
        {
            Token = token,
            UserId = user.Id,
            Username = user.Username,
            FullName = user.FullName,
            Role = user.Role,
            CompanyId = user.CompanyId
        });
    }
}