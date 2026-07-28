using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace AttendanceApi.Models;

public class WeeklyScheduleEntry
{
    /// 1 = Monday, 2 = Tuesday ... 7 = Sunday
    public int DayOfWeek { get; set; }

    [BsonRepresentation(BsonType.ObjectId)]
    public string? ShiftId { get; set; } // null = no work
}

public class ShiftAssignment
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; } = string.Empty;

    [BsonRepresentation(BsonType.ObjectId)]
    public string CompanyId { get; set; } = string.Empty;

    [BsonRepresentation(BsonType.ObjectId)]
    public string UserId { get; set; } = string.Empty;

    public List<WeeklyScheduleEntry> WeeklySchedule { get; set; } = new();

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}