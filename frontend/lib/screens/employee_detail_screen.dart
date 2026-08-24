import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_state.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final String employeeId;

  const EmployeeDetailScreen({super.key, required this.employeeId});

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isResettingPassword = false;

  String? _errorMessage;

  Map<String, dynamic>? _employee;

  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadEmployee();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // LOAD EMPLOYEE
  Future<void> _loadEmployee() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService.get(
      '/api/employees/${widget.employeeId}',
      bearerToken: AuthState.instance.token,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;

      if (result.success) {
        _employee = result.data;

        _fullNameController.text = _employee!['fullName'] ?? '';

        _usernameController.text = _employee!['username'] ?? '';

        _emailController.text = _employee!['email'] ?? '';

        _phoneController.text = _employee!['phone'] ?? '';
      } else {
        _errorMessage = result.errorMessage;
      }
    });
  }

  // SAVE
  Future<void> _handleSave() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final result = await ApiService.put('/api/employees/${widget.employeeId}', {
      'fullName': _fullNameController.text.trim(),
      'username': _usernameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
    }, bearerToken: AuthState.instance.token);

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (result.success) {
      setState(() {
        _employee = result.data;
        _hasChanges = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 10),
              Text('Đã lưu thông tin nhân viên.'),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
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

  // RESET PASSWORD
  Future<void> _handleResetPassword() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'Cấp lại mật khẩu?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF202A3D),
          ),
        ),
        content: Text(
          'Hệ thống sẽ sinh mật khẩu mới và gửi qua email '
          '(${_employee?['email']}). '
          'Mật khẩu cũ sẽ không còn dùng được nữa.',
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Color(0xFF737D92),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Hủy',
              style: TextStyle(
                color: Color(0xFF737D92),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Cấp lại',
              style: TextStyle(
                color: Color(0xFF2864E8),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isResettingPassword = true;
    });

    final result = await ApiService.post(
      '/api/employees/${widget.employeeId}/reset-password',
      {},
      bearerToken: AuthState.instance.token,
    );

    if (!mounted) return;

    setState(() {
      _isResettingPassword = false;
    });

    if (result.success) {
      final emailSent = result.data!['emailSent'] == true;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                emailSent
                    ? Icons.mark_email_read_outlined
                    : Icons.warning_amber_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  emailSent
                      ? 'Đã cấp lại mật khẩu và gửi email thành công.'
                      : 'Đã cấp lại mật khẩu, nhưng gửi email thất bại — báo nhân viên liên hệ Admin.',
                ),
              ),
            ],
          ),
          backgroundColor: emailSent
              ? const Color(0xFF16A34A)
              : const Color(0xFF64748B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Cấp lại mật khẩu thất bại.'),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        Navigator.pop(context, _hasChanges);
      },

      child: Scaffold(
        backgroundColor: const Color(0xFFF0F3FF),

        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),

              Expanded(
                child: _isLoading
                    ? _buildLoading()
                    : _employee == null
                    ? _buildErrorState()
                    : _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // HEADER
  Widget _buildHeader() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.fromLTRB(16, 10, 18, 16),

      decoration: const BoxDecoration(
        color: Colors.white,

        border: Border(bottom: BorderSide(color: Color(0xFFE1E5F0), width: 1)),
      ),

      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(30),

            onTap: () {
              Navigator.pop(context, _hasChanges);
            },

            child: Container(
              width: 48,
              height: 48,

              decoration: const BoxDecoration(
                color: Color(0xFFEAF0FF),
                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.arrow_back,
                color: Color(0xFF244397),
                size: 28,
              ),
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Text(
              'Chi tiết nhân viên',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w500,
                color: Color(0xFF244397),
                letterSpacing: -0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // CONTENT
  Widget _buildContent() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          _buildEmployeeHeader(),

          const SizedBox(height: 18),

          _buildFormCard(),

          const SizedBox(height: 16),

          if (_errorMessage != null) _buildErrorMessage(),

          if (_errorMessage != null) const SizedBox(height: 12),

          _buildSaveButton(),

          const SizedBox(height: 12),

          _buildResetPasswordButton(),
        ],
      ),
    );
  }

  // EMPLOYEE HEADER
  Widget _buildEmployeeHeader() {
    final fullName = (_employee?['fullName'] ?? '').toString();

    final username = (_employee?['username'] ?? '').toString();

    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: const Color(0xFFDDE2EE)),

        boxShadow: [
          BoxShadow(
            color: const Color(0xFF53689E).withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,

            decoration: const BoxDecoration(
              color: Color(0xFFEAF0FF),
              shape: BoxShape.circle,
            ),

            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Color(0xFF244397),
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

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
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF202A3D),
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  '@$username',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF737D92),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // FORM CARD
  Widget _buildFormCard() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: const Color(0xFFDDE2EE)),

        boxShadow: [
          BoxShadow(
            color: const Color(0xFF53689E).withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            'Thông tin cá nhân',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF263A62),
            ),
          ),

          const SizedBox(height: 18),

          _buildTextField(
            controller: _fullNameController,
            label: 'Họ tên',
            icon: Icons.person_outline,
          ),

          const SizedBox(height: 16),

          _buildTextField(
            controller: _usernameController,
            label: 'Tên đăng nhập',
            icon: Icons.account_circle_outlined,
          ),

          const SizedBox(height: 7),

          const Padding(
            padding: EdgeInsets.only(left: 2),
            child: Text(
              'Đổi tên đăng nhập sẽ khiến nhân viên phải dùng tên mới ở lần đăng nhập tiếp theo.',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: Color(0xFF7A8498),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

          const SizedBox(height: 16),

          _buildTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 16),

          _buildTextField(
            controller: _phoneController,
            label: 'Số điện thoại',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  // TEXT FIELD
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF687389),
          ),
        ),

        const SizedBox(height: 8),

        TextField(
          controller: controller,
          keyboardType: keyboardType,

          style: const TextStyle(fontSize: 16, color: Color(0xFF202A3D)),

          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF7B8497), size: 21),

            filled: true,

            fillColor: const Color(0xFFF9FAFD),

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFFDDE2EE)),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFFDDE2EE)),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(
                color: Color(0xFF4C75D8),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ERROR
  Widget _buildErrorMessage() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: const Color(0xFFFFEEEE),

        borderRadius: BorderRadius.circular(14),

        border: Border.all(color: const Color(0xFFFFD2D2)),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Icon(Icons.error_outline, color: Color(0xFFE53935), size: 21),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Color(0xFFD32F2F),
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
      height: 58,

      child: ElevatedButton(
        onPressed: _isSaving ? null : _handleSave,

        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF244397),

          disabledBackgroundColor: const Color(0xFF8A9BC9),

          elevation: 0,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),

        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save_outlined, color: Colors.white, size: 22),

                  SizedBox(width: 9),

                  Text(
                    'Lưu thay đổi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // RESET PASSWORD BUTTON
  Widget _buildResetPasswordButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,

      child: OutlinedButton(
        onPressed: _isResettingPassword ? null : _handleResetPassword,

        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFEEF3FF),

          disabledBackgroundColor: const Color(0xFFF3F5FA),

          side: const BorderSide(color: Color(0xFF6B8FE8), width: 1.3),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),

          elevation: 0,
        ),

        child: _isResettingPassword
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Color(0xFF2864E8),
                    ),
                  ),

                  SizedBox(width: 10),

                  Text(
                    'Đang gửi...',
                    style: TextStyle(
                      color: Color(0xFF2864E8),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_reset_outlined,
                    color: Color(0xFF2864E8),
                    size: 23,
                  ),

                  SizedBox(width: 9),

                  Text(
                    'Cấp lại mật khẩu',
                    style: TextStyle(
                      color: Color(0xFF2864E8),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  SizedBox(width: 5),

                  Text(
                    '• Gửi qua email',
                    style: TextStyle(
                      color: Color(0xFF6880B8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // LOADING
  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF244397)),
    );
  }

  // ERROR STATE
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Container(
              width: 76,
              height: 76,

              decoration: BoxDecoration(
                color: const Color(0xFFFFEEEE),
                borderRadius: BorderRadius.circular(24),
              ),

              child: const Icon(
                Icons.error_outline,
                color: Color(0xFFE53935),
                size: 40,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Không thể tải thông tin',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF263A62),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _errorMessage ?? 'Không tải được thông tin nhân viên.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Color(0xFF737D92),
              ),
            ),

            const SizedBox(height: 20),

            OutlinedButton.icon(
              onPressed: _loadEmployee,

              icon: const Icon(Icons.refresh, color: Color(0xFF244397)),

              label: const Text(
                'Thử lại',
                style: TextStyle(
                  color: Color(0xFF244397),
                  fontWeight: FontWeight.w600,
                ),
              ),

              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF244397)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
