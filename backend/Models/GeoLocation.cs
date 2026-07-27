namespace AttendanceApi.Models;

/// GPS coordinates use in AttendanceRecord (check-in/out) and WifiConfig (center radius accept).
public class GeoLocation
{
    public double Lat { get; set; }
    public double Lng { get; set; }
}