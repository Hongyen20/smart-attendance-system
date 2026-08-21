using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace AttendanceApi.Models;

public class IpConfig
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; } = string.Empty;

    [BsonRepresentation(BsonType.ObjectId)]
    public string CompanyId { get; set; } = string.Empty;

    public string AllowedIp { get; set; } = string.Empty;
    public GeoLocation GpsCenter { get; set; } = new();
    public double RadiusMeters { get; set; } = 100;
    public bool IsActive { get; set; } = true;
}