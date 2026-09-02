using System.ComponentModel.DataAnnotations;

namespace AttendanceApi.DTOs;

public class UpdateCompanyRequest
{
    [Required(ErrorMessage = "Tên công ty không được để trống.")]
    public string CompanyName { get; set; } = string.Empty;

    [Required(ErrorMessage = "Mã công ty không được để trống.")]
    public string CompanyCode { get; set; } = string.Empty;

    public string Address { get; set; } = string.Empty;

    [Required(ErrorMessage = "Email công ty không được để trống.")]
    [EmailAddress(ErrorMessage = "Email công ty không hợp lệ.")]
    public string ContactEmail { get; set; } = string.Empty;

    public string ContactPhone { get; set; } = string.Empty;
}