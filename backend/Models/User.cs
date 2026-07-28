using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace AttendanceApi.Models;

public class User
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; } = string.Empty;

    [BsonRepresentation(BsonType.ObjectId)]
    public string? CompanyId { get; set; } // null if Role = SuperAdmin

    public string EmployeeCode { get; set; } = string.Empty; 

    public string Username { get; set; } = string.Empty;     //Login
    public string Email { get; set; } = string.Empty;        //Forget Password

    public string FullName { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public string Role { get; set; } = "Employee"; // SuperAdmin | Admin | Employee

    public string Phone { get; set; } = string.Empty;
    public string Status { get; set; } = "Active"; // Active | Inactive

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}