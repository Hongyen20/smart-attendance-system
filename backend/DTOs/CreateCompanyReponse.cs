namespace AttendanceApi.DTOs;

public class CreateCompanyResponse
{
    public string CompanyId { get; set; } = string.Empty;
    public string CompanyCode { get; set; } = string.Empty;
    public string CompanyName { get; set; } = string.Empty;

    public string AdminUsername { get; set; } = string.Empty;
    public string AdminFullName { get; set; } = string.Empty;

    public string AdminTemporaryPassword { get; set; } = string.Empty;
}