using AttendanceApi.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AttendanceApi.Controllers;

[ApiController]
[Route("api/face")]
[Authorize(Roles = "Admin")]
public class FaceController : ControllerBase
{
    private readonly UserService _userService;
    private readonly FaceRecognitionService _faceRecognitionService;

    public FaceController(
        UserService userService,
        FaceRecognitionService faceRecognitionService)
    {
        _userService = userService;
        _faceRecognitionService = faceRecognitionService;
    }

    private string? GetCompanyId()
    {
        return User.FindFirst("companyId")?.Value;
    }


     // REGISTER FACE

    [HttpPost("register/{userId}")]
    [Consumes("multipart/form-data")]
    public async Task<IActionResult> RegisterFace(
        string userId,
        IFormFile? image)
    {
        // 1. Lấy companyId từ JWT

        var companyId = GetCompanyId();

        if (string.IsNullOrWhiteSpace(companyId))
        {
            return Forbid();
        }

        // 2. Kiểm tra file ảnh
        if (image == null || image.Length == 0)
        {
            return BadRequest(new
            {
                message = "Vui lòng cung cấp ảnh khuôn mặt."
            });
        }

        // 3. Kiểm tra loại file
        var allowedContentTypes = new[]
        {
            "image/jpeg",
            "image/jpg",
            "image/png"
        };

        if (!allowedContentTypes.Contains(
                image.ContentType,
                StringComparer.OrdinalIgnoreCase))
        {
            return BadRequest(new
            {
                message =
                    "Chỉ hỗ trợ ảnh JPG, JPEG hoặc PNG."
            });
        }

        // 4. Giới hạn kích thước ảnh
        const long maxFileSize = 5 * 1024 * 1024;

        if (image.Length > maxFileSize)
        {
            return BadRequest(new
            {
                message =
                    "Kích thước ảnh không được vượt quá 5MB."
            });
        }
        // 5. Tìm Employee
        var user = await _userService.GetByIdAsync(
            companyId,
            userId);

        if (user == null)
        {
            return NotFound(new
            {
                message =
                    "Không tìm thấy nhân viên trong công ty."
            });
        }

        if (user.Role != "Employee")
        {
            return BadRequest(new
            {
                message =
                    "Chỉ có thể đăng ký khuôn mặt cho Employee."
            });
        }


        // 6. Nếu Employee đã có FaceId
        if (!string.IsNullOrWhiteSpace(user.FaceId))
        {
            return BadRequest(new
            {
                message =
                    "Nhân viên này đã đăng ký khuôn mặt."
            });
        }


        // 7. Gửi ảnh tới Amazon Rekognition
        string? faceId;

        await using (var stream = image.OpenReadStream())
        {
            faceId =
                await _faceRecognitionService.RegisterFaceAsync(
                    companyId,
                    userId,
                    stream);
        }


        // 8. Không tìm thấy khuôn mặt
        if (string.IsNullOrWhiteSpace(faceId))
        {
            return BadRequest(new
            {
                message =
                    "Không thể nhận diện khuôn mặt trong ảnh. " +
                    "Vui lòng sử dụng ảnh rõ mặt và chỉ có một người."
            });
        }

        // 9. Lưu FaceId vào MongoDB
        var collectionId =
            $"attendance-{companyId}";

        await _userService.UpdateFaceInfoAsync(
            companyId,
            userId,
            faceId,
            collectionId);


        // 10. Trả kết quả
        return Ok(new
        {
            message =
                "Đăng ký khuôn mặt thành công.",

            faceId = faceId,

            faceCollectionId = collectionId,

            registeredAt = DateTime.UtcNow
        });
    }
}

