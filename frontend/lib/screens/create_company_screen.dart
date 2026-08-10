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
  final _adminFullNameController = TextEditingController();
  final _adminEmailController = TextEditingController();

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
    _adminFullNameController.dispose();
    _adminEmailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_companyNameController.text.trim().isEmpty ||
        _companyCodeController.text.trim().isEmpty) {
      setState(
        () => _errorMessage = 'Tên công ty và mã công ty không được để trống.',
      );
      return;
    }
    if (_adminFullNameController.text.trim().isEmpty ||
        _adminEmailController.text.trim().isEmpty) {
      setState(
        () => _errorMessage = 'Họ tên và email Admin không được để trống.',
      );
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
      'adminFullName': _adminFullNameController.text.trim(),
      'adminEmail': _adminEmailController.text.trim(),
    }, bearerToken: AuthState.instance.token);

    setState(() {
      _isSubmitting = false;
      if (result.success) {
        _result = result.data;
      } else {
        _errorMessage = result.errorMessage;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tạo công ty mới'),
        backgroundColor: AppColors.cardBackground,
        foregroundColor: AppColors.primaryBlue,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionCard(
                title: 'Thông tin công ty',
                children: [
                  _buildTextField(
                    controller: _companyNameController,
                    label: 'Tên công ty',
                    hint: 'Acme Corporation',
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _companyCodeController,
                    label: 'Mã công ty',
                    hint: 'acme',
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _addressController,
                    label: 'Địa chỉ',
                    hint: '',
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _contactEmailController,
                    label: 'Email liên hệ',
                    hint: 'hr@acme.com',
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _contactPhoneController,
                    label: 'Số điện thoại liên hệ',
                    hint: '',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'Tài khoản Admin đầu tiên',
                children: [
                  _buildTextField(
                    controller: _adminFullNameController,
                    label: 'Họ tên Admin',
                    hint: 'Nguyễn Văn A',
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _adminEmailController,
                    label: 'Email Admin',
                    hint: 'admin@acme.com',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_errorMessage != null) _buildErrorBox(_errorMessage!),
              if (_result != null) _buildResultBox(_result!),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
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
                      : const Text(
                          'Tạo công ty',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFB0B3BD)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
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

  Widget _buildErrorBox(String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.dangerRedBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.dangerRed, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.dangerRed, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultBox(Map<String, dynamic> result) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.successGreenBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.successGreen, size: 20),
              SizedBox(width: 8),
              Text(
                'Tạo công ty thành công!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.successGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _resultRow('Tên công ty', result['companyName']),
          _resultRow('Mã công ty', result['companyCode']),
          _resultRow('Username Admin', result['adminUsername']),
          _resultRow('Mật khẩu tạm thời', result['adminTemporaryPassword']),
          const SizedBox(height: 8),
          const Text(
            'Gửi thông tin đăng nhập này cho công ty ngay — mật khẩu chỉ hiển thị 1 lần.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              '$value',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
