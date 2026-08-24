namespace AttendanceApi.DTOs;

public class AttendanceHistoryItemResponse
{
    public DateTime WorkDate { get; set; }
    public DateTime? CheckInTime { get; set; }
    public DateTime? CheckOutTime { get; set; }
    public string Status { get; set; } = string.Empty;
    public double WorkingHours { get; set; }
}

public class AttendanceHistoryResponse
{
    public List<AttendanceHistoryItemResponse> Items { get; set; } = new();
    public double TotalHours { get; set; }
    public int DaysWorked { get; set; }

    public int TotalWorkdaysInMonth { get; set; }
}