using AttendanceApi.Models;
using MongoDB.Driver;

namespace AttendanceApi.Services;

public class ShiftService
{
    private readonly IMongoCollection<Shift> _shifts;

    public ShiftService(IMongoDatabase database)
    {
        _shifts = database.GetCollection<Shift>("shifts");
    }

    public async Task<List<Shift>> GetAllByCompanyAsync(string companyId)
    {
        return await _shifts.Find(s => s.CompanyId == companyId).ToListAsync();
    }

    public async Task<Shift?> GetByIdAsync(string companyId, string id)
    {
        return await _shifts.Find(s => s.Id == id && s.CompanyId == companyId).FirstOrDefaultAsync();
    }

    public async Task CreateAsync(Shift shift)
    {
        await _shifts.InsertOneAsync(shift);
    }

    public async Task UpdateAsync(Shift shift)
    {
        await _shifts.ReplaceOneAsync(s => s.Id == shift.Id && s.CompanyId == shift.CompanyId, shift);
    }

    public async Task DeleteAsync(string companyId, string id)
    {
        await _shifts.DeleteOneAsync(s => s.Id == id && s.CompanyId == companyId);
    }
}