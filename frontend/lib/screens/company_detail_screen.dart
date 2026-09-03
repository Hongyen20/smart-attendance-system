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
  bool _isChangingStatus = false;

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

  // CHANGE COMPANY STATUS (lock / unlock)
  Future<void> _changeCompanyStatus() async {
    final currentStatus = _company['status']?.toString() ?? 'Active';

    final isActive = currentStatus == 'Active';

    final newStatus = isActive ? 'Suspended' : 'Active';

    final companyName = _company['name']?.toString() ?? 'công ty này';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            isActive ? 'Tạm khóa công ty?' : 'Mở khóa công ty?',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            isActive
                ? 'Công ty "$companyName" sẽ không thể đăng nhập '
                      'vào hệ thống cho đến khi được mở khóa.'
                : 'Bạn có chắc muốn mở khóa công ty '
                      '"$companyName" không?',
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Hủy',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive
                    ? AppColors.dangerRed
                    : AppColors.successGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              child: Text(isActive ? 'Tạm khóa' : 'Mở khóa'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final companyId = _company['id']?.toString();

    if (companyId == null || companyId.isEmpty) {
      _showMessage('Không tìm thấy ID công ty.');
      return;
    }

    setState(() {
      _isChangingStatus = true;
    });

    final result = await ApiService.put('/api/companies/$companyId/status', {
      'status': newStatus,
    }, bearerToken: AuthState.instance.token);

    if (!mounted) return;

    setState(() {
      _isChangingStatus = false;
    });

    if (result.success) {
      setState(() {
        _company['status'] = newStatus;
      });

      _showMessage(
        isActive ? 'Đã tạm khóa công ty.' : 'Đã mở khóa công ty.',
        success: true,
      );
    } else {
      _showMessage(
        result.errorMessage ?? 'Không thể thay đổi trạng thái công ty.',
      );
    }
  }

  void _showMessage(String message, {bool success = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success
              ? AppColors.successGreen
              : AppColors.dangerRed,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  // Format an ISO-ish date string as dd/MM/yyyy, falling back to '-'
  String _formatDate(dynamic rawValue) {
    if (rawValue == null) return '-';

    final text = rawValue.toString();

    if (text.isEmpty) return '-';

    final parsed = DateTime.tryParse(text);

    if (parsed == null) return text;

    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final year = parsed.year.toString();

    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        automaticallyImplyLeading: false,

        titleSpacing: 20,

        title: Row(
          children: [
            _buildRoundIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.pop(context),
            ),

            const SizedBox(width: 14),

            const Expanded(
              child: Text(
                'Thông tin công ty',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            if (!_isEditing)
              _buildRoundIconButton(
                icon: Icons.edit_outlined,
                onTap: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
              ),
          ],
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCompanyHeader(),

              const SizedBox(height: 14),

              _buildInformationCard(),

              const SizedBox(height: 14),

              if (!_isEditing) _buildOtherInfoCard(),

              if (!_isEditing) const SizedBox(height: 18),

              if (_isEditing) _buildEditActions(),

              if (!_isEditing) _buildStatusButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoundIconButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 17, color: AppColors.primaryBlue),
        splashRadius: 18,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildCompanyHeader() {
    final status = _company['status']?.toString() ?? 'Unknown';

    final isActive = status == 'Active';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.10),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.business_rounded,
              size: 24,
              color: AppColors.primaryBlue,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _company['name']?.toString() ?? 'Chưa có tên',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Mã: ${_company['companyCode'] ?? '-'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.successGreenBg
                        : AppColors.dangerRedBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? AppColors.successGreen
                              : AppColors.dangerRed,
                        ),
                      ),

                      const SizedBox(width: 5),

                      Text(
                        isActive ? 'Đang hoạt động' : 'Tạm khóa',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? AppColors.successGreen
                              : AppColors.dangerRed,
                        ),
                      ),
                    ],
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

        const SizedBox(height: 14),

        _buildField(
          controller: _codeController,
          label: 'Mã công ty',
          icon: Icons.tag_outlined,
          enabled: _isEditing,
        ),

        const SizedBox(height: 14),

        _buildField(
          controller: _addressController,
          label: 'Địa chỉ',
          icon: Icons.location_on_outlined,
          enabled: _isEditing,
          maxLines: 2,
        ),

        const SizedBox(height: 14),

        _buildField(
          controller: _emailController,
          label: 'Email liên hệ',
          icon: Icons.email_outlined,
          enabled: _isEditing,
          keyboardType: TextInputType.emailAddress,
        ),

        const SizedBox(height: 14),

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

  Widget _buildOtherInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 12, bottom: 4),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: AppColors.primaryBlue,
                ),
                SizedBox(width: 8),
                Text(
                  'Thông tin khác',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          _buildMetaRow('Ngày tạo', _formatDate(_company['createdAt'])),

          _buildMetaRow(
            'Cập nhật gần nhất',
            _formatDate(_company['updatedAt']),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE5ECFA))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
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
              Icon(icon, size: 18, color: AppColors.primaryBlue),

              const SizedBox(width: 8),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

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
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),

        const SizedBox(height: 6),

        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          keyboardType: keyboardType,

          style: TextStyle(
            fontSize: 13.5,
            color: enabled ? AppColors.textPrimary : AppColors.textPrimary,
          ),

          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              size: 19,
              color: enabled ? AppColors.primaryBlue : AppColors.textSecondary,
            ),

            filled: true,
            fillColor: enabled
                ? AppColors.cardBackground
                : AppColors.background,

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),

            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
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
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
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
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.save_outlined, size: 19),
            label: Text(_isSaving ? 'Đang lưu...' : 'Lưu thay đổi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // LOCK / UNLOCK BUTTON
  Widget _buildStatusButton() {
    final status = _company['status']?.toString() ?? 'Active';

    final isActive = status == 'Active';

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isChangingStatus ? null : _changeCompanyStatus,
        icon: _isChangingStatus
            ? SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isActive
                      ? AppColors.dangerRed
                      : AppColors.successGreen,
                ),
              )
            : Icon(
                isActive ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                size: 18,
              ),
        label: Text(
          isActive ? 'Tạm khóa công ty' : 'Mở khóa công ty',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive
              ? AppColors.dangerRedBg
              : AppColors.successGreenBg,
          foregroundColor: isActive
              ? AppColors.dangerRed
              : AppColors.successGreen,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
    );
  }
}
