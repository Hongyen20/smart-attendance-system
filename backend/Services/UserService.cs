using AttendanceApi.Models;
using MongoDB.Driver;

namespace AttendanceApi.Services;

public class UserService
{
    private readonly IMongoCollection<User> _users;

    public UserService(IMongoDatabase database)
    {
        _users = database.GetCollection<User>("users");
    }

    // Login
    public async Task<User?> GetByUsernameAsync(string username)
    {
        return await _users.Find(u => u.Username == username).FirstOrDefaultAsync();
    }

    // Forget Password
    public async Task<User?> GetByEmailAsync(string email)
    {
        return await _users.Find(u => u.Email == email).FirstOrDefaultAsync();
    }
    // For SuperAdmin, companyId = null.
    public async Task<User?> GetByIdAsync(string? companyId, string id)
    {
        return await _users.Find(u => u.Id == id && u.CompanyId == companyId).FirstOrDefaultAsync();
    }

    public async Task<List<User>> GetAllByCompanyAsync(string companyId)
    {
        return await _users.Find(u => u.CompanyId == companyId).ToListAsync();
    }

    public async Task<bool> ExistsByUsernameAsync(string username)
    {
        return await _users.Find(u => u.Username == username).AnyAsync();
    }

    public async Task<bool> ExistsByEmailAsync(string email)
    {
        return await _users.Find(u => u.Email == email).AnyAsync();
    }

    public async Task CreateAsync(User user)
    {
        await _users.InsertOneAsync(user);
    }

    public async Task UpdateAsync(User user)
    {
        user.UpdatedAt = DateTime.UtcNow;
        await _users.ReplaceOneAsync(u => u.Id == user.Id, user);
    }

    // Generated username automatic from CompanyID + UserID, EX: "acme" + "NV001" -> "acme.nv001".
    public static string GenerateUsername(string companyCode, string employeeCode)
    {
        return $"{companyCode}.{employeeCode}".ToLowerInvariant();
    }
}