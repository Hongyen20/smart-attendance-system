namespace AttendanceApi.DTOs;

public class EmployeeSummaryResponse
{
    public string Id { get; set; } = string.Empty;
    public string EmployeeCode { get; set; } = string.Empty;
    public string Username { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string Role { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public int AnnualLeaveDays { get; set; }
    public string CurrentShiftType { get; set; } = string.Empty;
    public string CurrentShiftStart { get; set; } = string.Empty;
    public string CurrentShiftEnd { get; set; } = string.Empty;
    public double CurrentShiftHours { get; set; }
}