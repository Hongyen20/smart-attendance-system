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
   // Upload file dạng multipart/form-data (dùng cho avatar).
   // Nhận vào bytes thay vì đường dẫn file để hoạt động được trên MỌI nền tảng
   // kể cả web (trên web không có file path thật, chỉ có bytes trong bộ nhớ).
  static Future<ApiResult<Map<String, dynamic>>> uploadBytes(
    String path,
    String fieldName,
    List<int> bytes,
    String filename, {
    String? bearerToken,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}$path'),
      );
      if (bearerToken != null) {
        request.headers['Authorization'] = 'Bearer $bearerToken';
      }
      request.files.add(
        http.MultipartFile.fromBytes(fieldName, bytes, filename: filename),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResult.success(decoded);
      }

      final message = decoded['message'] as String?;
      return ApiResult.failure(
        message ?? 'Đã có lỗi xảy ra (mã ${response.statusCode}).',
      );
    } catch (e) {
      return ApiResult.failure(
        'Không thể tải ảnh lên',
      );
    }
  }

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

      final message =
          decoded['message'] as String? ?? _extractValidationError(decoded);
      return ApiResult.failure(
        message ?? 'Đã có lỗi xảy ra (mã ${response.statusCode}).',
      );
    } catch (e) {
      return ApiResult.failure(
        'Không thể kết nối tới máy chủ',
      );
    }
  }

   // Dùng cho các endpoint trả về object JSON đơn (ví dụ GET /api/utils/current-ip).
  static Future<ApiResult<Map<String, dynamic>>> get(
    String path, {
    String? bearerToken,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}$path'),
        headers: {
          if (bearerToken != null) 'Authorization': 'Bearer $bearerToken',
        },
      );

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResult.success(decoded);
      }

      final message = decoded['message'] as String?;
      return ApiResult.failure(
        message ?? 'Đã có lỗi xảy ra (mã ${response.statusCode}).',
      );
    } catch (e) {
      return ApiResult.failure(
        'Không thể kết nối tới máy chủ',
      );
    }
  }

   // Dùng cho các endpoint trả về mảng JSON (ví dụ GET /api/employees).
  static Future<ApiResult<List<dynamic>>> getList(
    String path, {
    String? bearerToken,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}$path'),
        headers: {
          if (bearerToken != null) 'Authorization': 'Bearer $bearerToken',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body) as List<dynamic>;
        return ApiResult.success(decoded);
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final message = decoded['message'] as String?;
      return ApiResult.failure(
        message ?? 'Đã có lỗi xảy ra (mã ${response.statusCode}).',
      );
    } catch (e) {
      return ApiResult.failure(
        'Không thể kết nối tới máy chủ',
      );
    }
  }

  static Future<ApiResult<Map<String, dynamic>>> put(
    String path,
    Map<String, dynamic> body, {
    String? bearerToken,
  }) async {
    try {
      final response = await http.put(
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

      final message =
          decoded['message'] as String? ?? _extractValidationError(decoded);
      return ApiResult.failure(
        message ?? 'Đã có lỗi xảy ra (mã ${response.statusCode}).',
      );
    } catch (e) {
      return ApiResult.failure(
        'Không thể kết nối tới máy chủ',
      );
    }
  }

  static Future<ApiResult<Map<String, dynamic>>> delete(
    String path, {
    String? bearerToken,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}$path'),
        headers: {
          if (bearerToken != null) 'Authorization': 'Bearer $bearerToken',
        },
      );

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResult.success(decoded);
      }

      final message = decoded['message'] as String?;
      return ApiResult.failure(
        message ?? 'Đã có lỗi xảy ra (mã ${response.statusCode}).',
      );
    } catch (e) {
      return ApiResult.failure(
        'Không thể kết nối tới máy chủ',
      );
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
