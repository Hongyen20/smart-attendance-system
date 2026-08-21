using System.ComponentModel.DataAnnotations;

namespace AttendanceApi.DTOs;

public class CreateIpConfigRequest
{
    [Required(ErrorMessage = "Địa chỉ IP không được để trống.")]
    [RegularExpression(
        @"^(\d{1,3}\.){3}\d{1,3}$",
        ErrorMessage = "Địa chỉ IP không đúng định dạng, ví dụ: 118.70.12.34.")]
    public string AllowedIp { get; set; } = string.Empty;

    [Required(ErrorMessage = "Vĩ độ (lat) không được để trống.")]
    [Range(-90, 90, ErrorMessage = "Vĩ độ phải nằm trong khoảng -90 đến 90.")]
    public double Lat { get; set; }

    [Required(ErrorMessage = "Kinh độ (lng) không được để trống.")]
    [Range(-180, 180, ErrorMessage = "Kinh độ phải nằm trong khoảng -180 đến 180.")]
    public double Lng { get; set; }

    [Range(1, 5000, ErrorMessage = "Bán kính phải từ 1 đến 5000 mét.")]
    public double RadiusMeters { get; set; } = 100;
}