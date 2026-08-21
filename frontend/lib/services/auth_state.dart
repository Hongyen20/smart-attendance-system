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
  }

  void clear() {
    token = null;
    userId = null;
    username = null;
    fullName = null;
    role = null;
    companyId = null;
    avatarUrl = null;
  }
}