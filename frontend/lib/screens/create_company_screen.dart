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

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyCodeController.dispose();
    _addressController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();

    super.dispose();
  }

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
        _errorMessage =
            'Không thể kết nối đến hệ thống. '
            'Vui lòng thử lại.';
      });
    }
  }

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
            borderRadius: BorderRadius.circular(18),
          ),

          icon: const Icon(
            Icons.check_circle,
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
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Tài khoản Admin',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        adminUsername,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
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
                  color: AppColors.textSecondary,
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
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Hoàn tất'),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        foregroundColor: AppColors.primaryBlue,
        elevation: 0,

        leading: IconButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, size: 27),
        ),

        title: const Text(
          'Tạo công ty mới',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,

          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              _buildIntro(),

              const SizedBox(height: 16),

              _buildCompanyForm(),

              const SizedBox(height: 16),

              if (_errorMessage != null) _buildErrorBox(),

              const SizedBox(height: 8),

              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),

      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,

            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.10),
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.business_outlined,
              color: AppColors.primaryBlue,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Text(
              'Nhập thông tin công ty. '
              'Hệ thống sẽ tự động tạo tài khoản Admin '
              'và gửi thông tin đăng nhập qua email.',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderColor),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            'Thông tin công ty',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 18),

          _buildTextField(
            controller: _companyNameController,
            label: 'Tên công ty',
            hint: 'FlexTime Corporation',
            icon: Icons.business_outlined,
          ),

          const SizedBox(height: 16),

          _buildTextField(
            controller: _companyCodeController,
            label: 'Mã công ty',
            hint: 'flextime',
            icon: Icons.tag_outlined,
          ),

          const SizedBox(height: 16),

          _buildTextField(
            controller: _addressController,
            label: 'Địa chỉ',
            hint: 'Địa chỉ công ty',
            icon: Icons.location_on_outlined,
          ),

          const SizedBox(height: 16),

          _buildTextField(
            controller: _contactEmailController,
            label: 'Email liên hệ',
            hint: 'hr@congty.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 16),

          _buildTextField(
            controller: _contactPhoneController,
            label: 'Số điện thoại liên hệ',
            hint: '0123456789',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

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
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 7),

        TextField(
          controller: controller,
          keyboardType: keyboardType,

          decoration: InputDecoration(
            hintText: hint,

            hintStyle: const TextStyle(color: Color(0xFFB0B3BD), fontSize: 14),

            prefixIcon: Icon(icon, color: AppColors.primaryBlue, size: 21),

            filled: true,
            fillColor: AppColors.cardBackground,

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
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

  Widget _buildErrorBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: AppColors.dangerRedBg,
        borderRadius: BorderRadius.circular(13),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Icon(Icons.error_outline, color: AppColors.dangerRed, size: 21),

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

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,

      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _handleSubmit,

        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,

          disabledBackgroundColor: AppColors.primaryBlue.withOpacity(0.6),

          foregroundColor: Colors.white,

          elevation: 0,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),

        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.3,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  Icon(Icons.add_business_outlined, size: 21),

                  SizedBox(width: 9),

                  Text(
                    'Tạo công ty',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }
}
