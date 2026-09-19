namespace AttendanceApi.DTOs;

public class BusinessTripRequestResponse
{
    public string Id { get; set; } = string.Empty;
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public string Destination { get; set; } = string.Empty;
    public string Reason { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime? ApprovedAt { get; set; }
    public string? EmployeeName { get; set; }
    public string? EmployeeUsername { get; set; }
}