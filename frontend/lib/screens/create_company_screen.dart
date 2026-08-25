import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_state.dart';

class CreateCompanyScreen extends StatefulWidget {
  const CreateCompanyScreen({super.key});

  @override
  State<CreateCompanyScreen> createState() => _CreateCompanyScreenState();
}

class _CreateCompanyScreenState extends State<CreateCompanyScreen> {
  final _companyNameController = TextEditingController();
  final _companyCodeController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();

  bool _isSubmitting = false;

  Map<String, dynamic>? _result;
  String? _errorMessage;

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyCodeController.dispose();
    _addressController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  // CREATE COMPANY

  Future<void> _handleSubmit() async {
    if (_companyNameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Tên công ty không được để trống.';
        _result = null;
      });
      return;
    }

    if (_companyCodeController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Mã công ty không được để trống.';
        _result = null;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _result = null;
    });

    final result = await ApiService.post('/api/companies', {
      'companyName': _companyNameController.text.trim(),
      'companyCode': _companyCodeController.text.trim(),
      'address': _addressController.text.trim(),
      'contactEmail': _contactEmailController.text.trim(),
      'contactPhone': _contactPhoneController.text.trim(),
    }, bearerToken: AuthState.instance.token);

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;

      if (result.success) {
        _result = result.data;
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
                    _buildInfoNotice(),

                    const SizedBox(height: 16),

                    _buildCompanyCard(),

                    const SizedBox(height: 16),

                    if (_errorMessage != null) _buildErrorBox(_errorMessage!),

                    if (_result != null) _buildResultBox(_result!),

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
              'Tạo công ty mới',
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

  // INFO NOTICE
  Widget _buildInfoNotice() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),

      decoration: BoxDecoration(
        color: const Color(0xFFF3F7FF),

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: const Color(0xFFD2E0FF)),
      ),

      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,

            decoration: const BoxDecoration(
              color: Color(0xFFE3EDFF),
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.info_outline,
              color: Color(0xFF3972C8),
              size: 22,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Text(
              'Vui lòng nhập đầy đủ thông tin để tạo công ty mới.',
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Color(0xFF31579E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // COMPANY CARD
  Widget _buildCompanyCard() {
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

          // CARD HEADER
          Row(
            children: [
              Container(
                width: 54,
                height: 54,

                decoration: const BoxDecoration(
                  color: Color(0xFFEAF0FF),
                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.business_outlined,
                  color: Color(0xFF244397),
                  size: 28,
                ),
              ),

              const SizedBox(width: 13),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông tin công ty',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF263A62),
                      ),
                    ),

                    SizedBox(height: 4),

                    Text(
                      'Nhập thông tin cơ bản của công ty.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF737D92)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          const Divider(height: 1, color: Color(0xFFE7EAF2)),

          const SizedBox(height: 20),


          // COMPANY NAME
          _buildTextField(
            controller: _companyNameController,
            label: 'Tên công ty',
            hint: 'FlexTime Corporation',
            icon: Icons.business_outlined,
            required: true,
            helperText: 'Tên đầy đủ của công ty.',
          ),

          const SizedBox(height: 18),


          // COMPANY CODE
          _buildTextField(
            controller: _companyCodeController,
            label: 'Mã công ty',
            hint: 'FI',
            icon: Icons.badge_outlined,
            required: true,
            helperText:
                'Mã công ty viết tắt, dùng để định danh trong hệ thống.',
          ),

          const SizedBox(height: 18),


          // ADDRESS
          _buildTextField(
            controller: _addressController,
            label: 'Địa chỉ',
            hint: '123 Đường ABC, Quận 1, TP. HCM',
            icon: Icons.location_on_outlined,
            required: false,
            helperText: 'Địa chỉ trụ sở hoặc địa chỉ liên hệ của công ty.',
            maxLines: 1,
          ),

          const SizedBox(height: 18),


          // CONTACT EMAIL
          _buildTextField(
            controller: _contactEmailController,
            label: 'Email liên hệ',
            hint: 'hr@acme.com',
            icon: Icons.email_outlined,
            required: true,
            helperText: 'Email dùng để nhận thông báo và liên hệ từ hệ thống.',
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 18),


          // CONTACT PHONE
          _buildTextField(
            controller: _contactPhoneController,
            label: 'Số điện thoại liên hệ',
            hint: '0123456789',
            icon: Icons.phone_outlined,
            required: true,
            helperText:
                'Số điện thoại dùng để hỗ trợ và liên hệ khi cần thiết.',
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
    required String hint,
    required IconData icon,
    required bool required,
    required String helperText,
    int maxLines = 1,
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

              if (required)
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
          maxLines: maxLines,
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

              child: Icon(icon, color: const Color(0xFF3972C8), size: 22),
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

        // Helper text
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
                  Icon(
                    Icons.business_center_outlined,
                    color: Colors.white,
                    size: 22,
                  ),

                  SizedBox(width: 10),

                  Text(
                    'Tạo công ty',
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
    return Container(
      width: double.infinity,

      margin: const EdgeInsets.only(bottom: 14),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: const Color(0xFFBBE8C8)),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Container(
            width: 40,
            height: 40,

            decoration: const BoxDecoration(
              color: Color(0xFFDDF8E6),
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.check_circle_outline,
              color: Color(0xFF16A34A),
              size: 22,
            ),
          ),

          const SizedBox(width: 11),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  'Tạo công ty thành công!',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF15803D),
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'Thông tin công ty đã được tạo thành công trong hệ thống.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Color(0xFF687389),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // RESULT ROW
  Widget _resultRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),

      child: Row(
        children: [
          SizedBox(
            width: 130,

            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF7A8498)),
            ),
          ),

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
      ),
    );
  }
}
