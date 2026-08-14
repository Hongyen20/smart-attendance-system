using AttendanceApi.Settings;
using MailKit.Net.Smtp;
using MailKit.Security;
using Microsoft.Extensions.Options;
using MimeKit;

namespace AttendanceApi.Services;

public class EmailService
{
    private readonly EmailSettings _settings;

    public EmailService(IOptions<EmailSettings> settings)
    {
        _settings = settings.Value;
    }

    // Send email consist of username + temporary password for new employee
    public async Task SendAccountCredentialsEmailAsync(
        string toEmail, string toName, string companyName, string username, string temporaryPassword)
    {
        var message = new MimeMessage();
        message.From.Add(new MailboxAddress(_settings.SenderName, _settings.SenderEmail));
        message.To.Add(new MailboxAddress(toName, toEmail));
        message.Subject = $"Công ty {companyName} gửi thông tin tài khoản đăng nhập hệ thống điểm danh";

        message.Body = new TextPart("plain")
        {
            Text = $"""
                Xin chào {toName},

                Tài khoản của bạn trên hệ thống đã được tạo thành công bởi quản trị viên của công ty.

                Thông tin đăng nhập tài khoản:
                Tên đăng nhập: {username}
                Mật khẩu: {temporaryPassword}

                Thông tin công ty: {companyName}

                Vui lòng sử dụng thông tin trên để đăng nhập vào hệ thống.

                Lưu ý: Đây là mật khẩu tạm thời. Vui lòng thay đổi mật khẩu sau khi đăng nhập lần đầu và không chia sẻ thông tin tài khoản cho người khác.

                Trân trọng,
                Admin

                Email được gửi tự động, vui lòng không trả lời email này.
                """
        };

        using var client = new SmtpClient();
        await client.ConnectAsync(_settings.SmtpHost, _settings.SmtpPort, SecureSocketOptions.StartTls);
        await client.AuthenticateAsync(_settings.SmtpUsername, _settings.SmtpPassword);
        await client.SendAsync(message);
        await client.DisconnectAsync(true);
    }
}