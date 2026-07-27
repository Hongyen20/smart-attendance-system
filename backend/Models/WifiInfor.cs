namespace AttendanceApi.Models;

// WiFi Information (SSID/BSSID), use in AttendanceRecord (check-in/out) và WifiConfig (config verified).
public class WifiInfo
{
    public string Ssid { get; set; } = string.Empty;
    public string Bssid { get; set; } = string.Empty;
}