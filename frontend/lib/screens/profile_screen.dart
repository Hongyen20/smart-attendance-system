import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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


  // LIFECYCLE


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

    setState(() {
      _isLoading = false;

      if (result.success) {
        _profile = result.data;

        _emailController.text = (_profile?['email'] ?? '').toString();

        _phoneController.text = (_profile?['phone'] ?? '').toString();
      } else {
        _errorMessage = result.errorMessage;
      }
    });
  }

  // SAVE PROFILE
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

    setState(() {
      _isSaving = false;
    });

    if (result.success) {
      setState(() {
        _profile = result.data;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu thông tin cá nhân.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() {
        _errorMessage = result.errorMessage;
      });
    }
  }


  // PICK AVATAR
  Future<void> _handlePickAvatar() async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (picked == null) return;

    setState(() {
      _isUploadingAvatar = true;
    });

    final bytes = await picked.readAsBytes();

    final result = await ApiService.uploadBytes(
      '/api/users/me/avatar',
      'file',
      bytes,
      picked.name,
      bearerToken: AuthState.instance.token,
    );

    if (!mounted) return;

    setState(() {
      _isUploadingAvatar = false;
    });

    if (result.success) {
      final newAvatarUrl = result.data!['avatarUrl'] as String;

      setState(() {
        _profile = {...?_profile, 'avatarUrl': newAvatarUrl};
      });

      AuthState.instance.avatarUrl = newAvatarUrl;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật ảnh đại diện.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Tải ảnh lên thất bại.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
      backgroundColor: const Color(0xFFF1F4FF),

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF244397)),
            )
          : _profile == null
          ? _buildErrorState()
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [_buildHeader(), _buildProfileContent()],
                      ),
                    ),
                  ),
                ],
              ),
            ),

      bottomNavigationBar: _buildBottomNav(),
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
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFE53935)),

            const SizedBox(height: 16),

            Text(
              _errorMessage ?? 'Không tải được thông tin.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF263A62), fontSize: 15),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _loadProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF244397),
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


  // HEADER
  Widget _buildHeader() {
    final fullName = (_profile?['fullName'] ?? '').toString();

    final username = (_profile?['username'] ?? '').toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5F7FF), Color(0xFFE8EDFF)],
        ),
      ),
      child: Column(
        children: [
          // Top title
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Hồ sơ cá nhân',
                  style: TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF244397),
                    letterSpacing: -0.5,
                  ),
                ),
              ),

              IconButton(
                onPressed: () {
                  // TODO:
                  // Có thể kết nối notification screen sau.
                },
                icon: const Icon(
                  Icons.notifications_none_outlined,
                  size: 30,
                  color: Color(0xFF244397),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Avatar
          _buildAvatarSection(),

          const SizedBox(height: 16),

          // Name
          Text(
            fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w700,
              color: Color(0xFF202A3D),
            ),
          ),

          const SizedBox(height: 5),

          // Username
          Text(
            '@$username',
            style: const TextStyle(fontSize: 17, color: Color(0xFF747D91)),
          ),
        ],
      ),
    );
  }


  // AVATAR
  Widget _buildAvatarSection() {
    final avatarPath = _profile?['avatarUrl'] as String?;

    final hasAvatar = avatarPath != null && avatarPath.isNotEmpty;

    final fullName = (_profile?['fullName'] ?? '').toString();

    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFE7ECFF),
            border: Border.all(color: const Color(0xFFC7D4FF), width: 1.5),
          ),
          child: ClipOval(
            child: hasAvatar
                ? Image.network(
                    '${ApiConfig.baseUrl}$avatarPath',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return _buildAvatarInitial(initial);
                    },
                  )
                : _buildAvatarInitial(initial),
          ),
        ),

        // Camera button
        Positioned(
          right: -2,
          bottom: -2,
          child: GestureDetector(
            onTap: _isUploadingAvatar ? null : _handlePickAvatar,
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: const Color(0xFF244397),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: _isUploadingAvatar
                  ? const Padding(
                      padding: EdgeInsets.all(11),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: 21,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarInitial(String initial) {
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 46,
          fontWeight: FontWeight.w500,
          color: Color(0xFF244397),
        ),
      ),
    );
  }

  // PROFILE CONTENT
  Widget _buildProfileContent() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF385AAB).withValues(alpha: 0.08),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ACCOUNT INFORMATION
          _buildSectionTitle(
            icon: Icons.person_outline,
            title: 'Thông tin tài khoản',
          ),

          const SizedBox(height: 14),

          _buildReadOnlyField(
            label: 'Họ tên',
            value: (_profile?['fullName'] ?? '').toString(),
            icon: Icons.lock_outline,
            iconColor: const Color(0xFF2864E8),
          ),

          const SizedBox(height: 10),

          _buildReadOnlyField(
            label: 'Tên đăng nhập',
            value: (_profile?['username'] ?? '').toString(),
            icon: Icons.lock_outline,
            iconColor: const Color(0xFF2864E8),
          ),



          const SizedBox(height: 10),

          _buildInfoBox(),

          const SizedBox(height: 28),


          // CONTACT INFORMATION

          _buildSectionTitle(
            icon: Icons.mail_outline,
            title: 'Thông tin liên hệ',
          ),

          const SizedBox(height: 14),

          _buildEditableField(
            controller: _emailController,
            label: 'Email',
            hint: 'you@email.com',
          ),

          const SizedBox(height: 10),

          _buildEditableField(
            controller: _phoneController,
            label: 'Số điện thoại',
            hint: '0xxxxxxxxx',
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            _buildErrorBox(),
          ],

          const SizedBox(height: 20),


          // SAVE

          _buildSaveButton(),

          const SizedBox(height: 12),


          // CHANGE PASSWORD

          _buildChangePasswordButton(),

          const SizedBox(height: 12),


          // LOGOUT

          _buildLogoutButton(),
        ],
      ),
    );
  }


  // SECTION TITLE
  Widget _buildSectionTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, size: 26, color: const Color(0xFF2864E8)),

        const SizedBox(width: 10),

        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w600,
            color: Color(0xFF244397),
          ),
        ),
      ],
    );
  }

  // READ ONLY FIELD
  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    bool showEditIcon = false,
  }) {
    return Container(
      width: double.infinity,
      height: 68,
      padding: const EdgeInsets.only(left: 16, right: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE3F5), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF737D92),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const Spacer(),

                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF202A3D),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Container(
            width: 46,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF3FF),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor, size: 23),
          ),
        ],
      ),
    );
  }

  // INFO BOX
  Widget _buildInfoBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE3F5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF2864E8), size: 22),

          const SizedBox(width: 10),

          const Expanded(
            child: Text(
              'Họ tên và tên đăng nhập không thể tự đổi – liên hệ Admin/quản trị hệ thống nếu cần thay đổi.',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Color(0xFF68738A),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // EDITABLE FIELD
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
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF737D92),
          ),
        ),

        const SizedBox(height: 7),

        SizedBox(
          height: 68,
          child: TextField(
            controller: controller,
            style: const TextStyle(fontSize: 15, color: Color(0xFF202A3D)),
            decoration: InputDecoration(
              hintText: hint,

              hintStyle: const TextStyle(color: Color(0xFF9AA3B5)),

              filled: true,

              fillColor: const Color(0xFFFAFBFF),

              suffixIcon: Container(
                margin: const EdgeInsets.all(8),
                width: 46,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF3FF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  color: Color(0xFF2864E8),
                  size: 23,
                ),
              ),

              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFDCE3F5)),
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFDCE3F5)),
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF2864E8),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ERROR BOX
  Widget _buildErrorBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFFFCACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFE53935), size: 21),

          const SizedBox(width: 9),

          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Color(0xFFE53935),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // SAVE BUTTON
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _handleSaveProfile,

        icon: _isSaving
            ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.3,
                ),
              )
            : const Icon(Icons.save_outlined, color: Colors.white, size: 23),

        label: Text(
          _isSaving ? 'Đang lưu...' : 'Lưu thay đổi',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),

        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF244397),
          disabledBackgroundColor: const Color(
            0xFF244397,
          ).withValues(alpha: 0.65),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
      ),
    );
  }

  // CHANGE PASSWORD BUTTON
  Widget _buildChangePasswordButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
          );
        },

        icon: const Icon(
          Icons.lock_outline,
          color: Color(0xFF2864E8),
          size: 23,
        ),

        label: const Text(
          'Đổi mật khẩu',
          style: TextStyle(
            color: Color(0xFF2864E8),
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),

        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          side: const BorderSide(color: Color(0xFF2864E8), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
      ),
    );
  }

  // LOGOUT BUTTON
  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: OutlinedButton.icon(
        onPressed: _handleLogout,

        icon: const Icon(Icons.logout, color: Color(0xFFE53935), size: 23),

        label: const Text(
          'Đăng xuất',
          style: TextStyle(
            color: Color(0xFFE53935),
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),

        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          side: const BorderSide(color: Color(0xFFE53935), width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
      ),
    );
  }

  // BOTTOM NAVIGATION
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: 4,

        backgroundColor: Colors.white,

        type: BottomNavigationBarType.fixed,

        elevation: 0,

        selectedItemColor: const Color(0xFF244397),

        unselectedItemColor: const Color(0xFF737D92),

        selectedFontSize: 13,

        unselectedFontSize: 13,

        showUnselectedLabels: true,

        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),

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

            case 4:
              break;
          }
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
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
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
