using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace AttendanceApi.Models;

public class Shift
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; } = string.Empty;

    [BsonRepresentation(BsonType.ObjectId)]
    public string CompanyId { get; set; } = string.Empty;

    public string Name { get; set; } = string.Empty;
    public string Type { get; set; } = "Fixed"; // Fixed | Flexible

    public string? StartTime { get; set; }
    public string? EndTime { get; set; }

    // Only use for Type = Flexible.
    public double? RequiredHours { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}