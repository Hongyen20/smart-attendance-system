using System.Text;
using AttendanceApi.Services;
using AttendanceApi.Settings;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.OpenApi;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi;
using MongoDB.Driver;

var builder = WebApplication.CreateBuilder(args);

// 1. Read config from appsettings.json
builder.Services.Configure<MongoDbSettings>(
    builder.Configuration.GetSection("MongoDbSettings"));
builder.Services.Configure<JwtSettings>(
    builder.Configuration.GetSection("JwtSettings"));
builder.Services.Configure<SuperAdminSettings>(
    builder.Configuration.GetSection("SuperAdminSettings"));

var jwtSettings = builder.Configuration.GetSection("JwtSettings").Get<JwtSettings>()!;

// 2. Register to MongoDB
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

// 3. JWT Authentication Config
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
        ClockSkew = TimeSpan.Zero 
    };
});

builder.Services.AddAuthorization();

// 4. CORS — allow Flutter web (dev) call API
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFlutterApp", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();

    });
});

// 4.5 Register Service (access to MongoDB) 
builder.Services.AddSingleton<CompanyService>();
builder.Services.AddSingleton<UserService>();
builder.Services.AddSingleton<TokenService>();
builder.Services.AddSingleton<AttendanceRecordService>();
builder.Services.AddSingleton<WifiConfigService>();
builder.Services.AddSingleton<LeaveRequestService>();
builder.Services.AddSingleton<AuditLogService>();
builder.Services.AddSingleton<ShiftService>();
builder.Services.AddSingleton<ShiftAssignmentService>();
builder.Services.AddSingleton<CompanyHolidayService>();
builder.Services.AddSingleton<ShiftChangeRequestService>();
builder.Services.AddSingleton<BusinessTripRequestService>();

// 5. Controllers + OpenAPI/Swagger UI
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddOpenApi("v1", options =>
{
    options.AddDocumentTransformer<JwtBearerSecurityDocumentTransformer>();
});

var app = builder.Build();

// 6. Pipeline
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

// 7. Seed account SuperAdmin if don't exist
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

// .NET 10 usse OpenAPI built-in forSwashbuckle.AddSwaggerGen, so security scheme
internal sealed class JwtBearerSecurityDocumentTransformer(IAuthenticationSchemeProvider authenticationSchemeProvider)
    : IOpenApiDocumentTransformer
{
    public async Task TransformAsync(
        OpenApiDocument document,
        OpenApiDocumentTransformerContext context,
        CancellationToken cancellationToken)
    {
        var schemes = await authenticationSchemeProvider.GetAllSchemesAsync();
        if (!schemes.Any(s => s.Name == JwtBearerDefaults.AuthenticationScheme))
        {
            return;
        }

        document.Components ??= new OpenApiComponents();
        document.Components.SecuritySchemes ??= new Dictionary<string, IOpenApiSecurityScheme>();
        document.Components.SecuritySchemes["Bearer"] = new OpenApiSecurityScheme
        {
            Type = SecuritySchemeType.Http,
            Scheme = "bearer",
            BearerFormat = "JWT",
            In = ParameterLocation.Header,
            Description = "Nhập token theo dạng: Bearer {token}"
        };

        document.Security ??= new List<OpenApiSecurityRequirement>();
        document.Security.Add(new OpenApiSecurityRequirement
        {
            [new OpenApiSecuritySchemeReference("Bearer", document)] = []
        });
    }
}