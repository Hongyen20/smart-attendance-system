namespace AttendanceApi.DTOs;

public class IpConfigResponse
{
    public string Id { get; set; } = string.Empty;
    public string AllowedIp { get; set; } = string.Empty;
    public double Lat { get; set; }
    public double Lng { get; set; }
    public double RadiusMeters { get; set; }
    public bool IsActive { get; set; }
}