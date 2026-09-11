# =========================
# Stage 1: Build
# =========================
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build

WORKDIR /src

# Copy project file trước để tận dụng Docker cache
COPY AttendanceApi.csproj ./

RUN dotnet restore "AttendanceApi.csproj"

# Copy toàn bộ source code
COPY . .

# Build application
RUN dotnet build "AttendanceApi.csproj" \
    -c Release \
    -o /app/build \
    --no-restore


# =========================
# Stage 2: Publish
# =========================
FROM build AS publish

RUN dotnet publish "AttendanceApi.csproj" \
    -c Release \
    -o /app/publish \
    --no-restore \
    /p:UseAppHost=false


# =========================
# Stage 3: Runtime
# =========================
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final

WORKDIR /app

# Copy published application
COPY --from=publish /app/publish .

# ASP.NET Core listens on port 8080
ENV ASPNETCORE_HTTP_PORTS=8080

EXPOSE 8080

ENTRYPOINT ["dotnet", "AttendanceApi.dll"]