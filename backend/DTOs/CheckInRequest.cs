using System.ComponentModel.DataAnnotations;

namespace AttendanceApi.DTOs;

public class CheckInRequest
{
    [Required]
    [Range(-90, 90, ErrorMessage = "Vĩ độ không hợp lệ.")]
    public double Lat { get; set; }

    [Required]
    [Range(-180, 180, ErrorMessage = "Kinh độ không hợp lệ.")]
    public double Lng { get; set; }

    public string? DeviceId { get; set; }
}

public class CheckOutRequest : CheckInRequest
{
}