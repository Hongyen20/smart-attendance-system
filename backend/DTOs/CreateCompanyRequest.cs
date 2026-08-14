using System.ComponentModel.DataAnnotations;

namespace AttendanceApi.DTOs;

public class CreateCompanyRequest
{
    [Required(ErrorMessage = "Tên công ty không được để trống.")]
    public string CompanyName { get; set; } = string.Empty;

    [Required(ErrorMessage = "Mã công ty không được để trống.")]
    [RegularExpression(@"^[a-zA-Z0-9-]+$", ErrorMessage = "Mã công ty chỉ được chứa chữ, số và dấu gạch ngang.")]
    public string CompanyCode { get; set; } = string.Empty;

    public string Address { get; set; } = string.Empty;

    [EmailAddress(ErrorMessage = "Email liên hệ không đúng định dạng.")]
    public string ContactEmail { get; set; } = string.Empty;

    public string ContactPhone { get; set; } = string.Empty;

}