import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/auth_state.dart';

class CompanyDetailScreen extends StatefulWidget {
  final Map<String, dynamic> company;

  const CompanyDetailScreen({super.key, required this.company});

  @override
  State<CompanyDetailScreen> createState() => _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends State<CompanyDetailScreen> {
  late Map<String, dynamic> _company;

  bool _isEditing = false;
  bool _isSaving = false;

  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _addressController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();

    _company = Map<String, dynamic>.from(widget.company);

    _nameController = TextEditingController(
      text: _company['name']?.toString() ?? '',
    );

    _codeController = TextEditingController(
      text: _company['companyCode']?.toString() ?? '',
    );

    _addressController = TextEditingController(
      text: _company['address']?.toString() ?? '',
    );

    _emailController = TextEditingController(
      text: _company['contactEmail']?.toString() ?? '',
    );

    _phoneController = TextEditingController(
      text: _company['contactPhone']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final name = _nameController.text.trim();
    final code = _codeController.text.trim();
    final address = _addressController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      _showMessage('Tên công ty không được để trống.');
      return;
    }

    if (code.isEmpty) {
      _showMessage('Mã công ty không được để trống.');
      return;
    }

    if (email.isEmpty) {
      _showMessage('Email công ty không được để trống.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final companyId = _company['id']?.toString();

    final result = await ApiService.put('/api/companies/$companyId', {
      'companyName': name,
      'companyCode': code,
      'address': address,
      'contactEmail': email,
      'contactPhone': phone,
    }, bearerToken: AuthState.instance.token);

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (result.success) {
      final updatedCompany = result.data!;

      setState(() {
        _company = updatedCompany;
        _isEditing = false;

        _nameController.text = updatedCompany['name']?.toString() ?? '';

        _codeController.text = updatedCompany['companyCode']?.toString() ?? '';

        _addressController.text = updatedCompany['address']?.toString() ?? '';

        _emailController.text =
            updatedCompany['contactEmail']?.toString() ?? '';

        _phoneController.text =
            updatedCompany['contactPhone']?.toString() ?? '';
      });

      _showMessage('Thông tin công ty đã được cập nhật.', success: true);
    } else {
      _showMessage(result.errorMessage ?? 'Không thể cập nhật công ty.');
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;

      _nameController.text = _company['name']?.toString() ?? '';

      _codeController.text = _company['companyCode']?.toString() ?? '';

      _addressController.text = _company['address']?.toString() ?? '';

      _emailController.text = _company['contactEmail']?.toString() ?? '';

      _phoneController.text = _company['contactPhone']?.toString() ?? '';
    });
  }

  void _showMessage(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppColors.successGreen : AppColors.dangerRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _company['status']?.toString() ?? 'Unknown';

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        foregroundColor: AppColors.primaryBlue,
        elevation: 0,

        title: const Text(
          'Thông tin công ty',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
        ),

        actions: [
          if (!_isEditing)
            IconButton(
              tooltip: 'Chỉnh sửa',
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCompanyHeader(status),

              const SizedBox(height: 18),

              _buildInformationCard(),

              const SizedBox(height: 16),

              _buildContactCard(),

              const SizedBox(height: 20),

              if (_isEditing) _buildEditActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyHeader(String status) {
    final isActive = status == 'Active';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.business_rounded,
              size: 30,
              color: AppColors.primaryBlue,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _company['name']?.toString() ?? 'Chưa có tên',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'Mã: ${_company['companyCode'] ?? '-'}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 9),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.successGreenBg
                        : AppColors.amberBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? 'Đang hoạt động' : 'Tạm ngưng',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? AppColors.successGreen
                          : AppColors.amber,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationCard() {
    return _buildSectionCard(
      title: 'Thông tin doanh nghiệp',
      icon: Icons.business_outlined,
      children: [
        _buildField(
          controller: _nameController,
          label: 'Tên công ty',
          icon: Icons.business_outlined,
          enabled: _isEditing,
        ),

        const SizedBox(height: 15),

        _buildField(
          controller: _codeController,
          label: 'Mã công ty',
          icon: Icons.tag_outlined,
          enabled: _isEditing,
        ),

        const SizedBox(height: 15),

        _buildField(
          controller: _addressController,
          label: 'Địa chỉ',
          icon: Icons.location_on_outlined,
          enabled: _isEditing,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildContactCard() {
    return _buildSectionCard(
      title: 'Thông tin liên hệ',
      icon: Icons.contact_phone_outlined,
      children: [
        _buildField(
          controller: _emailController,
          label: 'Email công ty',
          icon: Icons.email_outlined,
          enabled: _isEditing,
          keyboardType: TextInputType.emailAddress,
        ),

        const SizedBox(height: 15),

        _buildField(
          controller: _phoneController,
          label: 'Số điện thoại',
          icon: Icons.phone_outlined,
          enabled: _isEditing,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
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
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primaryBlue),

              const SizedBox(width: 8),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          ...children,
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),

        const SizedBox(height: 7),

        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          keyboardType: keyboardType,

          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              size: 21,
              color: enabled ? AppColors.primaryBlue : AppColors.textSecondary,
            ),

            filled: true,
            fillColor: enabled
                ? AppColors.cardBackground
                : AppColors.background,

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

            disabledBorder: OutlineInputBorder(
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

  Widget _buildEditActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSaving ? null : _cancelEdit,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              side: const BorderSide(color: AppColors.borderColor),
            ),
            child: const Text(
              'Hủy',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveChanges,
            icon: _isSaving
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.save_outlined, size: 20),
            label: Text(_isSaving ? 'Đang lưu...' : 'Lưu thay đổi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
