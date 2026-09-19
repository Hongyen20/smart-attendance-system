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

[HttpPost("register/{userId}")]
[Consumes("multipart/form-data")]
public async Task<IActionResult> RegisterFace(
    string userId,
    IFormFile? image)
{
    var companyId = GetCompanyId();

    if (string.IsNullOrWhiteSpace(companyId))
    {
        return Forbid();
    }

    if (image == null || image.Length == 0)
    {
        return BadRequest(new
        {
            message = "Vui lòng cung cấp ảnh khuôn mặt."
        });
    }

    var extension = Path.GetExtension(image.FileName)
        .ToLowerInvariant();

    var allowedExtensions = new[]
    {
        ".jpg",
        ".jpeg",
        ".png"
    };

    if (!allowedExtensions.Contains(extension))
    {
        return BadRequest(new
        {
            message =
                "Chỉ hỗ trợ ảnh JPG, JPEG hoặc PNG."
        });
    }

    const long maxFileSize = 5 * 1024 * 1024;

    if (image.Length > maxFileSize)
    {
        return BadRequest(new
        {
            message =
                "Kích thước ảnh không được vượt quá 5MB."
        });
    }

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

    // Lưu FaceId cũ để xử lý trường hợp đổi ảnh.
    var oldFaceId = user.FaceId;

    string? newFaceId;

    await using (var stream = image.OpenReadStream())
    {
        newFaceId =
            await _faceRecognitionService.RegisterFaceAsync(
                companyId,
                userId,
                stream);
    }

    if (string.IsNullOrWhiteSpace(newFaceId))
    {
        return BadRequest(new
        {
            message =
                "Không thể nhận diện khuôn mặt trong ảnh. " +
                "Vui lòng sử dụng ảnh rõ mặt và chỉ có một người."
        });
    }

    var collectionId = $"attendance-{companyId}";


     /* Cập nhật FaceId mới trước.
     *
     * Nếu bước này thành công thì nhân viên đã có
     * FaceId mới hợp lệ.
     */
    await _userService.UpdateFaceInfoAsync(
        companyId,
        userId,
        newFaceId,
        collectionId);

    /*
     * Chỉ xóa FaceId cũ sau khi FaceId mới đã được
     * lưu thành công vào MongoDB.
     *
     * Nếu xóa FaceId cũ thất bại thì FaceId mới vẫn
     * hoạt động bình thường. FaceId cũ chỉ trở thành
     * dữ liệu dư thừa trong Rekognition.
     */
    if (!string.IsNullOrWhiteSpace(oldFaceId) &&
        !string.Equals(
            oldFaceId,
            newFaceId,
            StringComparison.OrdinalIgnoreCase))
    {
        try
        {
            await _faceRecognitionService.DeleteFaceAsync(
                companyId,
                oldFaceId);
        }
        catch
        {
            // Không làm thất bại việc đổi ảnh.
            // FaceId mới đã được lưu và sử dụng thành công.
        }
    }

    var isReplacing =
        !string.IsNullOrWhiteSpace(oldFaceId);

    return Ok(new
    {
        message = isReplacing
            ? "Đổi ảnh khuôn mặt thành công."
            : "Đăng ký khuôn mặt thành công.",

        faceId = newFaceId,

        faceCollectionId = collectionId,

        registeredAt = DateTime.UtcNow,

        replaced = isReplacing
    });
}


}
