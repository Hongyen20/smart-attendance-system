import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;
  bool _isSuccess = false;

  // =========================
  // MÀU RIÊNG CHO MÀN HÌNH
  // =========================

  static const Color _backgroundColor = Color(0xFFF3F5FF);
  static const Color _cardColor = Colors.white;

  static const Color _primaryColor = Color(0xFF29479A);
  static const Color _primaryLightColor = Color(0xFFE9EEFF);

  static const Color _borderColor = Color(0xFFDCE1EC);
  static const Color _focusColor = Color(0xFF3D6FEF);

  static const Color _textColor = Color(0xFF252B3A);
  static const Color _secondaryTextColor = Color(0xFF6B7280);
  static const Color _hintColor = Color(0xFFB1B6C4);

  static const Color _errorBackground = Color(0xFFFFF1F1);
  static const Color _errorColor = Color(0xFFD64545);

  static const Color _successBackground = Color(0xFFECF9F1);
  static const Color _successColor = Color(0xFF239653);

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleForgotPassword() async {
    FocusScope.of(context).unfocus();

    final username = _usernameController.text.trim();
    final phone = _phoneController.text.trim();

    if (username.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập tên đăng nhập.';
        _isSuccess = false;
      });
      return;
    }

    if (phone.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập số điện thoại.';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _isSuccess = false;
    });

    try {
      final result = await ApiService.post('/api/auth/forgot-password', {
        'username': username,
        'phone': phone,
      });

      if (!mounted) return;

      if (result.success) {
        setState(() {
          _isSubmitting = false;
          _isSuccess = true;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _isSubmitting = false;
          _isSuccess = false;
          _errorMessage =
              result.errorMessage ?? 'Thông tin xác minh không chính xác.';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
        _isSuccess = false;
        _errorMessage = 'Không thể kết nối đến hệ thống. Vui lòng thử lại sau.';
      });
    }
  }

  void _backToLogin() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,

      // =========================
      // APP BAR
      // =========================
      appBar: AppBar(
        backgroundColor: _cardColor,
        foregroundColor: _primaryColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,

        leading: IconButton(
          onPressed: _backToLogin,
          icon: const Icon(Icons.arrow_back_rounded, size: 28),
          color: _primaryColor,
        ),

        title: const Text(
          'Quên mật khẩu',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: _primaryColor,
          ),
        ),
      ),

      // =========================
      // BODY
      // =========================
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,

          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormCard(),

              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                _buildErrorBox(_errorMessage!),
              ],

              if (_isSuccess) ...[
                const SizedBox(height: 14),
                _buildSuccessBox(),
              ],

              const SizedBox(height: 18),

              _buildSubmitButton(),

              const SizedBox(height: 12),

              Center(
                child: TextButton(
                  onPressed: _backToLogin,
                  style: TextButton.styleFrom(
                    foregroundColor: _primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  child: const Text(
                    'Quay lại đăng nhập',
                    style: TextStyle(
                      color: _primaryColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
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

  // ============================================================
  // FORM CARD
  // ============================================================

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),

      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: _usernameController,
            label: 'Tên đăng nhập',
            hint: 'Nhập tên đăng nhập của bạn',
            icon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
          ),

          const SizedBox(height: 20),

          _buildTextField(
            controller: _phoneController,
            label: 'Số điện thoại',
            hint: 'Nhập số điện thoại đã đăng ký',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleForgotPassword(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    Function(String)? onSubmitted,
  }) {
    final isUsername = label == 'Tên đăng nhập';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LABEL
        RichText(
          text: const TextSpan(text: '', children: []),
        ),

        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _textColor,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              '*',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFFE05252),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // INPUT
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,

          style: const TextStyle(
            fontSize: 15,
            color: _textColor,
            fontWeight: FontWeight.w500,
          ),

          decoration: InputDecoration(
            hintText: hint,

            hintStyle: const TextStyle(
              color: _hintColor,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),

            prefixIcon: Icon(icon, color: _primaryColor, size: 22),

            prefixIconConstraints: const BoxConstraints(minWidth: 52),

            filled: true,
            fillColor: Colors.white,

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 15,
            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _borderColor, width: 1),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _borderColor, width: 1),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _focusColor, width: 1.5),
            ),

            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _errorColor, width: 1.2),
            ),

            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _errorColor, width: 1.5),
            ),
          ),
        ),

        const SizedBox(height: 7),

        // HELPER TEXT
        Text(
          isUsername
              ? 'Nhập chính xác tên đăng nhập của nhân viên.'
              : 'Số điện thoại phải trùng với thông tin đã đăng ký.',
          style: const TextStyle(
            fontSize: 11.5,
            color: _secondaryTextColor,
            fontStyle: FontStyle.italic,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SUBMIT BUTTON
  // ============================================================

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,

      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _handleForgotPassword,

        icon: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.2,
                ),
              )
            : const Icon(Icons.send_rounded, color: Colors.white, size: 21),

        label: Text(
          _isSubmitting ? 'Đang xác minh...' : 'Xác nhận quên mật khẩu',

          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),

        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,

          disabledBackgroundColor: _primaryColor.withOpacity(0.55),

          elevation: 0,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ERROR BOX
  // ============================================================

  Widget _buildErrorBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: _errorBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF5CACA)),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: _errorColor, size: 21),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: _errorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUCCESS BOX
  // ============================================================

  Widget _buildSuccessBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: _successBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC8EBD6)),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: _successColor,
            size: 22,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Xác minh thành công',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _successColor,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'Hướng dẫn đặt lại mật khẩu đã được gửi '
                  'đến email của nhân viên. Vui lòng kiểm tra '
                  'hộp thư để tiếp tục.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: _secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
