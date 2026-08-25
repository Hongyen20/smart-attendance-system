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

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // CREATE EMPLOYEE
  Future<void> _handleSubmit() async {
    if (_fullNameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
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
      'fullName': _fullNameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
    }, bearerToken: AuthState.instance.token);

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;

      if (result.success) {
        _result = result.data;

        // Clear form sau khi tạo thành công
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
      backgroundColor: const Color(0xFFF0F3FF),

      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),

                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormCard(),

                    const SizedBox(height: 16),

                    if (_errorMessage != null) _buildErrorBox(_errorMessage!),

                    if (_result != null) _buildResultBox(_result!),

                    const SizedBox(height: 2),

                    _buildCreateButton(),
                  ],
                ),
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
                Icons.arrow_back,
                color: Color(0xFF244397),
                size: 28,
              ),
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Text(
              'Tạo tài khoản nhân viên',
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
            color: const Color(0xFF53689E).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // FORM HEADER
          Row(
            children: [
              Container(
                width: 58,
                height: 58,

                decoration: const BoxDecoration(
                  color: Color(0xFFEAF0FF),
                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.person_add_alt_1_outlined,
                  color: Color(0xFF244397),
                  size: 29,
                ),
              ),

              const SizedBox(width: 14),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông tin nhân viên',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF263A62),
                      ),
                    ),

                    SizedBox(height: 4),

                    Text(
                      'Nhập thông tin cơ bản để tạo tài khoản cho nhân viên.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Color(0xFF737D92),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          const Divider(height: 1, color: Color(0xFFE7EAF2)),

          const SizedBox(height: 20),

          // FULL NAME
          _buildTextField(
            controller: _fullNameController,
            label: 'Họ tên',
            hint: 'Nhập họ tên nhân viên',
            icon: Icons.person_outline,
            helperText: 'Họ tên sẽ hiển thị trong hệ thống.',
          ),

          const SizedBox(height: 18),

          // EMAIL
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'Nhập email nhân viên',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            helperText: 'Email dùng để gửi mật khẩu và thông báo.',
          ),

          const SizedBox(height: 18),


          // PHONE
          _buildTextField(
            controller: _phoneController,
            label: 'Số điện thoại',
            hint: 'Nhập số điện thoại',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            helperText: 'Số điện thoại dùng để liên hệ khi cần thiết.',
          ),
        ],
      ),
    );
  }


  // TEXT FIELD


  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String helperText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        // Label
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF263A62),
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

        // Input
        TextField(
          controller: controller,
          keyboardType: keyboardType,

          style: const TextStyle(fontSize: 16, color: Color(0xFF202A3D)),

          decoration: InputDecoration(
            prefixIcon: Container(
              margin: const EdgeInsets.all(8),

              width: 42,
              height: 42,

              decoration: BoxDecoration(
                color: const Color(0xFFEAF0FF),
                borderRadius: BorderRadius.circular(11),
              ),

              child: Icon(icon, color: const Color(0xFF657797), size: 22),
            ),

            hintText: hint,

            hintStyle: const TextStyle(color: Color(0xFF9EA6B6), fontSize: 16),

            filled: true,

            fillColor: const Color(0xFFFAFBFD),

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 17,
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

        const SizedBox(height: 7),

        // Helper
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Text(
            helperText,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: Color(0xFF7A8498),
            ),
          ),
        ),
      ],
    );
  }


  // CREATE BUTTON


  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,

      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _handleSubmit,

        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF244397),

          disabledBackgroundColor: const Color(0xFF8A9BC9),

          elevation: 0,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),

        child: _isSubmitting
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
                  Icon(Icons.person_add_alt_1, color: Colors.white, size: 23),

                  SizedBox(width: 10),

                  Text(
                    'Tạo tài khoản',
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


  // ERROR BOX


  Widget _buildErrorBox(String message) {
    return Container(
      width: double.infinity,

      margin: const EdgeInsets.only(bottom: 14),

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
              message,
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


  // RESULT BOX


  Widget _buildResultBox(Map<String, dynamic> result) {
    final emailSent = result['emailSent'] == true;

    return Container(
      width: double.infinity,

      margin: const EdgeInsets.only(bottom: 14),

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

          // RESULT HEADER

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
            padding: const EdgeInsets.all(12),

            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),

              borderRadius: BorderRadius.circular(12),
            ),

            child: Column(
              children: [
                _resultRow('Username', result['username']),

                const SizedBox(height: 8),

                _resultRow('Họ tên', result['fullName']),

                const SizedBox(height: 8),

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
              color: Color(0xFF263A62),
            ),
          ),
        ),
      ],
    );
  }
}
