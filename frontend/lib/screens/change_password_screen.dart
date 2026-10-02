import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/auth_state.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool _isSubmitting = false;

  String? _errorMessage;

  // DISPOSE

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  // CHANGE PASSWORD

  Future<void> _handleSubmit() async {
    final current = _currentPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng điền đầy đủ thông tin.';
      });
      return;
    }

    if (newPass.length < 8) {
      setState(() {
        _errorMessage = 'Mật khẩu mới phải có ít nhất 8 ký tự.';
      });
      return;
    }

    if (newPass != confirm) {
      setState(() {
        _errorMessage = 'Mật khẩu xác nhận không khớp.';
      });
      return;
    }

    if (current == newPass) {
      setState(() {
        _errorMessage = 'Mật khẩu mới phải khác mật khẩu hiện tại.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final result = await ApiService.put('/api/users/me/password', {
      'currentPassword': current,
      'newPassword': newPass,
    }, bearerToken: AuthState.instance.token);

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (result.success) {
      _showSuccessMessage();

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        Navigator.pop(context);
      });
    } else {
      setState(() {
        _errorMessage = result.errorMessage;
      });
    }
  }

  // SUCCESS MESSAGE

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF16A34A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Đổi mật khẩu thành công.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 900) {
              return _buildDesktopLayout();
            }

            return _buildMobileLayout();
          },
        ),
      ),
    );
  }

  // DESKTOP LAYOUT

  Widget _buildDesktopLayout() {
    return Column(
      children: [
        _buildDesktopHeader(),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 34),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: _buildPasswordCard(isDesktop: true),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // DESKTOP HEADER

  Widget _buildDesktopHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2EAF7), width: 1)),
      ),
      child: Row(
        children: [
          _buildBackButton(),

          const SizedBox(width: 18),

          const Expanded(
            child: Text(
              'Đổi mật khẩu',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w700,
                color: Color(0xFF244397),
                letterSpacing: -0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // MOBILE LAYOUT

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildMobileHeader(),

        Expanded(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            child: _buildPasswordCard(isDesktop: false),
          ),
        ),
      ],
    );
  }

  // MOBILE HEADER

  Widget _buildMobileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 18, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2EAF7), width: 1)),
      ),
      child: Row(
        children: [
          _buildBackButton(),

          const SizedBox(width: 14),

          const Expanded(
            child: Text(
              'Đổi mật khẩu',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: Color(0xFF244397),
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // BACK BUTTON

  Widget _buildBackButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: () {
        Navigator.pop(context);
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: Color(0xFFEAF0FF),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: Color(0xFF244397),
          size: 25,
        ),
      ),
    );
  }

  // PASSWORD CARD

  Widget _buildPasswordCard({required bool isDesktop}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 28 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isDesktop ? 20 : 18),
        border: Border.all(color: const Color(0xFFE0E7F3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF31589D).withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCardHeader(isDesktop: isDesktop),

          SizedBox(height: isDesktop ? 26 : 22),

          const Divider(height: 1, color: Color(0xFFE7ECF5)),

          SizedBox(height: isDesktop ? 26 : 22),

          _buildPasswordField(
            controller: _currentPasswordController,
            label: 'Mật khẩu hiện tại',
            hint: 'Nhập mật khẩu hiện tại',
            obscure: _obscureCurrent,
            onToggle: () {
              setState(() {
                _obscureCurrent = !_obscureCurrent;
              });
            },
            isDesktop: isDesktop,
          ),

          const SizedBox(height: 20),

          _buildPasswordField(
            controller: _newPasswordController,
            label: 'Mật khẩu mới',
            hint: 'Nhập mật khẩu mới',
            obscure: _obscureNew,
            onToggle: () {
              setState(() {
                _obscureNew = !_obscureNew;
              });
            },
            isDesktop: isDesktop,
          ),

          const SizedBox(height: 20),

          _buildPasswordField(
            controller: _confirmPasswordController,
            label: 'Xác nhận mật khẩu mới',
            hint: 'Nhập lại mật khẩu mới',
            obscure: _obscureConfirm,
            onToggle: () {
              setState(() {
                _obscureConfirm = !_obscureConfirm;
              });
            },
            isDesktop: isDesktop,
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 18),
            _buildErrorBox(_errorMessage!),
          ],

          const SizedBox(height: 24),

          _buildSubmitButton(isDesktop: isDesktop),

          const SizedBox(height: 14),

          _buildSecurityNote(isDesktop: isDesktop),
        ],
      ),
    );
  }

  // CARD HEADER

  Widget _buildCardHeader({required bool isDesktop}) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 18 : 15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFF0F6FF), Color(0xFFE7F0FF)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: isDesktop ? 58 : 50,
            height: isDesktop ? 58 : 50,
            decoration: const BoxDecoration(
              color: Color(0xFFD9E7FF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_reset_rounded,
              color: AppColors.primaryBlue,
              size: isDesktop ? 29 : 25,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đổi mật khẩu',
                  style: TextStyle(
                    fontSize: isDesktop ? 20 : 17,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF244397),
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'Cập nhật mật khẩu để bảo vệ tài khoản của bạn.',
                  style: TextStyle(
                    fontSize: isDesktop ? 13 : 12,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // PASSWORD FIELD

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    required bool isDesktop,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isDesktop ? 14 : 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF263A62),
          ),
        ),

        const SizedBox(height: 8),

        TextField(
          controller: controller,
          obscureText: obscure,
          textInputAction: TextInputAction.next,
          style: TextStyle(
            fontSize: isDesktop ? 15 : 14,
            color: const Color(0xFF202A3D),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            prefixIcon: Padding(
              padding: const EdgeInsets.all(8),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: Color(0xFF2864E8),
                  size: 20,
                ),
              ),
            ),

            suffixIcon: IconButton(
              tooltip: obscure ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
              onPressed: onToggle,
              icon: Icon(
                obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textSecondary,
                size: 21,
              ),
            ),

            hintText: hint,

            hintStyle: TextStyle(
              color: const Color(0xFF9AA8BE),
              fontSize: isDesktop ? 15 : 14,
              fontWeight: FontWeight.w400,
            ),

            filled: true,
            fillColor: const Color(0xFFFAFCFF),

            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: isDesktop ? 17 : 15,
            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFDDE6F5)),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFDDE6F5)),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF2864E8),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ERROR BOX

  Widget _buildErrorBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.dangerRedBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFFFD4D4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFFFFDDDD),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppColors.dangerRed,
              size: 19,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.dangerRed,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // SUBMIT BUTTON

  Widget _buildSubmitButton({required bool isDesktop}) {
    return SizedBox(
      width: double.infinity,
      height: isDesktop ? 56 : 54,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          disabledBackgroundColor: const Color(0xFF8EA8DE),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.4,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock_reset_rounded,
                    color: Colors.white,
                    size: 22,
                  ),

                  const SizedBox(width: 10),

                  Text(
                    'Đổi mật khẩu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isDesktop ? 15 : 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // SECURITY NOTE

  Widget _buildSecurityNote({required bool isDesktop}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF6E86AF),
            size: 19,
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Text(
              'Mật khẩu mới nên có ít nhất 8 ký tự và không nên trùng với mật khẩu hiện tại.',
              style: TextStyle(
                fontSize: isDesktop ? 12 : 11.5,
                height: 1.45,
                color: const Color(0xFF71809A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
