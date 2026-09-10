using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Net;

namespace AttendanceApi.Controllers;

[ApiController]
[Route("api/utils")]
[Authorize]
public class UtilsController : ControllerBase
{
    [HttpGet("current-ip")]
    public IActionResult GetCurrentIp()
    {
        var forwarded = Request.Headers["X-Forwarded-For"].FirstOrDefault()?.Split(',').FirstOrDefault()?.Trim();

        var rawIp = forwarded ?? HttpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";

        var ip = NormalizeToIPv4(rawIp);

        return Ok(new { ip });
    }

    private static string NormalizeToIPv4(string rawIp)
    {
        if (!IPAddress.TryParse(rawIp, out var parsed))
        {
            return rawIp; 
        }
        if (IPAddress.IsLoopback(parsed))
        {
            return "127.0.0.1";
        }

        if (parsed.IsIPv4MappedToIPv6)
        {
            return parsed.MapToIPv4().ToString();
        }

        return parsed.ToString();
    }
}