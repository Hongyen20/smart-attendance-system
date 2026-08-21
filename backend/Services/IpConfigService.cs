using AttendanceApi.Models;
using MongoDB.Driver;

namespace AttendanceApi.Services;

public class IpConfigService
{
    private readonly IMongoCollection<IpConfig> _configs;

    public IpConfigService(IMongoDatabase database)
    {
        _configs = database.GetCollection<IpConfig>("ip_configs");
    }

    public async Task<List<IpConfig>> GetAllByCompanyAsync(string companyId)
    {
        return await _configs.Find(c => c.CompanyId == companyId).ToListAsync();
    }

    // Use for check-in: check ip
    public async Task<List<IpConfig>> GetActiveByCompanyAsync(string companyId)
    {
        return await _configs.Find(c => c.CompanyId == companyId && c.IsActive).ToListAsync();
    }

    public async Task<IpConfig?> GetByIdAsync(string companyId, string id)
    {
        return await _configs.Find(c => c.Id == id && c.CompanyId == companyId).FirstOrDefaultAsync();
    }

    public async Task CreateAsync(IpConfig config)
    {
        await _configs.InsertOneAsync(config);
    }

    public async Task UpdateAsync(IpConfig config)
    {
        await _configs.ReplaceOneAsync(c => c.Id == config.Id && c.CompanyId == config.CompanyId, config);
    }

    public async Task DeleteAsync(string companyId, string id)
    {
        await _configs.DeleteOneAsync(c => c.Id == id && c.CompanyId == companyId);
    }
}