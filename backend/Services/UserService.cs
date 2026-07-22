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

    public async Task<User?> GetByEmailAsync(string email)
    {
        return await _users.Find(u => u.Email == email).FirstOrDefaultAsync();
    }

    public async Task<User?> GetByIdAsync(string id)
    {
        return await _users.Find(u => u.Id == id).FirstOrDefaultAsync();
    }

    public async Task CreateAsync(User user)
    {
        await _users.InsertOneAsync(user);
    }
}