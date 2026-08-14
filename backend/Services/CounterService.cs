using MongoDB.Bson;
using MongoDB.Driver;

namespace AttendanceApi.Services;

public class CounterService
{
    private readonly IMongoCollection<BsonDocument> _counters;

    public CounterService(IMongoDatabase database)
    {
        _counters = database.GetCollection<BsonDocument>("counters");
    }

// Generate an incrementing sequence number using MongoDB's atomic increment
// instead of counting existing records and adding 1—the standard counting
// method risks duplicate numbers if two admins create records simultaneously.
    public async Task<int> GetNextSequenceAsync(string key)
    {
        var filter = Builders<BsonDocument>.Filter.Eq("_id", key);
        var update = Builders<BsonDocument>.Update.Inc("value", 1);
        var options = new FindOneAndUpdateOptions<BsonDocument>
        {
            IsUpsert = true,
            ReturnDocument = ReturnDocument.After
        };

        var result = await _counters.FindOneAndUpdateAsync(filter, update, options);
        return result["value"].AsInt32;
    }
}