using AttendanceApi.Models;
using MongoDB.Driver;

namespace AttendanceApi.Services;

public class WifiConfigService
{
    private readonly IMongoCollection<WifiConfig> _configs;

    public WifiConfigService(IMongoDatabase database)
    {
        _configs = database.GetCollection<WifiConfig>("wifi_configs");
    }

    public async Task<List<WifiConfig>> GetAllByCompanyAsync(string companyId)
    {
        return await _configs.Find(c => c.CompanyId == companyId).ToListAsync();
    }

    // Check-in: only get wifi config is turn on and check SSID/BSSID + GPS.
    public async Task<List<WifiConfig>> GetActiveByCompanyAsync(string companyId)
    {
        return await _configs.Find(c => c.CompanyId == companyId && c.IsActive).ToListAsync();
    }

    public async Task<WifiConfig?> GetByIdAsync(string companyId, string id)
    {
        return await _configs.Find(c => c.Id == id && c.CompanyId == companyId).FirstOrDefaultAsync();
    }

    public async Task CreateAsync(WifiConfig config)
    {
        await _configs.InsertOneAsync(config);
    }

    public async Task UpdateAsync(WifiConfig config)
    {
        await _configs.ReplaceOneAsync(c => c.Id == config.Id && c.CompanyId == config.CompanyId, config);
    }

    public async Task DeleteAsync(string companyId, string id)
    {
        await _configs.DeleteOneAsync(c => c.Id == id && c.CompanyId == companyId);
    }
}