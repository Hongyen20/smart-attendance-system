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

    // ============================================================
    // GET COMPANY BY ID
    // ============================================================

    public async Task<Company?> GetByIdAsync(string id)
    {
        return await _companies
            .Find(c => c.Id == id)
            .FirstOrDefaultAsync();
    }

    // ============================================================
    // GET COMPANY BY CODE
    // ============================================================

    public async Task<Company?> GetByCompanyCodeAsync(
        string companyCode)
    {
        return await _companies
            .Find(c => c.CompanyCode == companyCode)
            .FirstOrDefaultAsync();
    }

    // ============================================================
    // CHECK COMPANY CODE EXISTS
    // ============================================================

    public async Task<bool> ExistsByCompanyCodeAsync(
        string companyCode)
    {
        return await _companies
            .Find(c => c.CompanyCode == companyCode)
            .AnyAsync();
    }

    // ============================================================
    // CHECK COMPANY CODE EXISTS EXCEPT CURRENT COMPANY
    // ============================================================

    public async Task<bool> ExistsByCompanyCodeExceptIdAsync(
        string companyCode,
        string id)
    {
        return await _companies
            .Find(c =>
                c.CompanyCode == companyCode &&
                c.Id != id)
            .AnyAsync();
    }

    // ============================================================
    // CREATE COMPANY
    // ============================================================

    public async Task CreateAsync(Company company)
    {
        await _companies.InsertOneAsync(company);
    }

    // ============================================================
    // GET ALL COMPANIES
    // ============================================================

    public async Task<List<Company>> GetAllAsync()
    {
        return await _companies
            .Find(_ => true)
            .SortByDescending(c => c.CreatedAt)
            .ToListAsync();
    }

    // ============================================================
    // UPDATE COMPANY STATUS
    // ============================================================

    public async Task UpdateStatusAsync(
        string id,
        string status)
    {
        var update =
            Builders<Company>.Update
                .Set(c => c.Status, status);

        await _companies.UpdateOneAsync(
            c => c.Id == id,
            update);
    }

    // ============================================================
    // UPDATE COMPANY INFORMATION
    // ============================================================

    public async Task<bool> UpdateInfoAsync(
        string id,
        string companyCode,
        string name,
        string address,
        string contactEmail,
        string contactPhone)
    {
        var update =
            Builders<Company>.Update
                .Set(c => c.CompanyCode, companyCode)
                .Set(c => c.Name, name)
                .Set(c => c.Address, address)
                .Set(c => c.ContactEmail, contactEmail)
                .Set(c => c.ContactPhone, contactPhone);

        var result = await _companies.UpdateOneAsync(
            c => c.Id == id,
            update
        );

        return result.ModifiedCount > 0;
    }
}