using AttendanceApi.Models;
using MongoDB.Driver;

namespace AttendanceApi.Services;

public class BusinessTripRequestService
{
    private readonly IMongoCollection<BusinessTripRequest> _requests;

    public BusinessTripRequestService(IMongoDatabase database)
    {
        _requests = database.GetCollection<BusinessTripRequest>("business_trip_requests");
    }

    public async Task<List<BusinessTripRequest>> GetByUserIdAsync(string companyId, string userId)
    {
        return await _requests
            .Find(r => r.UserId == userId && r.CompanyId == companyId)
            .SortByDescending(r => r.CreatedAt)
            .ToListAsync();
    }

    public async Task<List<BusinessTripRequest>> GetPendingByCompanyAsync(string companyId)
    {
        return await _requests
            .Find(r => r.CompanyId == companyId && r.Status == "Pending")
            .SortBy(r => r.StartDate)
            .ToListAsync();
    }

    public async Task<BusinessTripRequest?> GetByIdAsync(string companyId, string id)
    {
        return await _requests.Find(r => r.Id == id && r.CompanyId == companyId).FirstOrDefaultAsync();
    }

    // Find BusinessTripRequest have Approved of user
    public async Task<BusinessTripRequest?> GetApprovedTripForDateAsync(string companyId, string userId, DateTime date)
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

    public async Task CreateAsync(BusinessTripRequest request)
    {
        await _requests.InsertOneAsync(request);
    }

    public async Task UpdateStatusAsync(string companyId, string id, string status, string approvedBy)
    {
        var update = Builders<BusinessTripRequest>.Update
            .Set(r => r.Status, status)
            .Set(r => r.ApprovedBy, approvedBy)
            .Set(r => r.ApprovedAt, DateTime.UtcNow);

        await _requests.UpdateOneAsync(
            r => r.Id == id && r.CompanyId == companyId,
            update);
    }
}