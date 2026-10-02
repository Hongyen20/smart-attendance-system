import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_state.dart';

class CreateEmployeeScreen extends StatefulWidget {
  const CreateEmployeeScreen({super.key});

  @override
  State<CreateEmployeeScreen> createState() => _CreateEmployeeScreenState();
}

class _CreateEmployeeScreenState extends State<CreateEmployeeScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isSubmitting = false;

  String? _errorMessage;
  Map<String, dynamic>? _result;

  // COLORS

  static const Color _primary = Color(0xFF2864E8);
  static const Color _navy = Color(0xFF244397);
  static const Color _textPrimary = Color(0xFF263A62);
  static const Color _textSecondary = Color(0xFF7185A8);
  static const Color _background = Color(0xFFF5F9FF);
  static const Color _softBlue = Color(0xFFEAF0FF);
  static const Color _border = Color(0xFFDDE6F5);
  static const Color _inputBackground = Color(0xFFFAFCFF);

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // CREATE EMPLOYEE

  Future<void> _handleSubmit() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    if (fullName.isEmpty || email.isEmpty || phone.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng điền đầy đủ thông tin.';
        _result = null;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _result = null;
    });

    final result = await ApiService.post('/api/employees', {
      'fullName': fullName,
      'email': email,
      'phone': phone,
    }, bearerToken: AuthState.instance.token);

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;

      if (result.success) {
        _result = result.data;

        _fullNameController.clear();
        _emailController.clear();
        _phoneController.clear();
      } else {
        _errorMessage = result.errorMessage;
      }
    });
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 700;

                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 32,
                      vertical: isMobile ? 20 : 34,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1300),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildMainCard(isMobile: isMobile),

                            const SizedBox(height: 18),

                            _buildNoticeCard(isMobile: isMobile),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // HEADER

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2EAF7), width: 1)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          return Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: _softBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: _navy,
                    size: 25,
                  ),
                ),
              ),

              SizedBox(width: isMobile ? 12 : 18),

              Expanded(
                child: Text(
                  'Tạo tài khoản nhân viên',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isMobile ? 21 : 27,
                    fontWeight: FontWeight.w700,
                    color: _navy,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // MAIN CARD

  Widget _buildMainCard({required bool isMobile}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 18 : 20),
        border: Border.all(color: _border),
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
          _buildInformationBanner(isMobile: isMobile),

          SizedBox(height: isMobile ? 22 : 30),

          _buildFormContent(isMobile: isMobile),

          if (_errorMessage != null) ...[
            const SizedBox(height: 18),
            _buildErrorBox(_errorMessage!),
          ],

          if (_result != null) ...[
            const SizedBox(height: 18),
            _buildResultBox(_result!),
          ],

          const SizedBox(height: 24),

          _buildCreateButton(isMobile: isMobile),
        ],
      ),
    );
  }

  // INFORMATION BANNER

  Widget _buildInformationBanner({required bool isMobile}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFF0F6FF), Color(0xFFE5F0FF)],
        ),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Container(
            width: isMobile ? 50 : 58,
            height: isMobile ? 50 : 58,
            decoration: const BoxDecoration(
              color: Color(0xFFD7E6FF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_add_alt_1_outlined,
              color: _primary,
              size: isMobile ? 25 : 29,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thông tin nhân viên',
                  style: TextStyle(
                    fontSize: isMobile ? 17 : 20,
                    fontWeight: FontWeight.w700,
                    color: _navy,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'Nhập thông tin cơ bản để tạo tài khoản cho nhân viên.',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 13,
                    height: 1.45,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),

          if (!isMobile) ...[
            const SizedBox(width: 20),

            Container(
              width: 110,
              height: 75,
              decoration: BoxDecoration(
                color: const Color(0xFFDCEAFF).withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Center(
                child: Icon(
                  Icons.groups_2_outlined,
                  color: Color(0xFF4C7FE8),
                  size: 45,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // FORM

  Widget _buildFormContent({required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(
          controller: _fullNameController,
          label: 'Họ tên',
          hint: 'Nhập họ tên nhân viên',
          icon: Icons.person_outline_rounded,
          helperText: 'Họ tên sẽ hiển thị trong hệ thống.',
          keyboardType: TextInputType.name,
          isMobile: isMobile,
        ),

        const SizedBox(height: 21),

        _buildTextField(
          controller: _emailController,
          label: 'Email',
          hint: 'Nhập email nhân viên',
          icon: Icons.mail_outline_rounded,
          helperText: 'Email dùng để gửi mật khẩu và thông báo.',
          keyboardType: TextInputType.emailAddress,
          isMobile: isMobile,
        ),

        const SizedBox(height: 21),

        _buildTextField(
          controller: _phoneController,
          label: 'Số điện thoại',
          hint: 'Nhập số điện thoại',
          icon: Icons.phone_outlined,
          helperText: 'Số điện thoại dùng để liên hệ khi cần thiết.',
          keyboardType: TextInputType.phone,
          isMobile: isMobile,
        ),
      ],
    );
  }

  // TEXT FIELD

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String helperText,
    required TextInputType keyboardType,
    required bool isMobile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: label,
                style: TextStyle(
                  fontSize: isMobile ? 13 : 14,
                  fontWeight: FontWeight.w700,
                  color: _navy,
                ),
              ),
              const TextSpan(
                text: ' *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE53935),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: TextInputAction.next,
          style: TextStyle(
            fontSize: isMobile ? 14 : 15,
            color: const Color(0xFF202A3D),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            prefixIcon: Padding(
              padding: const EdgeInsets.all(7),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _softBlue,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: _primary, size: 21),
              ),
            ),

            hintText: hint,

            hintStyle: TextStyle(
              color: const Color(0xFF9AA9C2),
              fontSize: isMobile ? 14 : 15,
              fontWeight: FontWeight.w400,
            ),

            filled: true,
            fillColor: _inputBackground,

            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: isMobile ? 15 : 17,
            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _border),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _border),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _primary, width: 1.5),
            ),
          ),
        ),

        const SizedBox(height: 7),

        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Text(
            helperText,
            style: TextStyle(
              fontSize: isMobile ? 11 : 12,
              height: 1.4,
              color: _textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  // CREATE BUTTON

  Widget _buildCreateButton({required bool isMobile}) {
    return SizedBox(
      width: double.infinity,
      height: isMobile ? 54 : 60,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          disabledBackgroundColor: const Color(0xFF8EA8DE),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _isSubmitting
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  key: const ValueKey('button'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.person_add_alt_1_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Tạo tài khoản',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 15 : 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // NOTICE CARD

  Widget _buildNoticeCard({required bool isMobile}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 22,
        vertical: isMobile ? 14 : 16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9E7FF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFD6E5FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: _primary,
              size: 21,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lưu ý',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _navy,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  'Sau khi tạo tài khoản thành công, thông tin đăng nhập sẽ được gửi qua email cho nhân viên.',
                  style: TextStyle(
                    fontSize: isMobile ? 11.5 : 12,
                    height: 1.45,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ERROR BOX

  Widget _buildErrorBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD5D5)),
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
              color: Color(0xFFE53935),
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
                  height: 1.45,
                  color: Color(0xFFD32F2F),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // RESULT BOX

  Widget _buildResultBox(Map<String, dynamic> result) {
    final emailSent = result['emailSent'] == true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: emailSent ? const Color(0xFFF0FDF4) : const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: emailSent ? const Color(0xFFBBE8C8) : const Color(0xFFF1D58A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: emailSent
                      ? const Color(0xFFDDF8E6)
                      : const Color(0xFFFFEDC4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  emailSent
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_rounded,
                  color: emailSent
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFB77900),
                  size: 22,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Text(
                  emailSent
                      ? 'Đã tạo tài khoản thành công'
                      : 'Đã tạo tài khoản',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                    color: emailSent
                        ? const Color(0xFF15803D)
                        : const Color(0xFF9A6700),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            emailSent
                ? 'Thông tin đăng nhập đã được gửi đến email của nhân viên.'
                : 'Tài khoản đã được tạo nhưng email chưa được gửi thành công.',
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: Color(0xFF687389),
            ),
          ),

          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _resultRow('Username', result['username']),

                const SizedBox(height: 9),

                _resultRow('Họ tên', result['fullName']),

                const SizedBox(height: 9),

                _resultRow('Email', result['email']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // RESULT ROW

  Widget _resultRow(String label, dynamic value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF7A8498)),
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: SelectableText(
            '$value',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
