using AttendanceApi.DTOs;
using AttendanceApi.Models;
using AttendanceApi.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AttendanceApi.Controllers;

[ApiController]
[Route("api/ip-configs")]
[Authorize(Roles = "Admin")]
public class IpConfigController : ControllerBase
{
    private readonly IpConfigService _ipConfigService;

    public IpConfigController(IpConfigService ipConfigService)
    {
        _ipConfigService = ipConfigService;
    }

    private string? GetCompanyId() => User.FindFirst("companyId")?.Value;

    private static IpConfigResponse ToResponse(IpConfig config) => new()
    {
        Id = config.Id,
        AllowedIp = config.AllowedIp,
        Lat = config.GpsCenter.Lat,
        Lng = config.GpsCenter.Lng,
        RadiusMeters = config.RadiusMeters,
        IsActive = config.IsActive
    };

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var companyId = GetCompanyId();
        if (string.IsNullOrEmpty(companyId))
        {
            return Forbid();
        }

        var configs = await _ipConfigService.GetAllByCompanyAsync(companyId);
        return Ok(configs.Select(ToResponse));
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateIpConfigRequest request)
    {
        var companyId = GetCompanyId();
        if (string.IsNullOrEmpty(companyId))
        {
            return Forbid();
        }

        var config = new IpConfig
        {
            CompanyId = companyId,
            AllowedIp = request.AllowedIp,
            GpsCenter = new GeoLocation { Lat = request.Lat, Lng = request.Lng },
            RadiusMeters = request.RadiusMeters,
            IsActive = true
        };

        await _ipConfigService.CreateAsync(config);

        return Ok(ToResponse(config));
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(string id, [FromBody] UpdateIpConfigRequest request)
    {
        var companyId = GetCompanyId();
        if (string.IsNullOrEmpty(companyId))
        {
            return Forbid();
        }

        var existing = await _ipConfigService.GetByIdAsync(companyId, id);
        if (existing is null)
        {
            return NotFound(new { message = "Không tìm thấy cấu hình IP." });
        }

        existing.AllowedIp = request.AllowedIp;
        existing.GpsCenter = new GeoLocation { Lat = request.Lat, Lng = request.Lng };
        existing.RadiusMeters = request.RadiusMeters;
        existing.IsActive = request.IsActive;

        await _ipConfigService.UpdateAsync(existing);

        return Ok(ToResponse(existing));
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(string id)
    {
        var companyId = GetCompanyId();
        if (string.IsNullOrEmpty(companyId))
        {
            return Forbid();
        }

        var existing = await _ipConfigService.GetByIdAsync(companyId, id);
        if (existing is null)
        {
            return NotFound(new { message = "Không tìm thấy cấu hình IP." });
        }

        await _ipConfigService.DeleteAsync(companyId, id);

        return Ok(new { message = "Đã xóa cấu hình IP." });
    }
}