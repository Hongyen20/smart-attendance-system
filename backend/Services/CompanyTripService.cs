using AttendanceApi.Models;
using MongoDB.Driver;

namespace AttendanceApi.Services;

public class CompanyHolidayService
{
    private readonly IMongoCollection<CompanyHoliday> _holidays;

    public CompanyHolidayService(IMongoDatabase database)
    {
        _holidays = database.GetCollection<CompanyHoliday>("company_holidays");
    }

    public async Task<List<CompanyHoliday>> GetAllByCompanyAsync(string companyId)
    {
        return await _holidays.Find(h => h.CompanyId == companyId).ToListAsync();
    }

    // Check the day is the rest day
    public async Task<CompanyHoliday?> GetByDateAsync(string companyId, DateTime date)
    {
        return await _holidays
            .Find(h => h.CompanyId == companyId && h.Date == date.Date)
            .FirstOrDefaultAsync();
    }

    public async Task CreateAsync(CompanyHoliday holiday)
    {
        await _holidays.InsertOneAsync(holiday);
    }

    public async Task DeleteAsync(string companyId, string id)
    {
        await _holidays.DeleteOneAsync(h => h.Id == id && h.CompanyId == companyId);
    }
}