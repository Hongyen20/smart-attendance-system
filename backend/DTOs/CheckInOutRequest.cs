using System.ComponentModel.DataAnnotations;

namespace AttendanceApi.DTOs;

public class CheckInOutRequest
{
    [Required(ErrorMessage = "Vĩ độ (lat) không được để trống.")]
    [Range(-90, 90, ErrorMessage = "Vĩ độ phải nằm trong khoảng -90 đến 90.")]
    public double Lat { get; set; }

    [Required(ErrorMessage = "Kinh độ (lng) không được để trống.")]
    [Range(-180, 180, ErrorMessage = "Kinh độ phải nằm trong khoảng -180 đến 180.")]
    public double Lng { get; set; }

    public string DeviceId { get; set; } = string.Empty;
}