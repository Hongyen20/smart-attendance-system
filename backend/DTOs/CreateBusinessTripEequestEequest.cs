using System.ComponentModel.DataAnnotations;

namespace AttendanceApi.DTOs;

public class CreateBusinessTripRequestRequest : IValidatableObject
{
    [Required(ErrorMessage = "Từ ngày không được để trống.")]
    public DateTime StartDate { get; set; }

    [Required(ErrorMessage = "Đến ngày không được để trống.")]
    public DateTime EndDate { get; set; }

    [Required(ErrorMessage = "Địa điểm công tác không được để trống.")]
    public string Destination { get; set; } = string.Empty;

    public string Reason { get; set; } = string.Empty;

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        if (EndDate.Date < StartDate.Date)
        {
            yield return new ValidationResult("Đến ngày phải sau hoặc bằng Từ ngày.", new[] { nameof(EndDate) });
        }
    }
}