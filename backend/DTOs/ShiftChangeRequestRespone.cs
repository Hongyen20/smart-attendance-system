namespace AttendanceApi.DTOs;

public class ShiftChangeRequestResponse
{
    public string Id { get; set; } = string.Empty;
    public DateTime EffectiveDate { get; set; }
    public string RequestedShiftType { get; set; } = string.Empty;
    public string RequestedStartTime { get; set; } = string.Empty;
    public string RequestedEndTime { get; set; } = string.Empty;
    public double RequestedHours { get; set; }
    public string Reason { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime? ApprovedAt { get; set; }

    // Chỉ có giá trị khi Admin xem danh sách chờ duyệt.
    public string? EmployeeName { get; set; }
    // public string? EmployeeCode { get; set; }
}