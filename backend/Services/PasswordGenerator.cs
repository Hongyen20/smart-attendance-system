using System.Security.Cryptography;

namespace AttendanceApi.Services;

public static class PasswordGenerator
{
    private const string Charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

    // Random when create new admin
    public static string Generate(int length = 12)
    {
        var bytes = RandomNumberGenerator.GetBytes(length);
        var chars = new char[length];

        for (var i = 0; i < length; i++)
        {
            chars[i] = Charset[bytes[i] % Charset.Length];
        }

        return new string(chars);
    }
}