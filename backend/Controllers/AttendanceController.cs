using System.Security.Claims;
using System.Net;
using AttendanceApi.DTOs;
using AttendanceApi.Models;
using AttendanceApi.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AttendanceApi.Controllers;

[ApiController]
[Route("api/attendance")]
[Authorize(Roles = "Employee")]
public class AttendanceController : ControllerBase
{
    private readonly AttendanceRecordService _attendanceService;
    private readonly IpConfigService _ipConfigService;
    private readonly AuditLogService _auditLogService;
    private readonly LeaveRequestService _leaveRequestService;
    private readonly UserService _userService;
    private readonly FaceRecognitionService _faceRecognitionService;
    private readonly BusinessTripRequestService _businessTripRequestService;

    public AttendanceController(
        AttendanceRecordService attendanceService,
        IpConfigService ipConfigService,
        AuditLogService auditLogService,
        LeaveRequestService leaveRequestService,
        UserService userService,
        FaceRecognitionService faceRecognitionService,
        BusinessTripRequestService businessTripRequestService)
    {
        _attendanceService = attendanceService;
        _ipConfigService = ipConfigService;
        _auditLogService = auditLogService;
        _leaveRequestService = leaveRequestService;
        _userService = userService;
        _faceRecognitionService = faceRecognitionService;
        _businessTripRequestService = businessTripRequestService;
    }

    // CLAIMS

    private string? GetCompanyId()
        => User.FindFirst("companyId")?.Value;

    private string? GetUserId()
        => User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

    // CLIENT IP

    private string GetClientIp()
    {
        // Nginx gửi IPv4

        var realIp =
            Request.Headers["X-Real-IP"]
                .FirstOrDefault();

        if (!string.IsNullOrWhiteSpace(realIp))
        {
            var cleanedIp = realIp.Trim();

            if (IsValidIPv4(cleanedIp))
            {
                return cleanedIp;
            }
        }

        // Fallback nếu X-Real-IP không tồn tại.
        var forwarded =
            Request.Headers["X-Forwarded-For"]
                .FirstOrDefault();

        if (!string.IsNullOrWhiteSpace(forwarded))
        {
            // Lấy IP đầu tiên và kiểm tra lại nó có phải IPv4 hay không.
            var firstIp = forwarded
                .Split(',')
                .FirstOrDefault()
                ?.Trim();

            if (!string.IsNullOrWhiteSpace(firstIp) &&
                IsValidIPv4(firstIp))
            {
                return firstIp;
            }
        }

        // Fallback cuối cùng.
        var remoteIp =
            HttpContext.Connection.RemoteIpAddress;

        if (remoteIp is not null)
        {
            // Nếu backend nhận IPv4-mapped IPv6.
            if (remoteIp.IsIPv4MappedToIPv6)
            {
                return remoteIp
                    .MapToIPv4()
                    .ToString();
            }

            return remoteIp.ToString();
        }

        return "unknown";
    }

    // VALIDATE IPV4

    private static bool IsValidIPv4(string ip)
    {
        if (string.IsNullOrWhiteSpace(ip))
        {
            return false;
        }

        return IPAddress.TryParse(
                   ip.Trim(),
                   out var parsed)
               &&
               parsed.AddressFamily ==
                   System.Net.Sockets.AddressFamily.InterNetwork;
    }

    // FIND IP CONFIG

    private async Task<IpConfig?> FindMatchingIpConfigAsync(
        string companyId,
        string clientIp)
    {
        var configs =
            await _ipConfigService
                .GetActiveByCompanyAsync(companyId);

        return configs.FirstOrDefault(config =>
            string.Equals(
                config.AllowedIp?.Trim(),
                clientIp.Trim(),
                StringComparison.OrdinalIgnoreCase));
    }

    // CHECK GPS

    private static bool IsWithinGpsRadius(
        IpConfig config,
        double lat,
        double lng)
    {
        var distance =
            GeoUtils.DistanceInMeters(
                config.GpsCenter.Lat,
                config.GpsCenter.Lng,
                lat,
                lng);

        return distance <= config.RadiusMeters;
    }

    // VALIDATE IPV4 + GPS (DÙNG CHUNG)
    //
    // Dùng cho: precheck, check-in, check-out.
    //
    // Trả về:
    //   null          => IPv4 và GPS đều hợp lệ.
    //   IActionResult => lỗi, controller return ngay.
    //
    // failedAction: "CHECK_IN_FAILED" hoặc "CHECK_OUT_FAILED"
    // actionLabel : "chấm công" hoặc "check-out"

    private async Task<IActionResult?> ValidateLocationAsync(
        string companyId,
        string userId,
        string clientIp,
        double lat,
        double lng,
        string failedAction,
        string actionLabel)
    {
        // 1. IP PHẢI XÁC ĐỊNH ĐƯỢC

        if (string.IsNullOrWhiteSpace(clientIp) ||
            clientIp == "unknown")
        {
            await _auditLogService.LogAsync(
                companyId,
                userId,
                failedAction,
                "Không xác định được địa chỉ IPv4.");

            return BadRequest(new
            {
                message =
                    "Không xác định được mạng Wi-Fi bạn đang dùng. " +
                    "Vui lòng thử lại."
            });
        }

        // 2. IP PHẢI LÀ IPv4

        if (!IsValidIPv4(clientIp))
        {
            await _auditLogService.LogAsync(
                companyId,
                userId,
                failedAction,
                $"IP không phải IPv4 hợp lệ. IP={clientIp}");

            return StatusCode(
                403,
                new
                {
                    message =
                        "Mạng bạn đang dùng không hợp lệ. " +
                        "Vui lòng kết nối Wi-Fi của công ty rồi thử lại."
                });
        }

        // 3. CÔNG TY PHẢI CÓ CẤU HÌNH IP

        var configs =
            await _ipConfigService
                .GetActiveByCompanyAsync(companyId);

        if (configs.Count == 0)
        {
            return BadRequest(new
            {
                message =
                    "Công ty chưa cấu hình Wi-Fi cho phép chấm công. " +
                    "Vui lòng liên hệ Admin."
            });
        }

        // 4. KIỂM TRA IPV4 CHÍNH XÁC
        //
        // Sai IPv4 => DỪNG NGAY, không kiểm tra GPS.

        var matchedIpConfig =
            await FindMatchingIpConfigAsync(
                companyId,
                clientIp);

        if (matchedIpConfig is null)
        {
            await _auditLogService.LogAsync(
                companyId,
                userId,
                failedAction,
                $"IPv4 không khớp cấu hình. " +
                $"ClientIPv4={clientIp}");

            return StatusCode(
                403,
                new
                {
                    message =
                        "Bạn chưa kết nối Wi-Fi của công ty " +
                        $"nên không thể {actionLabel}. " +
                        "Vui lòng kết nối đúng Wi-Fi rồi thử lại."
                });
        }

        // 5. IPV4 ĐÚNG => KIỂM TRA GPS

        var isGpsValid =
            IsWithinGpsRadius(
                matchedIpConfig,
                lat,
                lng);

        if (!isGpsValid)
        {
            var distance =
                GeoUtils.DistanceInMeters(
                    matchedIpConfig.GpsCenter.Lat,
                    matchedIpConfig.GpsCenter.Lng,
                    lat,
                    lng);

            await _auditLogService.LogAsync(
                companyId,
                userId,
                failedAction,
                $"IPv4 đúng nhưng GPS không hợp lệ. " +
                $"IP={clientIp}, " +
                $"Lat={lat}, " +
                $"Lng={lng}, " +
                $"Distance={distance}m, " +
                $"Radius={matchedIpConfig.RadiusMeters}m");

            return StatusCode(
                403,
                new
                {
                    message =
                        "Bạn đã kết nối đúng Wi-Fi nhưng đang ở ngoài " +
                        $"phạm vi {actionLabel}."
                });
        }

        return null;
    }

    // CHECK-IN STATUS

    private static string DetermineCheckInStatus(
        User employee,
        DateTime checkInTimeUtc)
    {
        // Flexible Time không bị ràng buộc giờ cố định.
        if (employee.CurrentShiftType == "Flexible")
        {
            return "OnTime";
        }

        if (TimeSpan.TryParse(
                employee.CurrentShiftStart,
                out var shiftStart))
        {
            var checkInTimeOfDay =
                checkInTimeUtc.TimeOfDay;

            return checkInTimeOfDay > shiftStart
                ? "Late"
                : "OnTime";
        }

        return "OnTime";
    }

    // HISTORY

    [HttpGet("history")]
    public async Task<IActionResult> GetHistory(
        [FromQuery] int year,
        [FromQuery] int month)
    {
        var companyId = GetCompanyId();
        var userId = GetUserId();

        if (string.IsNullOrEmpty(companyId) ||
            string.IsNullOrEmpty(userId))
        {
            return Forbid();
        }

        if (month < 1 || month > 12)
        {
            return BadRequest(new
            {
                message = "Tháng không hợp lệ."
            });
        }

        var fromDate =
            new DateTime(year, month, 1);

        var toDate =
            fromDate
                .AddMonths(1)
                .AddDays(-1);

        var records =
            await _attendanceService
                .GetHistoryByUserAsync(
                    companyId,
                    userId,
                    fromDate,
                    toDate);

        var attendanceDates =
            records
                .Select(r => r.WorkDate)
                .ToHashSet();

        var items =
            records
                .Select(r =>
                    new AttendanceHistoryItemResponse
                    {
                        WorkDate = r.WorkDate,
                        CheckInTime = r.CheckInTime,
                        CheckOutTime = r.CheckOutTime,
                        Status = r.Status,
                        WorkingHours = r.WorkingHours
                    })
                .ToList();

        // APPROVED LEAVE

        var approvedLeaves =
            await _leaveRequestService
                .GetApprovedInRangeAsync(
                    companyId,
                    userId,
                    fromDate,
                    toDate);

        foreach (var leave in approvedLeaves)
        {
            var rangeStart =
                leave.StartDate > fromDate
                    ? leave.StartDate
                    : fromDate;

            var rangeEnd =
                leave.EndDate < toDate
                    ? leave.EndDate
                    : toDate;

            for (
                var d = rangeStart;
                d <= rangeEnd;
                d = d.AddDays(1))
            {
                if (attendanceDates.Contains(d))
                {
                    continue;
                }

                items.Add(
                    new AttendanceHistoryItemResponse
                    {
                        WorkDate = d,
                        Status =
                            leave.IsPaid == true
                                ? "PaidLeave"
                                : "UnpaidLeave",
                        LeaveType = leave.Type
                    });
            }
        }

        items =
            items
                .OrderByDescending(i => i.WorkDate)
                .ToList();

        var totalHours =
            Math.Round(
                items.Sum(i => i.WorkingHours),
                2);

        var daysWorked =
            items.Count(i =>
                i.CheckInTime is not null ||
                i.Status == "PaidLeave");

        var today =
            DateTime.UtcNow.Date;

        var countUntil =
            (year == today.Year &&
             month == today.Month)
                ? today
                : toDate;

        var totalWorkdays = 0;

        for (
            var d = fromDate;
            d <= countUntil;
            d = d.AddDays(1))
        {
            if (d.DayOfWeek != DayOfWeek.Saturday &&
                d.DayOfWeek != DayOfWeek.Sunday)
            {
                totalWorkdays++;
            }
        }

        return Ok(
            new AttendanceHistoryResponse
            {
                Items = items,
                TotalHours = totalHours,
                DaysWorked = daysWorked,
                TotalWorkdaysInMonth = totalWorkdays
            });
    }

    // TODAY

    [HttpGet("today")]
    public async Task<IActionResult> GetTodayStatus()
    {
        var companyId = GetCompanyId();
        var userId = GetUserId();

        if (string.IsNullOrEmpty(companyId) ||
            string.IsNullOrEmpty(userId))
        {
            return Forbid();
        }

        var today =
            DateTime.UtcNow.Date;

        var record =
            await _attendanceService
                .GetByUserAndDateAsync(
                    companyId,
                    userId,
                    today);

        if (record is null)
        {
            return Ok(new
            {
                checkedIn = false,
                checkedOut = false,
                checkInTime = (string?)null,
                workingHours = (double?)null
            });
        }

        return Ok(new
        {
            checkedIn =
                record.CheckInTime is not null,

            checkedOut =
                record.CheckOutTime is not null,

            checkInTime =
                record.CheckInTime?.ToString("o"),

            workingHours =
                record.CheckOutTime is not null
                    ? record.WorkingHours
                    : (double?)null
        });
    }

    // PRECHECK (CHECK-IN)
    //
    // Client gọi endpoint này SAU khi lấy IP + GPS
    // và TRƯỚC khi mở camera.
    //
    // NORMAL:
    // FACE ID → ĐÃ CHECK-IN? → IPV4 → GPS
    //
    // BUSINESS TRIP:
    // FACE ID → ĐÃ CHECK-IN?   (BỎ QUA IP/GPS)
    //
    // Body JSON: { "lat": ..., "lng": ..., "deviceId": "..." }
    //
    // OK   => 200 { ok = true, businessTrip = ... }
    // FAIL => 4xx { message = "..." }

    [HttpPost("precheck")]
    public async Task<IActionResult> PreCheck(
        [FromBody] CheckInOutRequest request)
    {
        var companyId = GetCompanyId();
        var userId = GetUserId();

        if (string.IsNullOrEmpty(companyId) ||
            string.IsNullOrEmpty(userId))
        {
            return Forbid();
        }

        // 1. NHÂN VIÊN

        var employee =
            await _userService.GetByIdAsync(
                companyId,
                userId);

        if (employee is null)
        {
            return NotFound(new
            {
                message =
                    "Không tìm thấy thông tin nhân viên."
            });
        }

        // 2. FACE ID

        if (string.IsNullOrWhiteSpace(
                employee.FaceId))
        {
            return BadRequest(new
            {
                message =
                    "Bạn chưa đăng ký khuôn mặt. " +
                    "Vui lòng đăng ký khuôn mặt trước khi check-in."
            });
        }

        // 3. ĐÃ CHECK-IN HÔM NAY CHƯA

        var today =
            DateTime.UtcNow.Date;

        var existing =
            await _attendanceService
                .GetByUserAndDateAsync(
                    companyId,
                    userId,
                    today);

        if (existing is not null &&
            existing.CheckInTime is not null)
        {
            return Conflict(new
            {
                message =
                    "Bạn đã check-in hôm nay rồi."
            });
        }

        // 4. BUSINESS TRIP

        var approvedTrip =
            await _businessTripRequestService
                .GetApprovedTripForDateAsync(
                    companyId,
                    userId,
                    today);

        var isBusinessTrip =
            approvedTrip is not null;

        // 5. NORMAL => IPV4 → GPS

        if (!isBusinessTrip)
        {
            var clientIp =
                GetClientIp();

            var locationError =
                await ValidateLocationAsync(
                    companyId,
                    userId,
                    clientIp,
                    request.Lat,
                    request.Lng,
                    "CHECK_IN_FAILED",
                    "chấm công");

            if (locationError is not null)
            {
                return locationError;
            }
        }

        // 6. OK => CHO PHÉP MỞ CAMERA

        return Ok(new
        {
            ok = true,
            businessTrip = isBusinessTrip
        });
    }

    // CHECK-IN
    //
    // NORMAL:
    // FACE ID → IPV4 → GPS → CAMERA → REKOGNITION → ATTENDANCE
    //
    // BUSINESS TRIP:
    // FACE ID → CAMERA → REKOGNITION → ATTENDANCE
    //             (BỎ QUA IP/GPS)

    [HttpPost("check-in")]
    [RequestSizeLimit(10 * 1024 * 1024)]
    public async Task<IActionResult> CheckIn(
        [FromForm] CheckInOutRequest request,
        IFormFile? faceImage)
    {
        var companyId = GetCompanyId();
        var userId = GetUserId();

        if (string.IsNullOrEmpty(companyId) ||
            string.IsNullOrEmpty(userId))
        {
            return Forbid();
        }

        // 1. LẤY THÔNG TIN NHÂN VIÊN

        var employee =
            await _userService.GetByIdAsync(
                companyId,
                userId);

        if (employee is null)
        {
            return NotFound(new
            {
                message =
                    "Không tìm thấy thông tin nhân viên."
            });
        }

        // 2. KIỂM TRA FACE ID

        if (string.IsNullOrWhiteSpace(
                employee.FaceId))
        {
            await _auditLogService.LogAsync(
                companyId,
                userId,
                "CHECK_IN_FAILED",
                "Nhân viên chưa đăng ký khuôn mặt.");

            return BadRequest(new
            {
                message =
                    "Bạn chưa đăng ký khuôn mặt. " +
                    "Vui lòng đăng ký khuôn mặt trước khi check-in."
            });
        }

        // 3. KIỂM TRA HÔM NAY ĐÃ CHECK-IN CHƯA

        var today =
            DateTime.UtcNow.Date;

        var existing =
            await _attendanceService
                .GetByUserAndDateAsync(
                    companyId,
                    userId,
                    today);

        if (existing is not null &&
            existing.CheckInTime is not null)
        {
            return Conflict(new
            {
                message =
                    "Bạn đã check-in hôm nay rồi."
            });
        }

        // 4. LẤY CLIENT IP

        var clientIp =
            GetClientIp();

        // 5. KIỂM TRA BUSINESS TRIP

        var approvedTrip =
            await _businessTripRequestService
                .GetApprovedTripForDateAsync(
                    companyId,
                    userId,
                    today);

        var isBusinessTrip =
            approvedTrip is not null;

        // 6. NORMAL EMPLOYEE => IPV4 → GPS
        //
        // Vẫn kiểm tra lại ở đây (không tin client
        // đã gọi precheck).

        if (!isBusinessTrip)
        {
            var locationError =
                await ValidateLocationAsync(
                    companyId,
                    userId,
                    clientIp,
                    request.Lat,
                    request.Lng,
                    "CHECK_IN_FAILED",
                    "chấm công");

            if (locationError is not null)
            {
                return locationError;
            }
        }

        // 7. ĐẾN ĐÂY MỚI KIỂM TRA ẢNH CAMERA

        if (faceImage is null ||
            faceImage.Length == 0)
        {
            return BadRequest(new
            {
                message =
                    "Chưa có ảnh khuôn mặt. " +
                    "Vui lòng chụp ảnh để xác thực."
            });
        }

        // 8. GIỚI HẠN LOẠI FILE

        var allowedContentTypes =
            new[]
            {
                "image/jpeg",
                "image/jpg",
                "image/png",
                "image/webp"
            };

        if (!allowedContentTypes.Contains(
                faceImage.ContentType,
                StringComparer.OrdinalIgnoreCase))
        {
            return BadRequest(new
            {
                message =
                    "Ảnh khuôn mặt không đúng định dạng."
            });
        }

        // 9. AWS REKOGNITION

        FaceVerificationResult verification;

        await using (
            var imageStream =
                faceImage.OpenReadStream())
        {
            verification =
                await _faceRecognitionService
                    .VerifyFaceAsync(
                        companyId,
                        userId,
                        imageStream);
        }

        if (!verification.Success)
        {
            await _auditLogService.LogAsync(
                companyId,
                userId,
                "CHECK_IN_FAILED",
                $"Xác thực khuôn mặt thất bại. " +
                $"Message={verification.Message}, " +
                $"Similarity={verification.Similarity}");

            return StatusCode(
                403,
                new
                {
                    message =
                        verification.Message
                });
        }

        // 10. TẠO ATTENDANCE RECORD

        var checkInTime =
            DateTime.UtcNow;

        var record =
            new AttendanceRecord
            {
                CompanyId = companyId,
                UserId = userId,
                WorkDate = today,

                CheckInTime =
                    checkInTime,

                CheckInLocation =
                    new GeoLocation
                    {
                        Lat = request.Lat,
                        Lng = request.Lng
                    },

                CheckInIp =
                    clientIp,

                CheckInDeviceId =
                    request.DeviceId,

                Status =
                    DetermineCheckInStatus(
                        employee,
                        checkInTime)
            };

        await _attendanceService
            .CreateAsync(record);

        // 11. AUDIT LOG

        await _auditLogService.LogAsync(
            companyId,
            userId,
            "CHECK_IN_SUCCESS",
            isBusinessTrip
                ? $"Business trip check-in. " +
                  $"Face verified. " +
                  $"Similarity={verification.Similarity}"
                : $"IPv4={clientIp}. " +
                  $"GPS verified. " +
                  $"Face verified. " +
                  $"Similarity={verification.Similarity}");

        // 12. RESPONSE

        return Ok(new
        {
            message =
                isBusinessTrip
                    ? "Check-in công tác thành công."
                    : "Check-in thành công.",

            checkInTime =
                record.CheckInTime,

            faceSimilarity =
                verification.Similarity,

            businessTrip =
                isBusinessTrip
        });
    }

    // CHECK-OUT
    //
    // NORMAL:
    // IPV4 → GPS
    //
    // BUSINESS TRIP:
    // BỎ QUA IPV4 + GPS

    [HttpPost("check-out")]
    public async Task<IActionResult> CheckOut(
        [FromBody] CheckInOutRequest request)
    {
        var companyId = GetCompanyId();
        var userId = GetUserId();

        if (string.IsNullOrEmpty(companyId) ||
            string.IsNullOrEmpty(userId))
        {
            return Forbid();
        }

        // 1. KIỂM TRA ATTENDANCE HÔM NAY

        var today =
            DateTime.UtcNow.Date;

        var existing =
            await _attendanceService
                .GetByUserAndDateAsync(
                    companyId,
                    userId,
                    today);

        if (existing is null ||
            existing.CheckInTime is null)
        {
            return BadRequest(new
            {
                message =
                    "Bạn chưa check-in hôm nay."
            });
        }

        if (existing.CheckOutTime is not null)
        {
            return Conflict(new
            {
                message =
                    "Bạn đã check-out hôm nay rồi."
            });
        }

        // 2. LẤY CLIENT IP

        var clientIp =
            GetClientIp();

        // 3. KIỂM TRA BUSINESS TRIP

        var approvedTrip =
            await _businessTripRequestService
                .GetApprovedTripForDateAsync(
                    companyId,
                    userId,
                    today);

        var isBusinessTrip =
            approvedTrip is not null;

        // 4. NORMAL EMPLOYEE => IPV4 → GPS

        if (!isBusinessTrip)
        {
            var locationError =
                await ValidateLocationAsync(
                    companyId,
                    userId,
                    clientIp,
                    request.Lat,
                    request.Lng,
                    "CHECK_OUT_FAILED",
                    "check-out");

            if (locationError is not null)
            {
                return locationError;
            }
        }

        // 5. TÍNH GIỜ LÀM

        var checkOutTime =
            DateTime.UtcNow;

        var workingHours =
            Math.Round(
                (
                    checkOutTime -
                    existing.CheckInTime!.Value
                ).TotalHours,
                2);

        // 6. UPDATE ATTENDANCE

        await _attendanceService
            .UpdateCheckOutAsync(
                companyId,
                userId,
                today,
                checkOutTime,

                new GeoLocation
                {
                    Lat = request.Lat,
                    Lng = request.Lng
                },

                clientIp,
                request.DeviceId,
                workingHours,
                existing.Status);

        // 7. AUDIT LOG

        await _auditLogService.LogAsync(
            companyId,
            userId,
            "CHECK_OUT_SUCCESS",
            isBusinessTrip
                ? "Business trip check-out."
                : $"IPv4={clientIp}. GPS verified.");

        // 8. RESPONSE

        return Ok(new
        {
            message =
                isBusinessTrip
                    ? "Check-out công tác thành công."
                    : "Check-out thành công.",

            checkOutTime,

            workingHours,

            businessTrip =
                isBusinessTrip
        });
    }
}