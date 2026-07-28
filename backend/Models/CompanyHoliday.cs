using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace AttendanceApi.Models;

public class CompanyHoliday
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; } = string.Empty;

    [BsonRepresentation(BsonType.ObjectId)]
    public string CompanyId { get; set; } = string.Empty;

    [BsonDateTimeOptions(DateOnly = true)]
    public DateTime Date { get; set; }

    public string Name { get; set; } = string.Empty;
    public bool IsPaid { get; set; } = true;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}