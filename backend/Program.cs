using System.Text;
using Amazon;
using Amazon.Rekognition;
using AttendanceApi.Services;
using AttendanceApi.Settings;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.AspNetCore.OpenApi;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi;
using MongoDB.Driver;

using AttendanceApi.Middlewares;

var builder = WebApplication.CreateBuilder(args);

Directory.CreateDirectory(
    Path.Combine(builder.Environment.ContentRootPath, "wwwroot")
);

// 1. Đọc cấu hình từ appsettings.json
builder.Services.Configure<MongoDbSettings>(
    builder.Configuration.GetSection("MongoDbSettings"));

builder.Services.Configure<JwtSettings>(
    builder.Configuration.GetSection("JwtSettings"));

builder.Services.Configure<SuperAdminSettings>(
    builder.Configuration.GetSection("SuperAdminSettings"));

builder.Services.Configure<EmailSettings>(
    builder.Configuration.GetSection("EmailSettings"));

var jwtSettings =
    builder.Configuration.GetSection("JwtSettings").Get<JwtSettings>()!;


// 2. Đăng ký kết nối MongoDB (singleton, dùng chung cho cả app)
builder.Services.AddSingleton<IMongoClient>(sp =>
{
    var settings =
        sp.GetRequiredService<
            Microsoft.Extensions.Options.IOptions<MongoDbSettings>>().Value;

    return new MongoClient(settings.ConnectionString);
});

builder.Services.AddSingleton(sp =>
{
    var settings =
        sp.GetRequiredService<
            Microsoft.Extensions.Options.IOptions<MongoDbSettings>>().Value;

    var client = sp.GetRequiredService<IMongoClient>();

    return client.GetDatabase(settings.DatabaseName);
});


// 3. Cấu hình JWT Authentication
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme =
        JwtBearerDefaults.AuthenticationScheme;

    options.DefaultChallengeScheme =
        JwtBearerDefaults.AuthenticationScheme;
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

        IssuerSigningKey =
            new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(jwtSettings.Key)),

        ClockSkew = TimeSpan.Zero
    };
});

builder.Services.AddAuthorization();


// 4. CORS — cho phép Flutter Web gọi API
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFlutterApp", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});


// 4.1 Forwarded Headers — đọc đúng IP client khi backend chạy sau Nginx
builder.Services.Configure<ForwardedHeadersOptions>(options =>
{
    options.ForwardedHeaders =
        ForwardedHeaders.XForwardedFor |
        ForwardedHeaders.XForwardedProto;

    options.KnownProxies.Clear();
    options.KnownNetworks.Clear();
});


// 4.2 Amazon Rekognition
// EC2 sẽ sử dụng IAM Role để cấp credentials.
// Không cần Access Key / Secret Key trong source code.
builder.Services.AddSingleton<IAmazonRekognition>(_ =>
{
    var region = RegionEndpoint.GetBySystemName("ap-southeast-2");

    return new AmazonRekognitionClient(region);
});


// 4.5 Đăng ký các Service
builder.Services.AddSingleton<CompanyService>();
builder.Services.AddSingleton<UserService>();
builder.Services.AddSingleton<TokenService>();
builder.Services.AddSingleton<EmailService>();
builder.Services.AddSingleton<CounterService>();
builder.Services.AddSingleton<AttendanceRecordService>();
builder.Services.AddSingleton<IpConfigService>();
builder.Services.AddSingleton<LeaveRequestService>();
builder.Services.AddSingleton<AuditLogService>();
builder.Services.AddSingleton<CompanyHolidayService>();
builder.Services.AddSingleton<ShiftChangeRequestService>();
builder.Services.AddSingleton<BusinessTripRequestService>();


// Face Recognition Service
// Service này sẽ sử dụng IAmazonRekognition ở trên.
builder.Services.AddSingleton<FaceRecognitionService>();


// 5. Controllers + OpenAPI/Swagger UI
// Dùng OpenAPI built-in của .NET 10

builder.Services.AddControllers();

builder.Services.AddEndpointsApiExplorer();

builder.Services.AddOpenApi("v1", options =>
{
    options.AddDocumentTransformer<
        JwtBearerSecurityDocumentTransformer>();
});


var app = builder.Build();


// 6. Pipeline
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();

    app.UseSwaggerUI(options =>
    {
        options.SwaggerEndpoint(
            "/openapi/v1.json",
            "v1");
    });
}

app.UseForwardedHeaders();

app.UseHttpsRedirection();

app.UseStaticFiles();

app.UseCors("AllowFlutterApp");

app.UseAuthentication();

app.UseMiddleware<CompanyStatusMiddleware>();

app.UseAuthorization();

app.MapControllers();


// 7. Seed tài khoản SuperAdmin nếu chưa tồn tại
using (var scope = app.Services.CreateScope())
{
    var userService =
        scope.ServiceProvider.GetRequiredService<UserService>();

    var superAdminSettings =
        scope.ServiceProvider
            .GetRequiredService<
                Microsoft.Extensions.Options.IOptions<SuperAdminSettings>>()
            .Value;

    var exists =
        await userService.ExistsByUsernameAsync(
            superAdminSettings.Username);

    if (!exists)
    {
        var superAdmin = new AttendanceApi.Models.User
        {
            CompanyId = null,
            Username = superAdminSettings.Username,
            Email = superAdminSettings.Email,
            FullName = superAdminSettings.FullName,
            PasswordHash =
                BCrypt.Net.BCrypt.HashPassword(
                    superAdminSettings.Password),
            Role = "SuperAdmin",
            Status = "Active"
        };

        await userService.CreateAsync(superAdmin);

        Console.WriteLine(
            $"[Seed] Đã tạo tài khoản SuperAdmin: {superAdminSettings.Username}");
    }
}


app.Run();


internal sealed class JwtBearerSecurityDocumentTransformer(
    IAuthenticationSchemeProvider authenticationSchemeProvider)
    : IOpenApiDocumentTransformer
{
    public async Task TransformAsync(
        OpenApiDocument document,
        OpenApiDocumentTransformerContext context,
        CancellationToken cancellationToken)
    {
        var schemes =
            await authenticationSchemeProvider
                .GetAllSchemesAsync();

        if (!schemes.Any(
                s => s.Name ==
                     JwtBearerDefaults.AuthenticationScheme))
        {
            return;
        }

        document.Components ??=
            new OpenApiComponents();

        document.Components.SecuritySchemes ??=
            new Dictionary<
                string,
                IOpenApiSecurityScheme>();

        document.Components.SecuritySchemes["Bearer"] =
            new OpenApiSecurityScheme
            {
                Type = SecuritySchemeType.Http,
                Scheme = "bearer",
                BearerFormat = "JWT",
                In = ParameterLocation.Header,
                Description =
                    "Nhập token theo dạng: Bearer {token}"
            };

        document.Security ??=
            new List<OpenApiSecurityRequirement>();

        document.Security.Add(
            new OpenApiSecurityRequirement
            {
                [
                    new OpenApiSecuritySchemeReference(
                        "Bearer",
                        document)
                ] = []
            });
    }
}
