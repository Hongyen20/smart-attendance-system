using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace AttendanceApi.Models;

public class User
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; } = string.Empty;

    [BsonRepresentation(BsonType.ObjectId)]
    public string? CompanyId { get; set; } // null nếu Role = SuperAdmin

    public string EmployeeCode { get; set; } = string.Empty; // duy nhất theo companyId, không dùng để login

    public string Username { get; set; } = string.Empty;    
    public string Email { get; set; } = string.Empty;        

    public string FullName { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public string Role { get; set; } = "Employee"; // SuperAdmin | Admin | Employee

    public string Phone { get; set; } = string.Empty;
    public string AvatarUrl { get; set; } = string.Empty;

    /// Số ngày phép được cấp/năm - Admin đặt khi tạo/sửa nhân viên. Mặc định 12.
    public int AnnualLeaveDays { get; set; } = 12;

    // Ca làm việc hiện tại - mặc định 08:00-18:00 (10 tiếng, đúng quy định thông thường).
    // Bị cập nhật khi có ShiftChangeRequest được Admin duyệt.
    public string CurrentShiftType { get; set; } = "Fixed"; // Fixed | Flexible
    public string CurrentShiftStart { get; set; } = "08:00"; // "HH:mm"
    public string CurrentShiftEnd { get; set; } = "18:00";   // "HH:mm"
    public double CurrentShiftHours { get; set; } = 10;
    public string Status { get; set; } = "Active"; // Active | Inactive

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}