using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace AttendanceApi.Models;

public class User
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; } = string.Empty;

    [BsonRepresentation(BsonType.ObjectId)]
    public string CompanyId { get; set; } = string.Empty;

    public string EmployeeCode { get; set; } = string.Empty; // depend on companyId

    public string Username { get; set; } = string.Empty;     
    public string Email { get; set; } = string.Empty;        

    public string FullName { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public string Role { get; set; } = "Employee"; // Employee | Admin

    [BsonRepresentation(BsonType.ObjectId)]
    public string? DepartmentId { get; set; }

    public string Phone { get; set; } = string.Empty;
    public string Status { get; set; } = "Active"; // Active | Inactive

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}