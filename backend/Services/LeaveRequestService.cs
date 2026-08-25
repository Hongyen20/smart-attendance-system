using AttendanceApi.Models;
using MongoDB.Driver;

namespace AttendanceApi.Services;

public class LeaveRequestService
{
    private readonly IMongoCollection<LeaveRequest> _requests;

    public LeaveRequestService(IMongoDatabase database)
    {
        _requests = database.GetCollection<LeaveRequest>("leave_requests");
    }

    public async Task<List<LeaveRequest>> GetByUserIdAsync(string companyId, string userId)
    {
        return await _requests
            .Find(r => r.UserId == userId && r.CompanyId == companyId)
            .SortByDescending(r => r.CreatedAt)
            .ToListAsync();
    }

    public async Task<List<LeaveRequest>> GetPendingByCompanyAsync(string companyId)
    {
        return await _requests
            .Find(r => r.CompanyId == companyId && r.Status == "Pending")
            .SortBy(r => r.StartDate)
            .ToListAsync();
    }

    public async Task<LeaveRequest?> GetByIdAsync(string companyId, string id)
    {
        return await _requests.Find(r => r.Id == id && r.CompanyId == companyId).FirstOrDefaultAsync();
    }

    /// Dùng trong logic tính công: tìm đơn nghỉ phép đã Approved của user bao trùm 1 ngày cụ thể.
    public async Task<LeaveRequest?> GetApprovedForDateAsync(string companyId, string userId, DateTime date)
    {
        var day = date.Date;
        return await _requests
            .Find(r => r.CompanyId == companyId
                    && r.UserId == userId
                    && r.Status == "Approved"
                    && r.StartDate <= day
                    && r.EndDate >= day)
            .FirstOrDefaultAsync();
    }

    /// Kiểm tra user đã có đơn nghỉ phép nào (Pending hoặc Approved) trùng khoảng ngày này chưa.
    /// Không tính đơn đã Rejected - đơn bị từ chối không nên chặn việc gửi đơn mới cho cùng ngày đó.
    /// 2 khoảng ngày [start1,end1] và [start2,end2] trùng nhau khi: start1 <= end2 && start2 <= end1.
    public async Task<bool> HasOverlappingRequestAsync(
        string companyId, string userId, DateTime startDate, DateTime endDate)
    {
        return await _requests
            .Find(r => r.CompanyId == companyId
                    && r.UserId == userId
                    && r.Status != "Rejected"
                    && r.StartDate <= endDate
                    && r.EndDate >= startDate)
            .AnyAsync();
    }

    public async Task CreateAsync(LeaveRequest request)
    {
        await _requests.InsertOneAsync(request);
    }

    public async Task UpdateStatusAsync(string companyId, string id, string status, string approvedBy)
    {
        var update = Builders<LeaveRequest>.Update
            .Set(r => r.Status, status)
            .Set(r => r.ApprovedBy, approvedBy)
            .Set(r => r.ApprovedAt, DateTime.UtcNow);

        await _requests.UpdateOneAsync(
            r => r.Id == id && r.CompanyId == companyId,
            update);
    }
}