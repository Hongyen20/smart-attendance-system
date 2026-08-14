using System.ComponentModel.DataAnnotations;

namespace AttendanceApi.DTOs;

public class CreateEmployeeRequest : IValidatableObject
{
    public string EmployeeCode { get; set; } = string.Empty;

    [Required(ErrorMessage = "Họ tên không được để trống.")]
    public string FullName { get; set; } = string.Empty;

    [Required(ErrorMessage = "Email không được để trống.")]
    [EmailAddress(ErrorMessage = "Email không đúng định dạng.")]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "Số điện thoại không được để trống.")]
    public string Phone { get; set; } = string.Empty;

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