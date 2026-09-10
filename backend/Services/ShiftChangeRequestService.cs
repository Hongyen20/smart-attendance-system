using AttendanceApi.Models;
using MongoDB.Driver;

namespace AttendanceApi.Services;

public class ShiftChangeRequestService
{
    private readonly IMongoCollection<ShiftChangeRequest> _requests;

    public ShiftChangeRequestService(IMongoDatabase database)
    {
        _requests = database.GetCollection<ShiftChangeRequest>("shift_change_requests");
    }

    public async Task<List<ShiftChangeRequest>> GetByUserIdAsync(string companyId, string userId)
    {
        return await _requests
            .Find(r => r.UserId == userId && r.CompanyId == companyId)
            .SortByDescending(r => r.CreatedAt)
            .ToListAsync();
    }

    // Danh sách đơn chờ duyệt - Admin dùng để hiển thị hàng đợi cần xử lý.
    public async Task<List<ShiftChangeRequest>> GetPendingByCompanyAsync(string companyId)
    {
        return await _requests
            .Find(r => r.CompanyId == companyId && r.Status == "Pending")
            .SortBy(r => r.EffectiveDate)
            .ToListAsync();
    }

    public async Task<ShiftChangeRequest?> GetByIdAsync(string companyId, string id)
    {
        return await _requests.Find(r => r.Id == id && r.CompanyId == companyId).FirstOrDefaultAsync();
    }

    public async Task CreateAsync(ShiftChangeRequest request)
    {
        await _requests.InsertOneAsync(request);
    }

    // Admin duyệt hoặc từ chối đơn.
    public async Task UpdateStatusAsync(string companyId, string id, string status, string approvedBy)
    {
        var update = Builders<ShiftChangeRequest>.Update
            .Set(r => r.Status, status)
            .Set(r => r.ApprovedBy, approvedBy)
            .Set(r => r.ApprovedAt, DateTime.UtcNow);

        await _requests.UpdateOneAsync(
            r => r.Id == id && r.CompanyId == companyId,
            update);
    }
}