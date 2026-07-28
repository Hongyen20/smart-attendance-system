using AttendanceApi.Models;
using MongoDB.Driver;

namespace AttendanceApi.Services;

public class ShiftAssignmentService
{
    private readonly IMongoCollection<ShiftAssignment> _assignments;

    public ShiftAssignmentService(IMongoDatabase database)
    {
        _assignments = database.GetCollection<ShiftAssignment>("shift_assignments");
    }

    // 1 staff have 1 document shift — null if not have shift.
    public async Task<ShiftAssignment?> GetByUserIdAsync(string companyId, string userId)
    {
        return await _assignments
            .Find(a => a.UserId == userId && a.CompanyId == companyId)
            .FirstOrDefaultAsync();
    }

    public async Task<List<ShiftAssignment>> GetAllByCompanyAsync(string companyId)
    {
        return await _assignments.Find(a => a.CompanyId == companyId).ToListAsync();
    }

    // Create new if the staff don't have shift
    public async Task UpsertAsync(ShiftAssignment assignment)
    {
        assignment.UpdatedAt = DateTime.UtcNow;
        await _assignments.ReplaceOneAsync(
            a => a.UserId == assignment.UserId && a.CompanyId == assignment.CompanyId,
            assignment,
            new ReplaceOptions { IsUpsert = true });
    }
}