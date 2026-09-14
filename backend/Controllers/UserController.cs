using System.Security.Claims;
using AttendanceApi.DTOs;
using AttendanceApi.Models;
using AttendanceApi.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AttendanceApi.Controllers;

[ApiController]
[Route("api/users")]
[Authorize]
public class UserController : ControllerBase
{
    private readonly UserService _userService;
    private readonly IWebHostEnvironment _env;

    private static readonly string[] AllowedAvatarExtensions = { ".jpg", ".jpeg", ".png", ".webp" };
    private const long MaxAvatarSizeBytes = 5 * 1024 * 1024; // 5MB

    public UserController(UserService userService, IWebHostEnvironment env)
    {
        _userService = userService;
        _env = env;
    }

    private string? GetUserId() => User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

    /// Có thể null nếu là SuperAdmin - GetByIdAsync đã hỗ trợ companyId null từ trước.
    private string? GetCompanyId() => User.FindFirst("companyId")?.Value;

    private static UserProfileResponse ToResponse(User u) => new()
    {
        Id = u.Id,
        Username = u.Username,
        FullName = u.FullName,
        Email = u.Email,
        Phone = u.Phone,
        AvatarUrl = u.AvatarUrl,
        Role = u.Role,
        CompanyId = u.CompanyId
    };

    [HttpGet("me")]
    public async Task<IActionResult> GetMe()
    {
        var userId = GetUserId();
        if (string.IsNullOrEmpty(userId))
        {
            return Forbid();
        }

        var user = await _userService.GetByIdAsync(GetCompanyId(), userId);
        if (user is null)
        {
            return NotFound(new { message = "Không tìm thấy tài khoản." });
        }

        return Ok(ToResponse(user));
    }

    /// Chỉ cho sửa Email + Phone. FullName và Username KHÔNG có trong DTO này
    /// -> không có cách nào gửi lên để đổi qua endpoint này, kể cả cố tình.
    [HttpPut("me/profile")]
    public async Task<IActionResult> UpdateProfile([FromBody] UpdateProfileRequest request)
    {
        var userId = GetUserId();
        if (string.IsNullOrEmpty(userId))
        {
            return Forbid();
        }

        var user = await _userService.GetByIdAsync(GetCompanyId(), userId);
        if (user is null)
        {
            return NotFound(new { message = "Không tìm thấy tài khoản." });
        }

        user.Email = request.Email;
        user.Phone = request.Phone;

        await _userService.UpdateAsync(user);

        return Ok(ToResponse(user));
    }

    [HttpPut("me/password")]
    public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
    {
        var userId = GetUserId();
        if (string.IsNullOrEmpty(userId))
        {
            return Forbid();
        }

        var user = await _userService.GetByIdAsync(GetCompanyId(), userId);
        if (user is null)
        {
            return NotFound(new { message = "Không tìm thấy tài khoản." });
        }

        if (!BCrypt.Net.BCrypt.Verify(request.CurrentPassword, user.PasswordHash))
        {
            return BadRequest(new { message = "Mật khẩu hiện tại không đúng." });
        }

        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);
        await _userService.UpdateAsync(user);

        return Ok(new { message = "Đổi mật khẩu thành công." });
    }

    [HttpPost("me/avatar")]
    public async Task<IActionResult> UploadAvatar(IFormFile file)
    {
        var userId = GetUserId();
        if (string.IsNullOrEmpty(userId))
        {
            return Forbid();
        }

        if (file is null || file.Length == 0)
        {
            return BadRequest(new { message = "Vui lòng chọn file ảnh." });
        }

        var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (!AllowedAvatarExtensions.Contains(ext))
        {
            return BadRequest(new { message = "Chỉ chấp nhận file ảnh JPG, PNG hoặc WEBP." });
        }

        if (file.Length > MaxAvatarSizeBytes)
        {
            return BadRequest(new { message = "Kích thước ảnh tối đa 5MB." });
        }

        var user = await _userService.GetByIdAsync(GetCompanyId(), userId);
        if (user is null)
        {
            return NotFound(new { message = "Không tìm thấy tài khoản." });
        }

        var uploadsDir = Path.Combine(_env.WebRootPath, "uploads", "avatars");
        Directory.CreateDirectory(uploadsDir);

        var fileName = $"{userId}{ext}";
        var filePath = Path.Combine(uploadsDir, fileName);

        await using (var stream = new FileStream(filePath, FileMode.Create))
        {
            await file.CopyToAsync(stream);
        }

        // Query string ?v=timestamp để phá cache ảnh cũ trên client khi đổi avatar mới.
        user.AvatarUrl = $"/uploads/avatars/{fileName}?v={DateTimeOffset.UtcNow.ToUnixTimeSeconds()}";
        await _userService.UpdateAsync(user);

        return Ok(new { avatarUrl = user.AvatarUrl });
    }
}