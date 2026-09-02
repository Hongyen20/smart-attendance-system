using System.ComponentModel.DataAnnotations;

namespace AttendanceApi.DTOs;

public class UpdateCompanyStatusRequest
{
    [Required(ErrorMessage = "Trạng thái không được để trống.")]
    [RegularExpression("^(Active|Suspended)$", ErrorMessage = "Trạng thái chỉ nhận giá trị Active hoặc Suspended.")]
    public string Status { get; set; } = string.Empty;
}