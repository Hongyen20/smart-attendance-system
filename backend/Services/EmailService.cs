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

    // Send email when SuperAdmin creates an Admin account for a new company
    public async Task SendAdminAccountEmailAsync(
        string toEmail,
        string toName,
        string companyName,
        string adminUsername,
        string temporaryPassword)
    {
        var message = new MimeMessage();

        message.From.Add(new MailboxAddress(_settings.SenderName, _settings.SenderEmail));
        message.To.Add(new MailboxAddress(toName, toEmail));
        message.Subject = $"Thông tin tài khoản Admin - {companyName}";

        message.Body = new TextPart("html")
        {
            Text = $"""
                <!DOCTYPE html>
                <html lang="vi">
                <head>
                    <meta charset="UTF-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                </head>

                <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">

                    <p>Xin chào quý công ty <strong>{companyName}</strong>,</p>

                    <p>
                        Rất vui vì quý công ty đã sử dụng dịch vụ của chúng tôi.
                    </p>

                    <p>
                        Tài khoản Admin của quý công ty đã được
                        <strong>SuperAdmin</strong> tạo thành công.
                    </p>

                    <p>
                        <strong>Thông tin đăng nhập:</strong>
                    </p>

                    <table style="border-collapse: collapse; margin: 10px 0;">
                        <tr>
                            <td style="padding: 6px 15px 6px 0;"><strong>Tài khoản:</strong></td>
                            <td style="padding: 6px 0;"><code>{adminUsername}</code></td>
                        </tr>
                        <tr>
                            <td style="padding: 6px 15px 6px 0;"><strong>Mật khẩu:</strong></td>
                            <td style="padding: 6px 0;"><code>{temporaryPassword}</code></td>
                        </tr>
                    </table>

                    <p>
                        Vui lòng sử dụng thông tin trên để truy cập tài khoản Admin
                        và bắt đầu quản lý hệ thống, bao gồm việc tạo tài khoản
                        cho các nhân viên của công ty.
                    </p>

                    <p>
                        <strong>Lưu ý:</strong>
                        Đây là mật khẩu tạm thời.
                        Vui lòng thay đổi mật khẩu sau khi đăng nhập lần đầu
                        và không chia sẻ thông tin tài khoản cho người khác.
                    </p>

                    <p>
                        Nếu gặp vấn đề về kỹ thuật trong quá trình sử dụng sản phẩm,
                        vui lòng liên hệ:
                        <strong>{_settings.SenderEmail}</strong>
                    </p>

                    <p>
                        Trân trọng,<br>
                        <strong>{_settings.SenderName}</strong>
                    </p>

                    <p style="color: #777; font-size: 13px;">
                        Email này được gửi tự động, vui lòng không trả lời trực tiếp email này.
                    </p>

                </body>
                </html>
                """
        };

        await SendEmailAsync(message);
    }

    // Send email when Admin creates an Employee account
    public async Task SendEmployeeAccountCredentialsEmailAsync(
        string toEmail,
        string toName,
        string companyName,
        string username,
        string temporaryPassword)
    {
        var message = new MimeMessage();

        message.From.Add(new MailboxAddress(_settings.SenderName, _settings.SenderEmail));
        message.To.Add(new MailboxAddress(toName, toEmail));
        message.Subject = $"Thông tin tài khoản đăng nhập hệ thống - {companyName}";

        message.Body = new TextPart("html")
        {
            Text = $"""
                <!DOCTYPE html>
                <html lang="vi">
                <head>
                    <meta charset="UTF-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                </head>

                <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">

                    <p>Xin chào <strong>{toName}</strong>,</p>

                    <p>
                        Tài khoản của bạn trên hệ thống điểm danh đã được
                        quản trị viên của công ty tạo thành công.
                    </p>

                    <p>
                        <strong>Thông tin đăng nhập:</strong>
                    </p>

                    <table style="border-collapse: collapse; margin: 10px 0;">
                        <tr>
                            <td style="padding: 6px 15px 6px 0;"><strong>Tên đăng nhập:</strong></td>
                            <td style="padding: 6px 0;"><code>{username}</code></td>
                        </tr>
                        <tr>
                            <td style="padding: 6px 15px 6px 0;"><strong>Mật khẩu:</strong></td>
                            <td style="padding: 6px 0;"><code>{temporaryPassword}</code></td>
                        </tr>
                    </table>

                    <p>
                        <strong>Thông tin công ty:</strong>
                        {companyName}
                    </p>

                    <p>
                        Vui lòng sử dụng thông tin trên để đăng nhập vào hệ thống.
                    </p>

                    <p>
                        <strong>Lưu ý:</strong>
                        Đây là mật khẩu tạm thời.
                        Vui lòng thay đổi mật khẩu sau khi đăng nhập lần đầu
                        và không chia sẻ thông tin tài khoản cho người khác.
                    </p>

                    <p>
                        Nếu gặp vấn đề về kỹ thuật trong quá trình sử dụng sản phẩm,
                        vui lòng liên hệ:
                        <strong>{_settings.SenderEmail}</strong>
                    </p>

                    <p>
                        Trân trọng,<br>
                        <strong>{_settings.SenderName}</strong>
                    </p>

                    <p style="color: #777; font-size: 13px;">
                        Email này được gửi tự động, vui lòng không trả lời trực tiếp email này.
                    </p>

                </body>
                </html>
                """
        };

        await SendEmailAsync(message);
    }

    private async Task SendEmailAsync(MimeMessage message)
    {
        using var client = new SmtpClient();
        await client.ConnectAsync(_settings.SmtpHost, _settings.SmtpPort, SecureSocketOptions.StartTls);
        await client.AuthenticateAsync(_settings.SmtpUsername, _settings.SmtpPassword);
        await client.SendAsync(message);
        await client.DisconnectAsync(true);
    }
}