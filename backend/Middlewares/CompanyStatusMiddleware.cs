using System.Security.Claims;
using AttendanceApi.Services;

namespace AttendanceApi.Middlewares;

public class CompanyStatusMiddleware
{
    private readonly RequestDelegate _next;

    public CompanyStatusMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context, CompanyService companyService)
    {
        if (context.User.Identity?.IsAuthenticated == true)
        {
            var role = context.User.FindFirst(ClaimTypes.Role)?.Value;
            var companyId = context.User.FindFirst("companyId")?.Value;

            // SuperAdmin có companyId rỗng -> không thuộc công ty nào -> bỏ qua.
            if (role != "SuperAdmin" && !string.IsNullOrEmpty(companyId))
            {
                var company = await companyService.GetByIdAsync(companyId);

                if (company is null || company.Status != "Active")
                {
                    context.Response.StatusCode = StatusCodes.Status403Forbidden;
                    context.Response.ContentType = "application/json";

                    await context.Response.WriteAsync(
                        "{\"message\":\"Công ty của bạn đã bị tạm khóa. Vui lòng liên hệ AttendGo để biết thêm chi tiết.\"}"
                    );

                    return; 
                }
            }
        }

        await _next(context);
    }
}