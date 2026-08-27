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

    // Kiểm tra user đã có đơn nghỉ phép nào (Pending hoặc Approved) trùng khoảng ngày này chưa
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

    // Tổng số ngày phép CÓ LƯƠNG đã dùng (đơn Approved + IsPaid=true) - dùng để tính
    // số ngày phép còn lại: AnnualLeaveDays
    public async Task<int> GetUsedPaidLeaveDaysAsync(string companyId, string userId)
    {
        var requests = await _requests
            .Find(r => r.CompanyId == companyId
                    && r.UserId == userId
                    && r.Status == "Approved"
                    && r.IsPaid == true)
            .ToListAsync();

        return requests.Sum(r => (r.EndDate - r.StartDate).Days + 1);
    }

    // Duyệt đơn kèm quyết định có lương hay không (đã tính toán ở Controller dựa vào số ngày phép còn lại).
    public async Task ApproveAsync(string companyId, string id, string approvedBy, bool isPaid)
    {
        var update = Builders<LeaveRequest>.Update
            .Set(r => r.Status, "Approved")
            .Set(r => r.ApprovedBy, approvedBy)
            .Set(r => r.ApprovedAt, DateTime.UtcNow)
            .Set(r => r.IsPaid, isPaid);

        await _requests.UpdateOneAsync(r => r.Id == id && r.CompanyId == companyId, update);
    }

    // Lấy các đơn đã Approved của 1 user, giao với khoảng ngày [fromDate, toDate] -
    // dùng để gộp vào lịch sử chấm công (những ngày nghỉ phép không có bản ghi check-in thật).
    public async Task<List<LeaveRequest>> GetApprovedInRangeAsync(
        string companyId, string userId, DateTime fromDate, DateTime toDate)
    {
        return await _requests
            .Find(r => r.CompanyId == companyId
                    && r.UserId == userId
                    && r.Status == "Approved"
                    && r.StartDate <= toDate
                    && r.EndDate >= fromDate)
            .ToListAsync();
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