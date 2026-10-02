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

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // SUBMIT

  Future<void> _handleSubmit() async {
    final current = _currentPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng điền đầy đủ các trường.';
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

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final result = await ApiService.put(
      '/api/users/me/password',
      {
        'currentPassword': current,
        'newPassword': newPass,
      },
      bearerToken: AuthState.instance.token,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 21,
              ),
              SizedBox(width: 10),
              Text('Đổi mật khẩu thành công.'),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      Navigator.pop(context);
    } else {
      setState(() {
        _errorMessage = result.errorMessage;
      });
    }
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 700;

            if (isMobile) {
              return _buildMobileLayout();
            }

            return _buildDesktopLayout();
          },
        ),
      ),
    );
  }

  // DESKTOP

  Widget _buildDesktopLayout() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 32,
          vertical: 40,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 650,
          ),
          child: Column(
            children: [
              _buildDesktopHeader(),

              const SizedBox(height: 28),

              _buildPasswordCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildHeaderIcon(),

        const SizedBox(width: 18),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Đổi mật khẩu',
                style: TextStyle(
                  color: Color(0xFF12348F),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Bảo mật tài khoản của bạn',
                style: TextStyle(
                  color: Color(0xFF7185A8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // MOBILE

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        16,
        10,
        16,
        28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMobileAppBar(),

          const SizedBox(height: 28),

          _buildMobileHeader(),

          const SizedBox(height: 24),

          _buildPasswordCard(),
        ],
      ),
    );
  }

  Widget _buildMobileAppBar() {
    return SizedBox(
      height: 46,
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFE2EAF7),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF31589D),
                  size: 22,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          const Text(
            'Đổi mật khẩu',
            style: TextStyle(
              color: Color(0xFF12348F),
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildHeaderIcon(
          size: 62,
          iconSize: 31,
        ),

        const SizedBox(width: 16),

        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Đổi mật khẩu',
                style: TextStyle(
                  color: Color(0xFF12348F),
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Bảo mật tài khoản của bạn',
                style: TextStyle(
                  color: Color(0xFF7185A8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // HEADER ICON

  Widget _buildHeaderIcon({
    double size = 78,
    double iconSize = 38,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFE7F0FF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Icon(
        Icons.lock_outline_rounded,
        color: AppColors.primaryBlue,
        size: iconSize,
      ),
    );
  }

  // PASSWORD CARD

  Widget _buildPasswordCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        28,
        28,
        28,
        30,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE2EAF7),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF31589D).withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          ),

          const SizedBox(height: 8),

          _buildPasswordHint(),

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
          ),

          const SizedBox(height: 18),

          if (_errorMessage != null) ...[
            _buildErrorMessage(),
            const SizedBox(height: 16),
          ],

          _buildSecurityHint(),

          const SizedBox(height: 22),

          _buildSubmitButton(),
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF294477),
          ),
        ),

        const SizedBox(height: 9),

        TextField(
          controller: controller,
          obscureText: obscure,
          textInputAction: TextInputAction.next,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF294477),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF8EA2C2),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),

            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: Color(0xFF5475AA),
              size: 21,
            ),

            suffixIcon: IconButton(
              tooltip: obscure
                  ? 'Hiện mật khẩu'
                  : 'Ẩn mật khẩu',
              onPressed: onToggle,
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF5475AA),
                size: 21,
              ),
            ),

            filled: true,
            fillColor: const Color(0xFFF8FAFF),

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFE2EAF7),
              ),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFE2EAF7),
              ),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF1464E8),
                width: 1.5,
              ),
            ),

            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // PASSWORD HINT

  Widget _buildPasswordHint() {
    final hasEnoughCharacters =
        _newPasswordController.text.length >= 8;

    return Row(
      children: [
        Icon(
          hasEnoughCharacters
              ? Icons.check_circle_outline_rounded
              : Icons.info_outline_rounded,
          size: 16,
          color: hasEnoughCharacters
              ? const Color(0xFF16A34A)
              : const Color(0xFF7185A8),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            hasEnoughCharacters
                ? 'Mật khẩu đạt yêu cầu tối thiểu 8 ký tự.'
                : 'Mật khẩu phải có ít nhất 8 ký tự.',
            style: TextStyle(
              fontSize: 12,
              color: hasEnoughCharacters
                  ? const Color(0xFF16A34A)
                  : const Color(0xFF7185A8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // SECURITY HINT

  Widget _buildSecurityHint() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.shield_outlined,
            color: Color(0xFF1464E8),
            size: 20,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              'Hãy sử dụng mật khẩu riêng và không chia sẻ '
              'mật khẩu với người khác.',
              style: const TextStyle(
                color: Color(0xFF31589D),
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ERROR

  Widget _buildErrorMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFD5D9),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFEF4444),
            size: 20,
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Color(0xFFD92D3A),
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // SUBMIT BUTTON

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isSubmitting
            ? null
            : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1464E8),
          disabledBackgroundColor: const Color(0xFF9BB8E8),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _isSubmitting
              ? const Row(
                  key: ValueKey('loading'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.3,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Đang cập nhật...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
              : const Row(
                  key: ValueKey('normal'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 20,
                    ),
                    SizedBox(width: 9),
                    Text(
                      'Đổi mật khẩu',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}