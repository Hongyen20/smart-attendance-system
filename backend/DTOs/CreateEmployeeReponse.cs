namespace AttendanceApi.DTOs;

public class CreateEmployeeResponse
{
    public string EmployeeId { get; set; } = string.Empty;
    public string Username { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;

    // True if email consists of information was send employee
    // False if .... 
    public bool EmailSent { get; set; }
    public string? EmailErrorMessage { get; set; }
}