namespace AttendanceApi.DTOs;

public class UpdateIpConfigRequest : CreateIpConfigRequest
{
    public bool IsActive { get; set; } = true;
}