using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace AttendanceApi.Models;

public class WifiConfig
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; } = string.Empty;

    [BsonRepresentation(BsonType.ObjectId)]
    public string CompanyId { get; set; } = string.Empty;

    public WifiInfo Wifi { get; set; } = new();
    public GeoLocation GpsCenter { get; set; } = new();
    public double RadiusMeters { get; set; } = 100;
    public bool IsActive { get; set; } = true;
}