using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AttendanceApi.Controllers;

[ApiController]
[Route("api/utils")]
[Authorize]
public class UtilsController : ControllerBase
{
    [HttpGet("current-ip")]
    public IActionResult GetCurrentIp()
    {
        var ip = Request.Headers["X-Forwarded-For"].FirstOrDefault()?.Split(',').FirstOrDefault()?.Trim()
                 ?? HttpContext.Connection.RemoteIpAddress?.ToString()
                 ?? "unknown";

        return Ok(new { ip });
    }
}