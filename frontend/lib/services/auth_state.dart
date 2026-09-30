import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AuthState {
  AuthState._internal();
  static final AuthState instance = AuthState._internal();

  String? token;
  String? userId;
  String? username;
  String? fullName;
  String? role;
  String? companyId;
  String? avatarUrl;

  bool get isLoggedIn => token != null;

  // STORAGE KEYS

  static const String _keyToken = 'auth_token';
  static const String _keyUserId = 'auth_user_id';
  static const String _keyUsername = 'auth_username';
  static const String _keyFullName = 'auth_full_name';
  static const String _keyRole = 'auth_role';
  static const String _keyCompanyId = 'auth_company_id';
  static const String _keyAvatarUrl = 'auth_avatar_url';

  // SET SESSION (đăng nhập)

  void setSession({
    required String token,
    required String userId,
    required String username,
    required String fullName,
    required String role,
    String? companyId,
    String? avatarUrl,
  }) {
    this.token = token;
    this.userId = userId;
    this.username = username;
    this.fullName = fullName;
    this.role = role;
    this.companyId = companyId;
    this.avatarUrl = avatarUrl;

    unawaited(_saveToStorage());
  }

  // CLEAR (đăng xuất)
  // Xóa cả trong bộ nhớ lẫn dữ liệu đã lưu trên máy.

  void clear() {
    token = null;
    userId = null;
    username = null;
    fullName = null;
    role = null;
    companyId = null;
    avatarUrl = null;

    unawaited(_removeFromStorage());
  }

  // RESTORE (khi mở app / tải lại trang)
  // Trả về true nếu khôi phục được phiên đăng nhập còn hạn.

  Future<bool> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedToken = prefs.getString(_keyToken);
      final savedUserId = prefs.getString(_keyUserId);
      final savedRole = prefs.getString(_keyRole);

      if (savedToken == null ||
          savedToken.isEmpty ||
          savedUserId == null ||
          savedRole == null) {
        return false;
      }

      // Token hết hạn => bắt đăng nhập lại.
      if (_isTokenExpired(savedToken)) {
        clear();

        return false;
      }

      token = savedToken;
      userId = savedUserId;
      username = prefs.getString(_keyUsername);
      fullName = prefs.getString(_keyFullName);
      role = savedRole;
      companyId = prefs.getString(_keyCompanyId);
      avatarUrl = prefs.getString(_keyAvatarUrl);

      return true;
    } catch (_) {
      return false;
    }
  }

  // STORAGE HELPERS

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await _setOrRemove(prefs, _keyToken, token);
      await _setOrRemove(prefs, _keyUserId, userId);
      await _setOrRemove(prefs, _keyUsername, username);
      await _setOrRemove(prefs, _keyFullName, fullName);
      await _setOrRemove(prefs, _keyRole, role);
      await _setOrRemove(prefs, _keyCompanyId, companyId);
      await _setOrRemove(prefs, _keyAvatarUrl, avatarUrl);
    } catch (_) {
      // Lưu thất bại thì vẫn dùng được trong phiên hiện tại.
    }
  }

  Future<void> _setOrRemove(
    SharedPreferences prefs,
    String key,
    String? value,
  ) async {
    if (value == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, value);
    }
  }

  Future<void> _removeFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_keyToken);
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyUsername);
      await prefs.remove(_keyFullName);
      await prefs.remove(_keyRole);
      await prefs.remove(_keyCompanyId);
      await prefs.remove(_keyAvatarUrl);
    } catch (_) {
      // Bỏ qua.
    }
  }

  // JWT EXPIRY
  // Đọc trường "exp" (s, UTC) trong payload của JWT.

  bool _isTokenExpired(String jwt) {
    try {
      final parts = jwt.split('.');

      if (parts.length != 3) {
        return true;
      }

      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );

      final map = jsonDecode(payload);

      if (map is! Map<String, dynamic>) {
        return true;
      }

      final exp = map['exp'];

      // Token không có "exp" => coi như không hết hạn.
      if (exp is! num) {
        return false;
      }

      final nowSeconds = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
      //30s trừ hao lêch giờ
      return nowSeconds >= exp.toInt() - 30;
    } catch (_) {
      return true;
    }
  }
}
