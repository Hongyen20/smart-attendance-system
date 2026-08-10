import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ApiResult<T> {
  final bool success;
  final T? data;
  final String? errorMessage;

  ApiResult.success(this.data) : success = true, errorMessage = null;
  ApiResult.failure(this.errorMessage) : success = false, data = null;
}

class ApiService {
  static Future<ApiResult<Map<String, dynamic>>> post(
    String path,
    Map<String, dynamic> body, {
    String? bearerToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}$path'),
        headers: {
          'Content-Type': 'application/json',
          if (bearerToken != null) 'Authorization': 'Bearer $bearerToken',
        },
        body: jsonEncode(body),
      );

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResult.success(decoded);
      }

      // Backend send error { "message": "..." } or { "errors": {...} } (validation)
      final message = decoded['message'] as String? ?? _extractValidationError(decoded);
      return ApiResult.failure(message ?? 'Đã có lỗi xảy ra (mã ${response.statusCode}).');
    } catch (e) {
      return ApiResult.failure('Không thể kết nối tới máy chủ. Kiểm tra lại mạng hoặc backend đã chạy chưa.');
    }
  }

  static String? _extractValidationError(Map<String, dynamic> decoded) {
    final errors = decoded['errors'] as Map<String, dynamic>?;
    if (errors == null || errors.isEmpty) return null;
    final firstField = errors.values.first;
    if (firstField is List && firstField.isNotEmpty) {
      return firstField.first.toString();
    }
    return null;
  }
}