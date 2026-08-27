using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace AttendanceApi.Models;

public class LeaveRequest
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; } = string.Empty;

    [BsonRepresentation(BsonType.ObjectId)]
    public string CompanyId { get; set; } = string.Empty;

    [BsonRepresentation(BsonType.ObjectId)]
    public string UserId { get; set; } = string.Empty;

    public string Type { get; set; } = string.Empty; // Annual | Sick | Unpaid | Other

    [BsonDateTimeOptions(DateOnly = true)]
    public DateTime StartDate { get; set; }

    [BsonDateTimeOptions(DateOnly = true)]
    public DateTime EndDate { get; set; }

    public string Reason { get; set; } = string.Empty;
    public string Status { get; set; } = "Pending"; // Pending | Approved | Rejected

    [BsonRepresentation(BsonType.ObjectId)]
    public string? ApprovedBy { get; set; }

    public DateTime? ApprovedAt { get; set; }

    // Chỉ có giá trị sau khi Status = Approved - quyết định lúc duyệt, không tính lại sau đó.
    // true = còn đủ ngày phép, tính công bình thường + đã trừ hạn mức.
    // false = hết ngày phép, xử lý nghỉ không lương, không tính công.
    // null = chưa được duyệt (Pending/Rejected).
    public bool? IsPaid { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}