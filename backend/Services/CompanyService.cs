using AttendanceApi.Models;
using MongoDB.Driver;

namespace AttendanceApi.Services;

public class CompanyService
{
    private readonly IMongoCollection<Company> _companies;

    public CompanyService(IMongoDatabase database)
    {
        _companies = database.GetCollection<Company>("companies");
    }

    public async Task<Company?> GetByIdAsync(string id)
    {
        return await _companies.Find(c => c.Id == id).FirstOrDefaultAsync();
    }

    public async Task<Company?> GetByCompanyCodeAsync(string companyCode)
    {
        return await _companies.Find(c => c.CompanyCode == companyCode).FirstOrDefaultAsync();
    }

    public async Task<bool> ExistsByCompanyCodeAsync(string companyCode)
    {
        return await _companies.Find(c => c.CompanyCode == companyCode).AnyAsync();
    }

    public async Task CreateAsync(Company company)
    {
        await _companies.InsertOneAsync(company);
    }
}