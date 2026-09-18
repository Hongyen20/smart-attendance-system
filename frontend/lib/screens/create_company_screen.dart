import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
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
  String? _errorMessage;

  // AttendGo COLORS
  static const Color primary = Color(0xFF2864E8);
  static const Color primaryDark = Color(0xFF294477);

  static const Color background = Color(0xFFF1F5FF);
  static const Color card = Colors.white;

  static const Color textPrimary = Color(0xFF182A52);
  static const Color textSecondary = Color(0xFF687895);

  static const Color border = Color(0xFFDCE5F8);
  static const Color softBlue = Color(0xFFEAF1FF);

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyCodeController.dispose();
    _addressController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();

    super.dispose();
  }

  // =========================================================
  // SUBMIT
  // =========================================================

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();

    final companyName = _companyNameController.text.trim();
    final companyCode = _companyCodeController.text.trim();
    final address = _addressController.text.trim();
    final email = _contactEmailController.text.trim();
    final phone = _contactPhoneController.text.trim();

    if (companyName.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập tên công ty.';
      });
      return;
    }

    if (companyCode.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập mã công ty.';
      });
      return;
    }

    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập email liên hệ.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.post('/api/companies', {
        'companyName': companyName,
        'companyCode': companyCode,
        'address': address,
        'contactEmail': email,
        'contactPhone': phone,
      }, bearerToken: AuthState.instance.token);

      if (!mounted) return;

      if (result.success) {
        await _showSuccessDialog(result.data);

        if (!mounted) return;

        Navigator.pop(context, true);
      } else {
        setState(() {
          _isSubmitting = false;
          _errorMessage = result.errorMessage ?? 'Không thể tạo công ty.';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Không thể kết nối đến hệ thống. Vui lòng thử lại.';
      });
    }
  }

  // =========================================================
  // SUCCESS DIALOG
  // =========================================================

  Future<void> _showSuccessDialog(dynamic data) async {
    final companyName = data is Map
        ? data['companyName']?.toString() ?? ''
        : '';

    final adminUsername = data is Map
        ? data['adminUsername']?.toString() ?? ''
        : '';

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          icon: const Icon(
            Icons.check_circle_rounded,
            color: AppColors.successGreen,
            size: 52,
          ),

          title: const Text(
            'Tạo công ty thành công',
            textAlign: TextAlign.center,
          ),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                companyName.isEmpty
                    ? 'Công ty đã được tạo.'
                    : 'Công ty "$companyName" đã được tạo.',
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 14),

              if (adminUsername.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Tài khoản Admin',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        adminUsername,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              const Text(
                'Thông tin tài khoản Admin đã được gửi đến email liên hệ của công ty.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),

          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: const Text(
                  'Hoàn tất',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,

                padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormCard(),

                    const SizedBox(height: 16),

                    if (_errorMessage != null) _buildErrorBox(),

                    if (_errorMessage != null) const SizedBox(height: 16),

                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 20, 12),

      child: Row(
        children: [
          IconButton(
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),

            icon: const Icon(Icons.arrow_back_rounded, size: 30),

            color: primary,

            splashRadius: 24,
          ),

          const SizedBox(width: 6),

          const Expanded(
            child: Text(
              'Tạo công ty mới',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w600,
                color: primaryDark,
                letterSpacing: -0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // FORM CARD
  // =========================================================

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),

      decoration: BoxDecoration(
        color: card,

        borderRadius: BorderRadius.circular(22),

        border: Border.all(color: border, width: 1),

        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          _buildTextField(
            controller: _companyNameController,
            label: 'Tên công ty',
            hint: 'Nhập tên công ty',
            icon: Icons.business_rounded,
          ),

          const SizedBox(height: 22),

          _buildTextField(
            controller: _companyCodeController,
            label: 'Mã công ty',
            hint: 'Nhập mã công ty',
            icon: Icons.tag_rounded,
          ),

          const SizedBox(height: 22),

          _buildTextField(
            controller: _addressController,
            label: 'Địa chỉ',
            hint: 'Nhập địa chỉ công ty',
            icon: Icons.location_on_rounded,
          ),

          const SizedBox(height: 22),

          _buildTextField(
            controller: _contactEmailController,
            label: 'Email liên hệ',
            hint: 'Nhập email liên hệ',
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 22),

          _buildTextField(
            controller: _contactPhoneController,
            label: 'Số điện thoại liên hệ',
            hint: 'Nhập số điện thoại',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TEXT FIELD
  // =========================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          label,

          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),

        const SizedBox(height: 9),

        TextField(
          controller: controller,
          keyboardType: keyboardType,

          style: const TextStyle(
            fontSize: 16,
            color: textPrimary,
            fontWeight: FontWeight.w500,
          ),

          decoration: InputDecoration(
            hintText: hint,

            hintStyle: const TextStyle(
              color: Color(0xFF9BA6BC),
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),

            prefixIcon: Padding(
              padding: const EdgeInsets.all(10),
              child: Container(
                width: 42,
                height: 42,

                decoration: BoxDecoration(
                  color: softBlue,
                  borderRadius: BorderRadius.circular(13),
                ),

                child: Icon(icon, color: primary, size: 23),
              ),
            ),

            prefixIconConstraints: const BoxConstraints(
              minWidth: 64,
              minHeight: 64,
            ),

            filled: true,
            fillColor: Colors.white,

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 17,
            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(color: border, width: 1.2),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(color: border, width: 1.2),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(color: primary, width: 1.7),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // ERROR
  // =========================================================

  Widget _buildErrorBox() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: AppColors.dangerRedBg,
        borderRadius: BorderRadius.circular(14),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.dangerRed,
            size: 21,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              _errorMessage!,

              style: const TextStyle(
                color: AppColors.dangerRed,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SUBMIT BUTTON
  // =========================================================

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,

      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _handleSubmit,

        style: ElevatedButton.styleFrom(
          backgroundColor: primary,

          disabledBackgroundColor: primary.withOpacity(0.6),

          foregroundColor: Colors.white,

          elevation: 0,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),

          shadowColor: primary.withOpacity(0.25),
        ),

        child: _isSubmitting
            ? const SizedBox(
                width: 23,
                height: 23,

                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.4,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  Icon(Icons.add_business_rounded, size: 23),

                  SizedBox(width: 10),

                  Text(
                    'Tạo công ty',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
      ),
    );
  }
}
