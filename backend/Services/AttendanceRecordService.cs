using AttendanceApi.Models;
using MongoDB.Driver;

namespace AttendanceApi.Services;

public class AttendanceRecordService
{
    private readonly IMongoCollection<AttendanceRecord> _records;

    public AttendanceRecordService(IMongoDatabase database)
    {
        _records = database.GetCollection<AttendanceRecord>("attendance_records");
    }

    // Use for check-in: check user have check-in in the day?
    public async Task<AttendanceRecord?> GetByUserAndDateAsync(string companyId, string userId, DateTime date)
    {
        return await _records
            .Find(r => r.CompanyId == companyId && r.UserId == userId && r.WorkDate == date.Date)
            .FirstOrDefaultAsync();
    }

    // Attendance history of 1 employee 
    public async Task<List<AttendanceRecord>> GetHistoryByUserAsync(
        string companyId, string userId, DateTime fromDate, DateTime toDate)
    {
        return await _records
            .Find(r => r.CompanyId == companyId
                    && r.UserId == userId
                    && r.WorkDate >= fromDate.Date
                    && r.WorkDate <= toDate.Date)
            .SortByDescending(r => r.WorkDate)
            .ToListAsync();
    }

    // Admin watch attendace information.
    public async Task<List<AttendanceRecord>> GetByCompanyAndDateRangeAsync(
        string companyId, DateTime fromDate, DateTime toDate)
    {
        return await _records
            .Find(r => r.CompanyId == companyId
                    && r.WorkDate >= fromDate.Date
                    && r.WorkDate <= toDate.Date)
            .SortByDescending(r => r.WorkDate)
            .ToListAsync();
    }

    public async Task CreateAsync(AttendanceRecord record)
    {
        await _records.InsertOneAsync(record);
    }

    // Update check-out information to record have created check-in in the same day.
    public async Task UpdateCheckOutAsync(
        string companyId, string userId, DateTime date,
        DateTime checkOutTime, GeoLocation? location, string checkOutIp, string deviceId,
        double workingHours, string status)
    {
        var update = Builders<AttendanceRecord>.Update
            .Set(r => r.CheckOutTime, checkOutTime)
            .Set(r => r.CheckOutLocation, location)
            .Set(r => r.CheckOutIp, checkOutIp)
            .Set(r => r.CheckOutDeviceId, deviceId)
            .Set(r => r.WorkingHours, workingHours)
            .Set(r => r.Status, status);

        await _records.UpdateOneAsync(
            r => r.CompanyId == companyId && r.UserId == userId && r.WorkDate == date.Date,
            update);
    }
}