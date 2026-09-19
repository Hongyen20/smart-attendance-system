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
        var forwarded =
            Request.Headers["X-Forwarded-For"].FirstOrDefault();

        if (!string.IsNullOrEmpty(forwarded))
        {
            return forwarded
                .Split(',')
                .FirstOrDefault()
                ?.Trim()
                ?? "unknown";
        }

        return HttpContext.Connection.RemoteIpAddress?.ToString()
            ?? "unknown";
    }

    // VALIDATE IPV4

    private static bool IsValidIPv4(string ip)
    {
        if (string.IsNullOrWhiteSpace(ip))
        {
            return false;
        }

        return IPAddress.TryParse(
                   ip,
                   out var parsed)
               &&
               parsed.AddressFamily ==
                   System.Net.Sockets.AddressFamily.InterNetwork;
    }

    // FIND MATCHING IP + GPS CONFIG

    private async Task<IpConfig?> FindMatchingConfigAsync(
        string companyId,
        string clientIp,
        double lat,
        double lng)
    {
        var configs =
            await _ipConfigService
                .GetActiveByCompanyAsync(companyId);

        return configs.FirstOrDefault(config =>
            string.Equals(
                config.AllowedIp?.Trim(),
                clientIp.Trim(),
                StringComparison.OrdinalIgnoreCase)
            &&
            GeoUtils.DistanceInMeters(
                config.GpsCenter.Lat,
                config.GpsCenter.Lng,
                lat,
                lng)
            <= config.RadiusMeters
        );
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

    // CHECK-IN
    //
    // NORMAL:
    // FACE ID → IP → GPS → CAMERA → REKOGNITION → ATTENDANCE
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

        // 4. LẤY CLIENT IP TỪ SERVER

        var clientIp =
            GetClientIp();

        // 5. KIỂM TRA ĐI CÔNG TÁC ĐÃ ĐƯỢC DUYỆT

        var approvedTrip =
            await _businessTripRequestService
                .GetApprovedTripForDateAsync(
                    companyId,
                    userId,
                    today);

        var isBusinessTrip =
            approvedTrip is not null;

        // 6. NORMAL EMPLOYEE:
        // KIỂM TRA IP + GPS
        //
        // BUSINESS TRIP:
        // BỎ QUA HOÀN TOÀN IP + GPS

        if (!isBusinessTrip)
        {
            if (string.IsNullOrWhiteSpace(clientIp) ||
                clientIp == "unknown")
            {
                return BadRequest(new
                {
                    message =
                        "Không xác định được địa chỉ IP công cộng."
                });
            }

            // Client IP phải là IPv4.
            if (!IsValidIPv4(clientIp))
            {
                return BadRequest(new
                {
                    message =
                        "Địa chỉ IP công cộng không hợp lệ."
                });
            }

            var configs =
                await _ipConfigService
                    .GetActiveByCompanyAsync(
                        companyId);

            if (configs.Count == 0)
            {
                return BadRequest(new
                {
                    message =
                        "Công ty chưa cấu hình IP cho phép chấm công. " +
                        "Vui lòng liên hệ Admin."
                });
            }

            var matched =
                await FindMatchingConfigAsync(
                    companyId,
                    clientIp,
                    request.Lat,
                    request.Lng);

            if (matched is null)
            {
                await _auditLogService.LogAsync(
                    companyId,
                    userId,
                    "CHECK_IN_FAILED",
                    $"IP hoặc GPS không khớp cấu hình. " +
                    $"IP={clientIp}, " +
                    $"Lat={request.Lat}, " +
                    $"Lng={request.Lng}");

                return StatusCode(
                    403,
                    new
                    {
                        message =
                            "Xác thực vị trí thất bại. " +
                            "Vui lòng đảm bảo bạn đang kết nối đúng mạng " +
                            "và ở trong khu vực công ty."
                    });
            }
        }

        // 7. KIỂM TRA ẢNH CAMERA

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
                : $"Face verified. " +
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
    // IP + GPS
    //
    // BUSINESS TRIP:
    // BỎ QUA IP + GPS

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

        // 3. KIỂM TRA ĐI CÔNG TÁC

        var approvedTrip =
            await _businessTripRequestService
                .GetApprovedTripForDateAsync(
                    companyId,
                    userId,
                    today);

        var isBusinessTrip =
            approvedTrip is not null;

        // 4. NORMAL EMPLOYEE:
        // KIỂM TRA IP + GPS
        //
        // BUSINESS TRIP:
        // BỎ QUA IP + GPS

        if (!isBusinessTrip)
        {
            if (string.IsNullOrWhiteSpace(clientIp) ||
                clientIp == "unknown")
            {
                return BadRequest(new
                {
                    message =
                        "Không xác định được địa chỉ IP công cộng."
                });
            }

            if (!IsValidIPv4(clientIp))
            {
                return BadRequest(new
                {
                    message =
                        "Địa chỉ IP công cộng không hợp lệ."
                });
            }

            var configs =
                await _ipConfigService
                    .GetActiveByCompanyAsync(
                        companyId);

            if (configs.Count == 0)
            {
                return BadRequest(new
                {
                    message =
                        "Công ty chưa cấu hình IP cho phép chấm công. " +
                        "Vui lòng liên hệ Admin."
                });
            }

            var matched =
                await FindMatchingConfigAsync(
                    companyId,
                    clientIp,
                    request.Lat,
                    request.Lng);

            if (matched is null)
            {
                await _auditLogService.LogAsync(
                    companyId,
                    userId,
                    "CHECK_OUT_FAILED",
                    $"IP hoặc GPS không khớp cấu hình. " +
                    $"IP={clientIp}, " +
                    $"Lat={request.Lat}, " +
                    $"Lng={request.Lng}");

                return StatusCode(
                    403,
                    new
                    {
                        message =
                            "Xác thực thất bại. " +
                            "Vui lòng đảm bảo đang kết nối đúng mạng " +
                            "và ở trong khu vực công ty."
                    });
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
        //
        // Giữ nguyên Status OnTime/Late.

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
            "CHECK_OUT_SUCCESS");

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

