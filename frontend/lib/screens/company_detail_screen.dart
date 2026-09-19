import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_state.dart';
import '../theme/app_colors.dart';

class CompanyDetailScreen extends StatefulWidget {
  final Map<String, dynamic> company;

  const CompanyDetailScreen({super.key, required this.company});

  @override
  State<CompanyDetailScreen> createState() => _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends State<CompanyDetailScreen> {
  late Map<String, dynamic> company;

  bool _isEditing = false;
  bool _isSaving = false;
  bool _isChangingStatus = false;
  bool _isSendingPassword = false;

  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _addressController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();

    company = Map<String, dynamic>.from(widget.company);

    _nameController = TextEditingController(
      text: company['name']?.toString() ?? '',
    );

    _codeController = TextEditingController(
      text: company['companyCode']?.toString() ?? '',
    );

    _addressController = TextEditingController(
      text: company['address']?.toString() ?? '',
    );

    _emailController = TextEditingController(
      text: company['contactEmail']?.toString() ?? '',
    );

    _phoneController = TextEditingController(
      text: company['contactPhone']?.toString() ?? '',
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

  String get _companyId => company['id']?.toString() ?? '';

  String get _companyName => company['name']?.toString() ?? 'Công ty';

  String get _companyCode => company['companyCode']?.toString() ?? '';

  String get _companyStatus => company['status']?.toString() ?? 'Active';

  String get _contactEmail => company['contactEmail']?.toString() ?? '';

  bool get _isActive => _companyStatus.toLowerCase() == 'active';

  String _formatDate(dynamic value) {
    if (value == null) {
      return 'Chưa có thông tin';
    }

    try {
      final date = DateTime.parse(value.toString());

      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();

      return '$day/$month/$year';
    } catch (_) {
      return value.toString();
    }
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  void _cancelEditing() {
    _nameController.text = company['name']?.toString() ?? '';

    _codeController.text = company['companyCode']?.toString() ?? '';

    _addressController.text = company['address']?.toString() ?? '';

    _emailController.text = company['contactEmail']?.toString() ?? '';

    _phoneController.text = company['contactPhone']?.toString() ?? '';

    setState(() {
      _isEditing = false;
    });
  }

  Future<void> _saveChanges() async {
    if (_companyId.isEmpty) {
      return;
    }

    final companyName = _nameController.text.trim();

    final companyCode = _codeController.text.trim();

    final address = _addressController.text.trim();

    final contactEmail = _emailController.text.trim();

    final contactPhone = _phoneController.text.trim();

    if (companyName.isEmpty) {
      _showMessage('Tên công ty không được để trống.');
      return;
    }

    if (companyCode.isEmpty) {
      _showMessage('Mã công ty không được để trống.');
      return;
    }

    if (contactEmail.isEmpty) {
      _showMessage('Email liên hệ không được để trống.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final result = await ApiService.put('/api/companies/$_companyId', {
        'companyName': companyName,
        'companyCode': companyCode,
        'address': address,
        'contactEmail': contactEmail,
        'contactPhone': contactPhone,
      }, bearerToken: AuthState.instance.token);

      if (!mounted) {
        return;
      }

      if (result.success) {
        final updatedCompany = result.data ?? {};

        setState(() {
          company = {...company, ...updatedCompany};

          _isEditing = false;
        });

        _showMessage('Đã cập nhật thông tin công ty.', success: true);
      } else {
        _showMessage(
          result.errorMessage ?? 'Không thể cập nhật thông tin công ty.',
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage('Không thể kết nối tới máy chủ.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _changeCompanyStatus() async {
    if (_companyId.isEmpty) {
      return;
    }

    final newStatus = _isActive ? 'Inactive' : 'Active';

    final actionText = _isActive ? 'khóa' : 'kích hoạt';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_isActive ? 'Khóa công ty' : 'Kích hoạt công ty'),
          content: Text(
            'Bạn có chắc chắn muốn $actionText '
            'công ty "$_companyName"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: Text(_isActive ? 'Khóa công ty' : 'Kích hoạt'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isChangingStatus = true;
    });

    try {
      final result = await ApiService.put('/api/companies/$_companyId/status', {
        'status': newStatus,
      }, bearerToken: AuthState.instance.token);

      if (!mounted) {
        return;
      }

      if (result.success) {
        setState(() {
          company = {...company, ...?result.data, 'status': newStatus};
        });

        _showMessage(
          newStatus == 'Active' ? 'Đã kích hoạt công ty.' : 'Đã khóa công ty.',
          success: true,
        );
      } else {
        _showMessage(
          result.errorMessage ?? 'Không thể thay đổi trạng thái công ty.',
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage('Không thể kết nối tới máy chủ.');
    } finally {
      if (mounted) {
        setState(() {
          _isChangingStatus = false;
        });
      }
    }
  }

  Future<void> _resetAdminPassword() async {
    if (_companyId.isEmpty) {
      return;
    }

    if (_contactEmail.trim().isEmpty) {
      _showMessage('Công ty chưa có email liên hệ.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock_reset_rounded, size: 24),
              SizedBox(width: 10),
              Text('Gửi mật khẩu mới'),
            ],
          ),
          content: Text(
            'Hệ thống sẽ tạo một mật khẩu mới cho '
            'tài khoản Admin của công ty.\n\n'
            'Mật khẩu mới sẽ được gửi đến email liên hệ:\n'
            '$_contactEmail\n\n'
            'Bạn có chắc chắn muốn tiếp tục?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Hủy'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context, true);
              },
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Gửi mật khẩu'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isSendingPassword = true;
    });

    try {
      final result = await ApiService.put(
        '/api/companies/$_companyId/admin/reset-password',
        {},
        bearerToken: AuthState.instance.token,
      );

      if (!mounted) {
        return;
      }

      if (result.success) {
        _showMessage(
          result.data?['message']?.toString() ??
              'Đã tạo mật khẩu mới và gửi đến email liên hệ.',
          success: true,
        );
      } else {
        _showMessage(result.errorMessage ?? 'Không thể gửi mật khẩu mới.');
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage('Không thể kết nối tới máy chủ.');
    } finally {
      if (mounted) {
        setState(() {
          _isSendingPassword = false;
        });
      }
    }
  }

  void _showMessage(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? Colors.green.shade700 : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: Colors.black87,
        title: const Text(
          'Chi tiết công ty',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              tooltip: 'Chỉnh sửa',
              onPressed: _startEditing,
              icon: const Icon(Icons.edit_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 32 : 16,
                vertical: 12,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildCompanyHeader(theme),

                      const SizedBox(height: 16),

                      _buildCompanyInformationCard(),

                      const SizedBox(height: 16),

                      _buildAdminSecurityCard(),

                      const SizedBox(height: 16),

                      _buildOtherInformationCard(),

                      if (_isEditing) ...[
                        const SizedBox(height: 20),
                        _buildEditActions(),
                      ] else ...[
                        const SizedBox(height: 20),
                        _buildStatusAction(),
                      ],

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCompanyHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryBlue, AppColors.accentBlue],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.business_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _companyName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _companyCode.isEmpty
                      ? 'Chưa có mã công ty'
                      : 'Mã công ty: $_companyCode',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.88),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                _buildStatusBadge(light: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge({bool light = false}) {
    final active = _isActive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: light
            ? Colors.white.withOpacity(0.18)
            : active
            ? Colors.green.withOpacity(0.10)
            : Colors.red.withOpacity(0.10),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? Colors.greenAccent : Colors.redAccent,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            active ? 'Đang hoạt động' : 'Đã khóa',
            style: TextStyle(
              color: light
                  ? Colors.white
                  : active
                  ? Colors.green.shade700
                  : Colors.red.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyInformationCard() {
    return _buildCard(
      title: 'Thông tin công ty',
      icon: Icons.business_outlined,
      child: Column(
        children: [
          if (_isEditing) ...[
            _buildTextField(
              controller: _nameController,
              label: 'Tên công ty',
              icon: Icons.business_outlined,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _codeController,
              label: 'Mã công ty',
              icon: Icons.tag_rounded,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _addressController,
              label: 'Địa chỉ',
              icon: Icons.location_on_outlined,
              maxLines: 2,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _emailController,
              label: 'Email liên hệ',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _phoneController,
              label: 'Số điện thoại',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
          ] else ...[
            _buildInfoRow(
              icon: Icons.business_outlined,
              label: 'Tên công ty',
              value: _companyName,
            ),
            _buildDivider(),
            _buildInfoRow(
              icon: Icons.tag_rounded,
              label: 'Mã công ty',
              value: _companyCode.isEmpty ? 'Chưa có' : _companyCode,
            ),
            _buildDivider(),
            _buildInfoRow(
              icon: Icons.location_on_outlined,
              label: 'Địa chỉ',
              value: company['address']?.toString().trim().isNotEmpty == true
                  ? company['address'].toString()
                  : 'Chưa có',
            ),
            _buildDivider(),
            _buildInfoRow(
              icon: Icons.email_outlined,
              label: 'Email liên hệ',
              value: _contactEmail.isEmpty ? 'Chưa có' : _contactEmail,
            ),
            _buildDivider(),
            _buildInfoRow(
              icon: Icons.phone_outlined,
              label: 'Số điện thoại',
              value:
                  company['contactPhone']?.toString().trim().isNotEmpty == true
                  ? company['contactPhone'].toString()
                  : 'Chưa có',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdminSecurityCard() {
    return _buildCard(
      title: 'Tài khoản quản trị',
      icon: Icons.admin_panel_settings_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primaryBlue.withOpacity(0.10),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primaryBlue,
                  size: 21,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Bạn có thể tạo mật khẩu mới cho '
                    'tài khoản Admin. Mật khẩu mới sẽ '
                    'được gửi đến email liên hệ của công ty.',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.email_rounded, color: AppColors.primaryBlue),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email nhận mật khẩu',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _contactEmail.isEmpty
                            ? 'Chưa có email liên hệ'
                            : _contactEmail,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _isSendingPassword ? null : _resetAdminPassword,
              icon: _isSendingPassword
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.lock_reset_rounded),
              label: Text(
                _isSendingPassword
                    ? 'Đang gửi mật khẩu...'
                    : 'Gửi mật khẩu mới cho Admin',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherInformationCard() {
    return _buildCard(
      title: 'Thông tin khác',
      icon: Icons.info_outline_rounded,
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.circle_outlined,
            label: 'Trạng thái',
            valueWidget: _buildStatusBadge(),
          ),
          _buildDivider(),
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Ngày tạo',
            value: _formatDate(company['createdAt']),
          ),
        ],
      ),
    );
  }

  Widget _buildEditActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSaving ? null : _cancelEditing,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Hủy'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: _isSaving ? null : _saveChanges,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(_isSaving ? 'Đang lưu...' : 'Lưu thay đổi'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusAction() {
    return SizedBox(
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _isChangingStatus ? null : _changeCompanyStatus,
        style: OutlinedButton.styleFrom(
          foregroundColor: _isActive
              ? Colors.red.shade700
              : Colors.green.shade700,
          side: BorderSide(
            color: _isActive ? Colors.red.shade200 : Colors.green.shade200,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: _isChangingStatus
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                _isActive
                    ? Icons.lock_outline_rounded
                    : Icons.lock_open_rounded,
              ),
        label: Text(
          _isChangingStatus
              ? 'Đang xử lý...'
              : _isActive
              ? 'Khóa công ty'
              : 'Kích hoạt công ty',
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: AppColors.primaryBlue, size: 21),
              ),
              const SizedBox(width: 11),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    String? value,
    Widget? valueWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                valueWidget ??
                    Text(
                      value ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Divider(height: 1, color: Colors.grey.shade200),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
      ),
    );
  }
}
