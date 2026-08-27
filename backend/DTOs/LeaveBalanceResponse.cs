namespace AttendanceApi.DTOs;

public class LeaveBalanceResponse
{
    public int AnnualLeaveDays { get; set; }
    public int UsedDays { get; set; }
    public int RemainingDays { get; set; }
}