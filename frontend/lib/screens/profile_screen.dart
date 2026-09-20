import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/auth_state.dart';
import '../services/api_config.dart';

import 'change_password_screen.dart';
import 'login_screen.dart';
import 'employee_home_screen.dart';
import 'history_screen.dart';
import 'leave_request_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  String? _errorMessage;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // LOAD PROFILE

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService.get(
      '/api/users/me',
      bearerToken: AuthState.instance.token,
    );

    if (!mounted) return;

    if (result.success) {
      final data = result.data as Map<String, dynamic>;

      setState(() {
        _profile = data;

        _emailController.text = data['email'] ?? '';
        _phoneController.text = data['phone'] ?? '';

        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = result.errorMessage;
      });
    }
  }

  // SAVE PROFILE

  Future<void> _handleSaveProfile() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final result = await ApiService.put('/api/users/me/profile', {
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
    }, bearerToken: AuthState.instance.token);

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (result.success) {
      setState(() {
        _profile = result.data;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã lưu thay đổi thông tin cá nhân.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      setState(() {
        _errorMessage = result.errorMessage;
      });
    }
  }

  // CHANGE PASSWORD

  void _openChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
    );
  }

  // LOGOUT

  void _handleLogout() {
    AuthState.instance.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primaryBlue),
              )
            : _profile == null
            ? _buildErrorState()
            : RefreshIndicator(
                color: AppColors.primaryBlue,
                onRefresh: _loadProfile,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),

                      const SizedBox(height: 22),

                      _buildProfileCard(),

                      const SizedBox(height: 26),

                      _buildSectionTitle('Tài khoản'),

                      const SizedBox(height: 12),

                      _buildAccountActions(),

                      const SizedBox(height: 24),

                      _buildLogoutButton(),
                    ],
                  ),
                ),
              ),
      ),

      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // HEADER

  Widget _buildHeader() {
    final fullName = _profile?['fullName'] ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildLogoHeader(),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hồ sơ cá nhân',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                'Xin chào, $fullName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // LOGO

  Widget _buildLogoHeader() {
    return SizedBox(
      width: 150,
      height: 60,
      child: Image.asset(
        'assets/images/logo.png',
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
      ),
    );
  }

  // PROFILE CARD

  Widget _buildProfileCard() {
    final fullName = _profile?['fullName'] ?? '';
    final username = _profile?['username'] ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          // AVATAR + NAME
          Row(
            children: [
              _buildAvatar(),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      '@$username',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // READ ONLY INFORMATION
          _buildReadOnlyRow(
            icon: Icons.person_outline,
            label: 'Họ tên',
            value: fullName,
          ),

          const SizedBox(height: 9),

          _buildReadOnlyRow(
            icon: Icons.badge_outlined,
            label: 'Tên đăng nhập',
            value: username,
          ),

          const SizedBox(height: 9),

          // INFORMATION NOTICE
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.infoBoxBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 20,
                  color: AppColors.primaryBlue,
                ),

                const SizedBox(width: 9),

                Expanded(
                  child: Text(
                    'Họ tên, tên đăng nhập và mã nhân viên không thể tự thay đổi. '
                    'Liên hệ Admin nếu cần cập nhật.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // EMAIL
          _buildEditableField(
            controller: _emailController,
            icon: Icons.email_outlined,
            label: 'Email',
            hint: 'you@email.com',
          ),

          const SizedBox(height: 12),

          // PHONE
          _buildEditableField(
            controller: _phoneController,
            icon: Icons.phone_outlined,
            label: 'Số điện thoại',
            hint: '09xxxxxxxx',
          ),

          // ERROR
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.dangerRedBg,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 20,
                    color: AppColors.dangerRed,
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: AppColors.dangerRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),

          // SAVE BUTTON
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _handleSaveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                disabledBackgroundColor: AppColors.primaryBlue.withOpacity(
                  0.55,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 21,
                      height: 21,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.4,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.save_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Lưu thay đổi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // AVATAR

  Widget _buildAvatar() {
    final avatarPath = _profile?['avatarUrl'] as String?;

    final hasAvatar = avatarPath != null && avatarPath.isNotEmpty;

    final fullName = (_profile?['fullName'] as String?) ?? '';

    final firstLetter = fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';

    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.infoBoxBackground,
        border: Border.all(color: AppColors.borderColor, width: 2),
      ),
      child: ClipOval(
        child: hasAvatar
            ? Image.network(
                '${ApiConfig.baseUrl}$avatarPath',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return _buildAvatarLetter(firstLetter);
                },
              )
            : _buildAvatarLetter(firstLetter),
      ),
    );
  }

  Widget _buildAvatarLetter(String letter) {
    return Center(
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryBlue,
        ),
      ),
    );
  }

  // READ ONLY ROW

  Widget _buildReadOnlyRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.infoBoxBackground,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: AppColors.primaryBlue, size: 19),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  value.isEmpty ? 'Chưa cập nhật' : value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.lock_outline,
            size: 16,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  // EDITABLE FIELD

  Widget _buildEditableField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),

        const SizedBox(height: 6),

        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFB0B3BD), fontSize: 14),

            prefixIcon: Icon(icon, color: AppColors.primaryBlue, size: 20),

            filled: true,
            fillColor: AppColors.cardBackground,

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.primaryBlue,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // SECTION TITLE

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }

  // ACCOUNT ACTIONS

  Widget _buildAccountActions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _openChangePassword,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.infoBoxBackground,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: AppColors.primaryBlue,
                  size: 23,
                ),
              ),

              const SizedBox(width: 13),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đổi mật khẩu',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Thay đổi mật khẩu đăng nhập',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  // LOGOUT

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _handleLogout,
        icon: const Icon(Icons.logout, color: AppColors.dangerRed, size: 20),
        label: const Text(
          'Đăng xuất',
          style: TextStyle(
            color: AppColors.dangerRed,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.dangerRed),
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  // ERROR STATE

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.dangerRedBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: AppColors.dangerRed,
                size: 34,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              _errorMessage ?? 'Không tải được thông tin cá nhân.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 18),

            ElevatedButton(
              onPressed: _loadProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                elevation: 0,
              ),
              child: const Text(
                'Thử lại',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // BOTTOM NAVIGATION

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 3,

      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const EmployeeHomeScreen()),
            );
            break;

          case 1:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            );
            break;

          case 2:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LeaveRequestScreen()),
            );
            break;

          case 3:
            // Đang ở Profile.
            break;
        }
      },

      type: BottomNavigationBarType.fixed,

      backgroundColor: AppColors.cardBackground,

      selectedItemColor: AppColors.primaryBlue,

      unselectedItemColor: AppColors.textSecondary,

      selectedFontSize: 12,

      unselectedFontSize: 12,

      showUnselectedLabels: true,

      elevation: 8,

      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Trang chủ',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.history_outlined),
          activeIcon: Icon(Icons.history),
          label: 'Lịch sử',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.description_outlined),
          activeIcon: Icon(Icons.description),
          label: 'Yêu cầu',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Cá nhân',
        ),
      ],
    );
  }
}
