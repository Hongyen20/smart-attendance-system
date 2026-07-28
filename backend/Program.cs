using System.Text;
using AttendanceApi.Services;
using AttendanceApi.Settings;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using MongoDB.Driver;

var builder = WebApplication.CreateBuilder(args);

// ---- 1. Đọc cấu hình từ appsettings.json ----
builder.Services.Configure<MongoDbSettings>(
    builder.Configuration.GetSection("MongoDbSettings"));
builder.Services.Configure<JwtSettings>(
    builder.Configuration.GetSection("JwtSettings"));
builder.Services.Configure<SuperAdminSettings>(
    builder.Configuration.GetSection("SuperAdminSettings"));

var jwtSettings = builder.Configuration.GetSection("JwtSettings").Get<JwtSettings>()!;

// ---- 2. Đăng ký kết nối MongoDB (singleton, dùng chung cho cả app) ----
builder.Services.AddSingleton<IMongoClient>(sp =>
{
    var settings = sp.GetRequiredService<Microsoft.Extensions.Options.IOptions<MongoDbSettings>>().Value;
    return new MongoClient(settings.ConnectionString);
});

builder.Services.AddSingleton(sp =>
{
    var settings = sp.GetRequiredService<Microsoft.Extensions.Options.IOptions<MongoDbSettings>>().Value;
    var client = sp.GetRequiredService<IMongoClient>();
    return client.GetDatabase(settings.DatabaseName);
});

// ---- 3. Cấu hình JWT Authentication ----
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtSettings.Issuer,
        ValidAudience = jwtSettings.Audience,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSettings.Key)),
        ClockSkew = TimeSpan.Zero // không cho phép trễ hạn token
    };
});

builder.Services.AddAuthorization();

// ---- 4. CORS — cho phép Flutter web (dev) gọi API ----
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFlutterApp", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
        // Khi lên production, thay AllowAnyOrigin() bằng
        // .WithOrigins("https://your-domain.com") để an toàn hơn.
    });
});

// ---- 4.5 Đăng ký các Service (tầng truy cập MongoDB) ----
builder.Services.AddSingleton<CompanyService>();
builder.Services.AddSingleton<UserService>();

// ---- 5. Controllers + OpenAPI/Swagger UI (dùng OpenAPI built-in của .NET 10) ----
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddOpenApi("v1", options =>
{
    options.AddDocumentTransformer<JwtBearerSecurityDocumentTransformer>();
});

var app = builder.Build();

// ---- 6. Pipeline ----
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.UseSwaggerUI(options =>
    {
        options.SwaggerEndpoint("/openapi/v1.json", "v1");
    });
}

app.UseHttpsRedirection();

app.UseCors("AllowFlutterApp");

app.UseAuthentication(); // PHẢI đứng trước UseAuthorization
app.UseAuthorization();

app.MapControllers();

// ---- 7. Seed tài khoản SuperAdmin nếu chưa tồn tại (chỉ chạy 1 lần) ----
using (var scope = app.Services.CreateScope())
{
    var userService = scope.ServiceProvider.GetRequiredService<UserService>();
    var superAdminSettings = scope.ServiceProvider
        .GetRequiredService<Microsoft.Extensions.Options.IOptions<SuperAdminSettings>>().Value;

    var exists = await userService.ExistsByUsernameAsync(superAdminSettings.Username);
    if (!exists)
    {
        var superAdmin = new AttendanceApi.Models.User
        {
            CompanyId = null,
            Username = superAdminSettings.Username,
            Email = superAdminSettings.Email,
            FullName = superAdminSettings.FullName,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(superAdminSettings.Password),
            Role = "SuperAdmin",
            Status = "Active"
        };
        await userService.CreateAsync(superAdmin);
        Console.WriteLine($"[Seed] Đã tạo tài khoản SuperAdmin: {superAdminSettings.Username}");
    }
}

app.Run();