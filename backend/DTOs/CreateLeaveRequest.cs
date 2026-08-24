using System.ComponentModel.DataAnnotations;

namespace AttendanceApi.DTOs;

public class CreateLeaveRequestRequest
{
    [Required(ErrorMessage = "Loại nghỉ phép không được để trống.")]
    public string Type { get; set; } = string.Empty;

    [Required(ErrorMessage = "Từ ngày không được để trống.")]
    public DateTime StartDate { get; set; }

    [Required(ErrorMessage = "Đến ngày không được để trống.")]
    public DateTime EndDate { get; set; }

    public string Reason { get; set; } = string.Empty;
}