import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/auth_state.dart';
import '../services/api_config.dart';
import 'change_password_screen.dart';
import 'login_screen.dart';
import 'employee_home_screen.dart';
import 'history_screen.dart';
import 'leave_request_screen.dart';
import 'statistics_screen.dart';

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
  bool _isUploadingAvatar = false;
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

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    final result = await ApiService.get(
      '/api/users/me',
      bearerToken: AuthState.instance.token,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result.success) {
        _profile = result.data;
        _emailController.text = _profile!['email'] ?? '';
        _phoneController.text = _profile!['phone'] ?? '';
      } else {
        _errorMessage = result.errorMessage;
      }
    });
  }

  Future<void> _handleSaveProfile() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final result = await ApiService.put('/api/users/me/profile', {
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
    }, bearerToken: AuthState.instance.token);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result.success) {
      setState(() => _profile = result.data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu thông tin cá nhân.')),
      );
    } else {
      setState(() => _errorMessage = result.errorMessage);
    }
  }

  Future<void> _handlePickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _isUploadingAvatar = true);

    final bytes = await picked.readAsBytes();
    final result = await ApiService.uploadBytes(
      '/api/users/me/avatar',
      'file',
      bytes,
      picked.name,
      bearerToken: AuthState.instance.token,
    );

    if (!mounted) return;
    setState(() => _isUploadingAvatar = false);

    if (result.success) {
      final newAvatarUrl = result.data!['avatarUrl'] as String;
      setState(() => _profile = {...?_profile, 'avatarUrl': newAvatarUrl});
      AuthState.instance.avatarUrl = newAvatarUrl;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật ảnh đại diện.')),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'Tải ảnh lên thất bại.')),
      );
    }
  }

  void _handleLogout() {
    AuthState.instance.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân'),
        backgroundColor: AppColors.cardBackground,
        foregroundColor: AppColors.primaryBlue,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
          ? Center(
              child: Text(
                _errorMessage ?? 'Không tải được thông tin.',
                style: const TextStyle(color: AppColors.dangerRed),
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: _buildAvatarSection()),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        _profile!['fullName'] ?? '',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        '@${_profile!['username'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildReadOnlyField('Họ tên', _profile!['fullName'] ?? ''),
                    const SizedBox(height: 12),
                    _buildReadOnlyField(
                      'Tên đăng nhập',
                      _profile!['username'] ?? '',
                    ),
                    const SizedBox(height: 12),
                    _buildReadOnlyField(
                      'Mã nhân viên',
                      _profile!['employeeCode'] ?? '',
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Họ tên và tên đăng nhập không thể tự đổi — liên hệ Admin/quản trị hệ thống nếu cần thay đổi.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildEditableField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'you@email.com',
                    ),
                    const SizedBox(height: 14),
                    _buildEditableField(
                      controller: _phoneController,
                      label: 'Số điện thoại',
                      hint: '09xxxxxxxx',
                    ),
                    const SizedBox(height: 16),
                    if (_errorMessage != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.dangerRedBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppColors.dangerRed,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _handleSaveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.4,
                                ),
                              )
                            : const Text(
                                'Lưu thay đổi',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ChangePasswordScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.lock_outline,
                          color: AppColors.accentBlue,
                        ),
                        label: const Text(
                          'Đổi mật khẩu',
                          style: TextStyle(color: AppColors.accentBlue),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.accentBlue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _handleLogout,
                        icon: const Icon(
                          Icons.logout,
                          color: AppColors.dangerRed,
                        ),
                        label: const Text(
                          'Đăng xuất',
                          style: TextStyle(color: AppColors.dangerRed),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.dangerRed),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 4,
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
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const StatisticsScreen()),
            );
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primaryBlue,
      unselectedItemColor: AppColors.textSecondary,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Trang chủ',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Lịch sử'),
        BottomNavigationBarItem(
          icon: Icon(Icons.event_busy_outlined),
          label: 'Nghỉ phép',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_outlined),
          label: 'Thống kê',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }

  Widget _buildAvatarSection() {
    final avatarPath = _profile?['avatarUrl'] as String?;
    final hasAvatar = avatarPath != null && avatarPath.isNotEmpty;

    return Stack(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: AppColors.infoBoxBackground,
          backgroundImage: hasAvatar
              ? NetworkImage('${ApiConfig.baseUrl}$avatarPath')
              : null,
          child: !hasAvatar
              ? Text(
                  (_profile!['fullName'] as String?)?.isNotEmpty == true
                      ? _profile!['fullName'][0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 32,
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: _isUploadingAvatar ? null : _handlePickAvatar,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.primaryBlue,
                shape: BoxShape.circle,
                border: Border.fromBorderSide(
                  BorderSide(color: Colors.white, width: 2),
                ),
              ),
              child: _isUploadingAvatar
                  ? const Padding(
                      padding: EdgeInsets.all(7),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.camera_alt, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ),
              const Icon(
                Icons.lock_outline,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
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
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFB0B3BD)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.accentBlue,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
