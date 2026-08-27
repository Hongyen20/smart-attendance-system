using System.ComponentModel.DataAnnotations;

namespace AttendanceApi.DTOs;

public class CreateEmployeeRequest : IValidatableObject
{
    [Required(ErrorMessage = "Mã nhân viên không được để trống.")]
    [RegularExpression(@"^[a-zA-Z0-9]+$", ErrorMessage = "Mã nhân viên chỉ được chứa chữ và số.")]
    public string EmployeeCode { get; set; } = string.Empty;

    [Required(ErrorMessage = "Họ tên không được để trống.")]
    public string FullName { get; set; } = string.Empty;

    [Required(ErrorMessage = "Email không được để trống.")]
    [EmailAddress(ErrorMessage = "Email không đúng định dạng.")]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "Số điện thoại không được để trống.")]
    public string Phone { get; set; } = string.Empty;

    // Số ngày phép/năm - không bắt buộc, để trống thì lấy mặc định 12.
    [Range(0, 365, ErrorMessage = "Số ngày phép phải từ 0 đến 365.")]
    public int? AnnualLeaveDays { get; set; }

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        if (!string.IsNullOrEmpty(Phone))
        {
            if (Phone.Length != 10)
            {
                yield return new ValidationResult(
                    "Số điện thoại phải gồm đúng 10 chữ số.",
                    new[] { nameof(Phone) });
            }
            else if (!Phone.All(char.IsDigit))
            {
                yield return new ValidationResult(
                    "Số điện thoại chỉ được chứa chữ số.",
                    new[] { nameof(Phone) });
            }

            if (Phone.Length > 0 && Phone[0] != '0')
            {
                yield return new ValidationResult(
                    "Số điện thoại phải bắt đầu bằng số 0.",
                    new[] { nameof(Phone) });
            }
        }
    }
}