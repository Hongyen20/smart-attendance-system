using System.ComponentModel.DataAnnotations;

namespace AttendanceApi.DTOs;

public class CreateShiftChangeRequest : IValidatableObject
{
    [Required(ErrorMessage = "Ngày áp dụng không được để trống.")]
    public DateTime EffectiveDate { get; set; }

    [Required(ErrorMessage = "Loại ca làm việc không được để trống.")]
    [RegularExpression("^(Fixed|Flexible)$", ErrorMessage = "Loại ca chỉ nhận Fixed hoặc Flexible.")]
    public string RequestedShiftType { get; set; } = "Fixed";

    [Required(ErrorMessage = "Thời gian bắt đầu không được để trống.")]
    [RegularExpression(@"^([01]\d|2[0-3]):([0-5]\d)$", ErrorMessage = "Thời gian bắt đầu phải đúng dạng HH:mm.")]
    public string RequestedStartTime { get; set; } = string.Empty;

    [Required(ErrorMessage = "Thời gian kết thúc không được để trống.")]
    [RegularExpression(@"^([01]\d|2[0-3]):([0-5]\d)$", ErrorMessage = "Thời gian kết thúc phải đúng dạng HH:mm.")]
    public string RequestedEndTime { get; set; } = string.Empty;

    public string Reason { get; set; } = string.Empty;

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        if (TimeSpan.TryParse(RequestedStartTime, out var start) &&
            TimeSpan.TryParse(RequestedEndTime, out var end))
        {
            if (end <= start)
            {
                yield return new ValidationResult(
                    "Thời gian kết thúc phải sau thời gian bắt đầu.",
                    new[] { nameof(RequestedEndTime) });
            }
        }
    }
}