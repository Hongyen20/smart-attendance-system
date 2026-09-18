import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/auth_state.dart';
import 'employee_home_screen.dart';
import 'create_company_screen.dart';
import 'admin_home_screen.dart';
import 'forgot_password_screen.dart';
import 'super_admin_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên đăng nhập')),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng nhập mật khẩu.')));
      return;
    }
    setState(() => _isLoading = true);

    final result = await ApiService.post('/api/auth/login', {
      'username': username,
      'password': password,
    });

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'Đăng nhập thất bại.')),
      );
      return;
    }

    final data = result.data!;

    AuthState.instance.setSession(
      token: data['token'] as String,
      userId: data['userId'] as String,
      username: data['username'] as String,
      fullName: data['fullName'] as String,
      role: data['role'] as String,
      companyId: data['companyId'] as String?,
      avatarUrl: data['avatarUrl'] as String?,
    );

    _navigateByRole(data['role'] as String);
  }

  void _navigateByRole(String role) {
    switch (role) {
      case 'SuperAdmin':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SuperAdminHomeScreen()),
        );
        break;

      case 'Admin':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
        );
        break;

      case 'Employee':
      default:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const EmployeeHomeScreen()),
        );
        break;
    }
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF4F7FF), Color(0xFFEAF0FF)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative background
              _buildBackgroundDecoration(),

              // Main content
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 850),
                    child: Column(
                      children: [
                        const SizedBox(height: 5),

                        _buildLogoHeader(),

                        const SizedBox(height: 15),

                        _buildLoginCard(),

                        const SizedBox(height: 28),

                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // BACKGROUND

  Widget _buildBackgroundDecoration() {
    return IgnorePointer(
      child: Stack(
        children: [
          // Top-left decoration
          Positioned(
            top: -90,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: const Color(0xFFDDE7FF).withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(140),
              ),
            ),
          ),

          // Bottom-right decoration
          Positioned(
            bottom: -100,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: const Color(0xFFD9E5FF).withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(150),
              ),
            ),
          ),

          // Top-right dots
          Positioned(top: 45, right: 35, child: _buildDotPattern()),

          // Bottom-left dots
          Positioned(bottom: 70, left: 30, child: _buildDotPattern()),
        ],
      ),
    );
  }

  Widget _buildDotPattern() {
    return SizedBox(
      width: 100,
      height: 80,
      child: Wrap(
        spacing: 18,
        runSpacing: 15,
        children: List.generate(
          20,
          (index) => Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFBFD0FA),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }

  // LOGO HEADER
  Widget _buildLogoHeader() {
  return Column(
    children: [
      Image.asset(
        'assets/images/logo.png',
        width: 300,
        fit: BoxFit.contain,
      ),
    ],
  );
}
  // LOGIN CARD

  Widget _buildLoginCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(40, 34, 40, 34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4967A8).withValues(alpha: 0.10),
            blurRadius: 35,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Username
          _buildFieldLabel('Tên đăng nhập', Icons.person_outline),

          const SizedBox(height: 10),

          TextField(
            controller: _usernameController,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(
              hint: 'Nhập tên đăng nhập',
              icon: Icons.person_outline,
            ),
          ),

          const SizedBox(height: 26),

          // Password
          _buildFieldLabel('Mật khẩu', Icons.lock_outline),

          const SizedBox(height: 10),

          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleLogin(),
            decoration: _inputDecoration(
              hint: 'Nhập mật khẩu',
              icon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: const Color(0xFF68738A),
                  size: 25,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Remember + Forgot password
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                  side: const BorderSide(color: Color(0xFFB8C0D0), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  activeColor: const Color(0xFF2864E8),
                ),
              ),

              const SizedBox(width: 10),

              const Text(
                'Ghi nhớ đăng nhập',
                style: TextStyle(color: Color(0xFF30394D), fontSize: 15),
              ),

              const Spacer(),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Quên mật khẩu?',
                  style: TextStyle(
                    color: AppColors.accentBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Login button
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF244397),
                disabledBackgroundColor: const Color(
                  0xFF244397,
                ).withValues(alpha: 0.6),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Đăng Nhập',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 12),
                        Icon(Icons.login, color: Colors.white, size: 23),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // FIELD LABEL

  Widget _buildFieldLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 21, color: const Color(0xFF244397)),

        const SizedBox(width: 10),

        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF263A62),
          ),
        ),
      ],
    );
  }

  // INPUT DECORATION
  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,

      hintStyle: const TextStyle(color: Color(0xFF9AA3B5), fontSize: 16),

      prefixIcon: Container(
        margin: const EdgeInsets.all(9),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF0FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF2864E8), size: 23),
      ),

      suffixIcon: suffixIcon,

      filled: true,

      fillColor: const Color(0xFFF8FAFF),

      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: Color(0xFFD3DEFA), width: 1.2),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: Color(0xFFD3DEFA), width: 1.2),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: Color(0xFF2864E8), width: 1.6),
      ),
    );
  }

  // FOOTER

  Widget _buildFooter() {
    return const Text(
      '© 2024 AttendGo. Tất cả quyền được bảo lưu.',
      textAlign: TextAlign.center,
      style: TextStyle(color: Color(0xFF68738A), fontSize: 13),
    );
  }
}
