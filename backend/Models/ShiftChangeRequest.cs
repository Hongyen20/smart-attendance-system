using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace AttendanceApi.Models;

public class ShiftChangeRequest
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; } = string.Empty;

    [BsonRepresentation(BsonType.ObjectId)]
    public string CompanyId { get; set; } = string.Empty;

    [BsonRepresentation(BsonType.ObjectId)]
    public string UserId { get; set; } = string.Empty;

    // Ngày bắt đầu áp dụng ca mới - vì đây là đổi CỐ ĐỊNH lịch làm việc (không phải
    // đổi riêng 1 ngày), ngày này chỉ mang tính tham khảo cho Admin biết từ khi nào.
    [BsonDateTimeOptions(DateOnly = true)]
    public DateTime EffectiveDate { get; set; }

    public string RequestedShiftType { get; set; } = "Fixed"; // Fixed | Flexible

    public string RequestedStartTime { get; set; } = string.Empty; // "HH:mm"
    public string RequestedEndTime { get; set; } = string.Empty;   // "HH:mm"

    // Tổng số giờ làm việc - tự tính (end - start) lúc tạo request.
    public double RequestedHours { get; set; }

    public string Reason { get; set; } = string.Empty;
    public string Status { get; set; } = "Pending"; // Pending | Approved | Rejected

    [BsonRepresentation(BsonType.ObjectId)]
    public string? ApprovedBy { get; set; }

    public DateTime? ApprovedAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}