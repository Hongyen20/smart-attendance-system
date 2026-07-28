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

    [BsonDateTimeOptions(DateOnly = true)]
    public DateTime RequestedDate { get; set; }

    [BsonRepresentation(BsonType.ObjectId)]
    public string? CurrentShiftId { get; set; }

    [BsonRepresentation(BsonType.ObjectId)]
    public string RequestedShiftId { get; set; } = string.Empty;

    public string Reason { get; set; } = string.Empty;
    public string Status { get; set; } = "Pending"; // Pending | Approved | Rejected

    [BsonRepresentation(BsonType.ObjectId)]
    public string? ApprovedBy { get; set; }

    public DateTime? ApprovedAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}