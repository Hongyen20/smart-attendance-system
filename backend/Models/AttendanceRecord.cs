using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace AttendanceApi.Models;

public class AttendanceRecord
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; } = string.Empty;

    [BsonRepresentation(BsonType.ObjectId)]
    public string CompanyId { get; set; } = string.Empty;

    [BsonRepresentation(BsonType.ObjectId)]
    public string UserId { get; set; } = string.Empty;

    [BsonDateTimeOptions(DateOnly = true)]
    public DateTime WorkDate { get; set; }

    public DateTime? CheckInTime { get; set; }
    public GeoLocation? CheckInLocation { get; set; }
    public string CheckInIp { get; set; } = string.Empty;
    public string CheckInDeviceId { get; set; } = string.Empty;

    public DateTime? CheckOutTime { get; set; }
    public GeoLocation? CheckOutLocation { get; set; }
    public string CheckOutIp { get; set; } = string.Empty;
    public string CheckOutDeviceId { get; set; } = string.Empty;

    public string Status { get; set; } = "OnTime"; // OnTime | Late | Absent | MissingCheckout
    public double WorkingHours { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}