namespace AttendanceApi.DTOs;

public class AttendanceHistoryItemResponse
{
    public DateTime WorkDate { get; set; }
    public DateTime? CheckInTime { get; set; }
    public DateTime? CheckOutTime { get; set; }
    public string Status { get; set; } = string.Empty;
    public double WorkingHours { get; set; }

    // Chỉ có giá trị khi Status là "PaidLeave" hoặc "UnpaidLeave" - loại đơn nghỉ phép
    // (Nghỉ ốm, Nghỉ phép năm...) tương ứng với ngày này.
    public string? LeaveType { get; set; }
}

public class AttendanceHistoryResponse
{
    public List<AttendanceHistoryItemResponse> Items { get; set; } = new();
    public double TotalHours { get; set; }
    public int DaysWorked { get; set; }

    // Số ngày làm việc (Thứ 2 - Thứ 6) tính từ đầu tháng tới hôm nay (nếu là tháng hiện tại)
    public int TotalWorkdaysInMonth { get; set; }
}