using AttendanceApi.Models;
using MongoDB.Driver;

namespace AttendanceApi.Services;

public class AuditLogService
{
    private readonly IMongoCollection<AuditLog> _logs;

    public AuditLogService(IMongoDatabase database)
    {
        _logs = database.GetCollection<AuditLog>("audit_logs");
    }

    /// companyId truyền null khi hành động đến từ SuperAdmin (không thuộc công ty nào).
    public async Task LogAsync(string? companyId, string userId, string action, string details = "", string ipAddress = "")
    {
        var log = new AuditLog
        {
            CompanyId = companyId,
            UserId = userId,
            Action = action,
            Details = details,
            IpAddress = ipAddress
        };
        await _logs.InsertOneAsync(log);
    }

    // Admin check log company
    public async Task<List<AuditLog>> GetByCompanyAsync(string companyId, int limit = 100)
    {
        return await _logs
            .Find(l => l.CompanyId == companyId)
            .SortByDescending(l => l.CreatedAt)
            .Limit(limit)
            .ToListAsync();
    }

    public async Task<List<AuditLog>> GetByUserAsync(string companyId, string userId, int limit = 50)
    {
        return await _logs
            .Find(l => l.CompanyId == companyId && l.UserId == userId)
            .SortByDescending(l => l.CreatedAt)
            .Limit(limit)
            .ToListAsync();
    }
}