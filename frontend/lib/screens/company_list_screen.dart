import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/auth_state.dart';

class CompanyDetailScreen extends StatefulWidget {
  final Map<String, dynamic> company;

  const CompanyDetailScreen({
    super.key,
    required this.company,
  });

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

  // ATTENDGO COLORS

  static const Color primary = Color(0xFF2864E8);
  static const Color primaryDark = Color(0xFF294477);

  static const Color background = Color(0xFFF1F5FF);
  static const Color card = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF294477);
  static const Color textSecondary = Color(0xFF687895);

  static const Color border = Color(0xFFC9D9FF);
  static const Color softBlue = Color(0xFFEAF0FF);

  static const Color successGreen = Color(0xFF16A34A);
  static const Color successBg = Color(0xFFEAF9F2);

  static const Color dangerRed = Color(0xFFEF4444);
  static const Color dangerBg = Color(0xFFFFEDEF);

  // INIT

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

  // GETTERS

  String get _companyId => company['id']?.toString() ?? '';

  String get _companyName =>
      company['name']?.toString() ?? 'Chưa có tên công ty';

  String get _companyCode =>
      company['companyCode']?.toString() ?? '';

  String get _companyStatus =>
      company['status']?.toString() ?? 'Active';

  String get _contactEmail =>
      company['contactEmail']?.toString() ?? '';

  String get _contactPhone =>
      company['contactPhone']?.toString() ?? '';

  String get _address =>
      company['address']?.toString() ?? '';

  bool get _isActive =>
      _companyStatus.toLowerCase() == 'active';

  // DATE FORMAT

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

  // EDIT

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  void _cancelEditing() {
    _nameController.text =
        company['name']?.toString() ?? '';

    _codeController.text =
        company['companyCode']?.toString() ?? '';

    _addressController.text =
        company['address']?.toString() ?? '';

    _emailController.text =
        company['contactEmail']?.toString() ?? '';

    _phoneController.text =
        company['contactPhone']?.toString() ?? '';

    setState(() {
      _isEditing = false;
    });
  }

  // SAVE CHANGES

  Future<void> _saveChanges() async {
    if (_companyId.isEmpty) {
      _showMessage('Không tìm thấy ID công ty.');
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
      final result = await ApiService.put(
        '/api/companies/$_companyId',
        {
          'companyName': companyName,
          'companyCode': companyCode,
          'address': address,
          'contactEmail': contactEmail,
          'contactPhone': contactPhone,
        },
        bearerToken: AuthState.instance.token,
      );

      if (!mounted) return;

      if (result.success) {
        final updatedCompany = result.data ?? {};

        setState(() {
          company = {
            ...company,
            ...updatedCompany,
          };

          _isEditing = false;
        });

        _showMessage(
          'Đã cập nhật thông tin công ty.',
          success: true,
        );
      } else {
        _showMessage(
          result.errorMessage ??
              'Không thể cập nhật thông tin công ty.',
        );
      }
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'Không thể kết nối tới máy chủ.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // CHANGE STATUS

  Future<void> _changeCompanyStatus() async {
    if (_companyId.isEmpty) {
      _showMessage('Không tìm thấy ID công ty.');
      return;
    }

    final newStatus = _isActive ? 'Inactive' : 'Active';
    final actionText = _isActive ? 'khóa' : 'kích hoạt';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _isActive
                      ? dangerBg
                      : successBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  _isActive
                      ? Icons.lock_outline_rounded
                      : Icons.lock_open_rounded,
                  size: 20,
                  color: _isActive
                      ? dangerRed
                      : successGreen,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  _isActive
                      ? 'Tạm khóa công ty?'
                      : 'Kích hoạt công ty?',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Bạn có chắc chắn muốn $actionText '
            'công ty "$_companyName"?',
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: textSecondary,
            ),
          ),
          actionsPadding:
              const EdgeInsets.fromLTRB(20, 0, 20, 16),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Hủy',
                style: TextStyle(
                  color: textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isActive ? dangerRed : successGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              child: Text(
                _isActive
                    ? 'Tạm khóa'
                    : 'Kích hoạt',
              ),
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
      final result = await ApiService.put(
        '/api/companies/$_companyId/status',
        {
          'status': newStatus,
        },
        bearerToken: AuthState.instance.token,
      );

      if (!mounted) return;

      if (result.success) {
        setState(() {
          company = {
            ...company,
            ...?result.data,
            'status': newStatus,
          };
        });

        _showMessage(
          newStatus == 'Active'
              ? 'Đã kích hoạt công ty.'
              : 'Đã khóa công ty.',
          success: true,
        );
      } else {
        _showMessage(
          result.errorMessage ??
              'Không thể thay đổi trạng thái công ty.',
        );
      }
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'Không thể kết nối tới máy chủ.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isChangingStatus = false;
        });
      }
    }
  }

  // RESET ADMIN PASSWORD

  Future<void> _resetAdminPassword() async {
    if (_companyId.isEmpty) {
      _showMessage('Không tìm thấy ID công ty.');
      return;
    }

    if (_contactEmail.trim().isEmpty) {
      _showMessage(
        'Công ty chưa có email liên hệ.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: softBlue,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  size: 21,
                  color: primary,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Text(
                  'Gửi mật khẩu mới',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Hệ thống sẽ tạo một mật khẩu mới cho '
            'tài khoản Admin của công ty.\n\n'
            'Mật khẩu mới sẽ được gửi đến email liên hệ:\n'
            '$_contactEmail\n\n'
            'Bạn có chắc chắn muốn tiếp tục?',
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: textSecondary,
            ),
          ),
          actionsPadding:
              const EdgeInsets.fromLTRB(20, 0, 20, 16),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Hủy',
                style: TextStyle(
                  color: textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(
                Icons.send_rounded,
                size: 17,
              ),
              label: const Text('Gửi mật khẩu'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
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

      if (!mounted) return;

      if (result.success) {
        _showMessage(
          result.data?['message']?.toString() ??
              'Đã tạo mật khẩu mới và gửi đến email liên hệ.',
          success: true,
        );
      } else {
        _showMessage(
          result.errorMessage ??
              'Không thể gửi mật khẩu mới.',
        );
      }
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'Không thể kết nối tới máy chủ.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSendingPassword = false;
        });
      }
    }
  }

  // MESSAGE

  void _showMessage(
    String message, {
    bool success = false,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              success ? successGreen : dangerRed,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: background,
        foregroundColor: primaryDark,
        automaticallyImplyLeading: false,
        titleSpacing: 20,

        title: Row(
          children: [
            _buildRoundIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.pop(context),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Chi tiết công ty',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: primaryDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Thông tin và quản lý công ty',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            if (!_isEditing)
              _buildRoundIconButton(
                icon: Icons.edit_outlined,
                onTap: _startEditing,
              )
            else
              _buildRoundIconButton(
                icon: Icons.close_rounded,
                onTap: _isSaving
                    ? null
                    : _cancelEditing,
              ),
          ],
        ),
      ),

      body: SafeArea(
        top: false,
        child: _buildBody(),
      ),
    );
  }

  // ROUND ICON BUTTON

  Widget _buildRoundIconButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(
          icon,
          size: 19,
          color: primary,
        ),
        splashRadius: 20,
      ),
    );
  }

  // BODY

  Widget _buildBody() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20,
        8,
        20,
        30,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          _buildCompanyHeader(),

          const SizedBox(height: 14),

          _buildCompanyInformationCard(),

          const SizedBox(height: 14),

          _buildAdminSecurityCard(),

          const SizedBox(height: 14),

          _buildOtherInformationCard(),

          const SizedBox(height: 14),

          if (_isEditing)
            _buildEditActions()
          else
            _buildStatusAction(),

          const SizedBox(height: 10),

          _buildBackButton(),
        ],
      ),
    );
  }

  // COMPANY HEADER

  Widget _buildCompanyHeader() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: softBlue,
                  borderRadius:
                      BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.business_rounded,
                  color: primary,
                  size: 31,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _companyName,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),

                    const SizedBox(height: 7),

                    if (_companyCode.isNotEmpty)
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: softBlue,
                          borderRadius:
                              BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Mã: $_companyCode',
                          style:
                              const TextStyle(
                            fontSize: 10.5,
                            fontWeight:
                                FontWeight.w700,
                            color: primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              _buildStatusBadge(),
            ],
          ),

          const SizedBox(height: 15),

          Container(
            height: 1,
            color: const Color(0xFFE5ECFA),
          ),

          const SizedBox(height: 13),

          if (_contactEmail.isNotEmpty)
            _buildCompactContactRow(
              Icons.email_outlined,
              _contactEmail,
            ),

          if (_contactEmail.isNotEmpty &&
              _contactPhone.isNotEmpty)
            const SizedBox(height: 9),

          if (_contactPhone.isNotEmpty)
            _buildCompactContactRow(
              Icons.phone_outlined,
              _contactPhone,
            ),

          if (_address.isNotEmpty) ...[
            const SizedBox(height: 9),
            _buildCompactContactRow(
              Icons.location_on_outlined,
              _address,
            ),
          ],
        ],
      ),
    );
  }

  // STATUS BADGE

  Widget _buildStatusBadge() {
    final active = _isActive;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: active
            ? successBg
            : dangerBg,
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
              color: active
                  ? successGreen
                  : dangerRed,
            ),
          ),

          const SizedBox(width: 5),

          Text(
            active
                ? 'Hoạt động'
                : 'Tạm khóa',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: active
                  ? successGreen
                  : dangerRed,
            ),
          ),
        ],
      ),
    );
  }

  // COMPACT CONTACT ROW

  Widget _buildCompactContactRow(
    IconData icon,
    String text,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          width: 29,
          height: 29,
          decoration: BoxDecoration(
            color: softBlue,
            borderRadius:
                BorderRadius.circular(9),
          ),
          child: Icon(
            icon,
            size: 15,
            color: primary,
          ),
        ),

        const SizedBox(width: 9),

        Expanded(
          child: Padding(
            padding:
                const EdgeInsets.only(top: 5),
            child: Text(
              text,
              maxLines: 2,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // COMPANY INFORMATION

  Widget _buildCompanyInformationCard() {
    return _buildCard(
      title: _isEditing
          ? 'Chỉnh sửa thông tin'
          : 'Thông tin chi tiết',
      icon: Icons.business_outlined,
      trailing: !_isEditing
          ? _buildSmallActionButton(
              icon: Icons.edit_outlined,
              label: 'Chỉnh sửa',
              onTap: _startEditing,
            )
          : null,
      child: _isEditing
          ? _buildEditFields()
          : _buildCompanyInfoRows(),
    );
  }

  // EDIT FIELDS

  Widget _buildEditFields() {
    return Column(
      children: [
        _buildTextField(
          controller: _nameController,
          label: 'Tên công ty',
          icon: Icons.business_outlined,
          required: true,
        ),

        const SizedBox(height: 12),

        _buildTextField(
          controller: _codeController,
          label: 'Mã công ty',
          icon: Icons.tag_rounded,
          required: true,
        ),

        const SizedBox(height: 12),

        _buildTextField(
          controller: _addressController,
          label: 'Địa chỉ',
          icon: Icons.location_on_outlined,
          maxLines: 2,
        ),

        const SizedBox(height: 12),

        _buildTextField(
          controller: _emailController,
          label: 'Email liên hệ',
          icon: Icons.email_outlined,
          keyboardType:
              TextInputType.emailAddress,
          required: true,
        ),

        const SizedBox(height: 12),

        _buildTextField(
          controller: _phoneController,
          label: 'Số điện thoại',
          icon: Icons.phone_outlined,
          keyboardType:
              TextInputType.phone,
        ),
      ],
    );
  }

  // COMPANY INFO ROWS

  Widget _buildCompanyInfoRows() {
    return Column(
      children: [
        _buildInfoRow(
          icon: Icons.business_outlined,
          label: 'Tên công ty',
          value: _companyName,
        ),

        _buildDivider(),

        _buildInfoRow(
          icon: Icons.tag_rounded,
          label: 'Mã công ty',
          value: _companyCode.isEmpty
              ? 'Chưa có'
              : _companyCode,
        ),

        _buildDivider(),

        _buildInfoRow(
          icon: Icons.location_on_outlined,
          label: 'Địa chỉ',
          value: _address.trim().isEmpty
              ? 'Chưa có'
              : _address,
        ),

        _buildDivider(),

        _buildInfoRow(
          icon: Icons.email_outlined,
          label: 'Email liên hệ',
          value: _contactEmail.isEmpty
              ? 'Chưa có'
              : _contactEmail,
        ),

        _buildDivider(),

        _buildInfoRow(
          icon: Icons.phone_outlined,
          label: 'Số điện thoại',
          value: _contactPhone.isEmpty
              ? 'Chưa có'
              : _contactPhone,
        ),
      ],
    );
  }

  // ADMIN SECURITY

  Widget _buildAdminSecurityCard() {
    return _buildCard(
      title: 'Tài khoản quản trị',
      icon: Icons.admin_panel_settings_outlined,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          Container(
            padding:
                const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: softBlue,
              borderRadius:
                  BorderRadius.circular(14),
              border: Border.all(
                color: border,
              ),
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius:
                        BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: primary,
                    size: 18,
                  ),
                ),

                const SizedBox(width: 10),

                const Expanded(
                  child: Text(
                    'Bạn có thể tạo mật khẩu mới cho '
                    'tài khoản Admin. Mật khẩu mới sẽ '
                    'được gửi đến email liên hệ của công ty.',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 12.5,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding:
                const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: background,
              borderRadius:
                  BorderRadius.circular(14),
              border: Border.all(
                color: border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: softBlue,
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.email_outlined,
                    color: primary,
                    size: 18,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Email nhận mật khẩu',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 10.5,
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        _contactEmail.isEmpty
                            ? 'Chưa có email liên hệ'
                            : _contactEmail,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textPrimary,
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 46,
            child: OutlinedButton.icon(
              onPressed:
                  _isSendingPassword
                      ? null
                      : _resetAdminPassword,
              icon: _isSendingPassword
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primary,
                      ),
                    )
                  : const Icon(
                      Icons.lock_reset_rounded,
                      size: 18,
                    ),
              label: Text(
                _isSendingPassword
                    ? 'Đang gửi mật khẩu...'
                    : 'Gửi mật khẩu mới cho Admin',
              ),
              style:
                  OutlinedButton.styleFrom(
                foregroundColor: primary,
                side: const BorderSide(
                  color: border,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // OTHER INFORMATION

  Widget _buildOtherInformationCard() {
    return _buildCard(
      title: 'Thông tin khác',
      icon: Icons.info_outline_rounded,
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.circle_outlined,
            label: 'Trạng thái',
            valueWidget:
                _buildStatusBadge(),
          ),

          _buildDivider(),

          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Ngày tạo',
            value:
                _formatDate(company['createdAt']),
          ),
        ],
      ),
    );
  }

  // STATUS ACTION

  Widget _buildStatusAction() {
    final active = _isActive;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: active
              ? const Color(0xFFFFD2D8)
              : const Color(0xFFC8EBD8),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: active
                  ? dangerBg
                  : successBg,
              borderRadius:
                  BorderRadius.circular(11),
            ),
            child: Icon(
              active
                  ? Icons.lock_outline_rounded
                  : Icons.lock_open_rounded,
              size: 20,
              color: active
                  ? dangerRed
                  : successGreen,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  active
                      ? 'Trạng thái tài khoản'
                      : 'Công ty đang tạm khóa',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w700,
                    color: textPrimary,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  active
                      ? 'Công ty hiện có thể đăng nhập và sử dụng hệ thống.'
                      : 'Công ty hiện không thể đăng nhập vào hệ thống.',
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    height: 1.35,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          OutlinedButton.icon(
            onPressed:
                _isChangingStatus
                    ? null
                    : _changeCompanyStatus,
            icon: _isChangingStatus
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    active
                        ? Icons.lock_outline_rounded
                        : Icons.lock_open_rounded,
                    size: 16,
                  ),
            label: Text(
              active
                  ? 'Tạm khóa'
                  : 'Mở khóa',
            ),
            style:
                OutlinedButton.styleFrom(
              foregroundColor: active
                  ? dangerRed
                  : successGreen,
              side: BorderSide(
                color: active
                    ? const Color(
                        0xFFFFC5CC,
                      )
                    : const Color(
                        0xFFB9E5CC,
                      ),
              ),
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 9,
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(11),
              ),
              textStyle: const TextStyle(
                fontSize: 11,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // EDIT ACTIONS

  Widget _buildEditActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed:
                _isSaving
                    ? null
                    : _cancelEditing,
            style:
                OutlinedButton.styleFrom(
              minimumSize:
                  const Size.fromHeight(48),
              foregroundColor:
                  textSecondary,
              side: const BorderSide(
                color: border,
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(13),
              ),
            ),
            child: const Text(
              'Hủy',
              style: TextStyle(
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: ElevatedButton.icon(
            onPressed:
                _isSaving
                    ? null
                    : _saveChanges,
            style:
                ElevatedButton.styleFrom(
              minimumSize:
                  const Size.fromHeight(48),
              backgroundColor: primary,
              foregroundColor:
                  Colors.white,
              elevation: 0,
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(13),
              ),
            ),
            icon: _isSaving
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.save_rounded,
                    size: 18,
                  ),
            label: Text(
              _isSaving
                  ? 'Đang lưu...'
                  : 'Lưu thay đổi',
              style: const TextStyle(
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // BACK BUTTON

  Widget _buildBackButton() {
    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 15,
        ),
        label: const Text(
          'Quay lại danh sách công ty',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(
            color: border,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(13),
          ),
        ),
      ),
    );
  }

  // CARD

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: card,
        borderRadius:
            BorderRadius.circular(19),
        border: Border.all(
          color: border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: softBlue,
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: primary,
                  size: 19,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
              ),

              if (trailing != null)
                trailing,
            ],
          ),

          const SizedBox(height: 14),

          child,
        ],
      ),
    );
  }

  // SMALL ACTION BUTTON

  Widget _buildSmallActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(10),
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 9,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: softBlue,
          borderRadius:
              BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: primary,
            ),

            const SizedBox(width: 5),

            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight:
                    FontWeight.w700,
                color: primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // INFO ROW

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    String? value,
    Widget? valueWidget,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: background,
              borderRadius:
                  BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              size: 15,
              color: primary,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: textSecondary,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 3),

                valueWidget ??
                    Text(
                      value ?? '',
                      style:
                          const TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w700,
                        color: textPrimary,
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

  // DIVIDER

  Widget _buildDivider() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Container(
        height: 1,
        color: const Color(0xFFE5ECFA),
      ),
    );
  }

  // TEXT FIELD

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool required = false,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 13,
        color: textPrimary,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText:
            required ? '$label *' : label,
        labelStyle: const TextStyle(
          fontSize: 12,
          color: textSecondary,
        ),
        prefixIcon: Icon(
          icon,
          size: 19,
          color: primary,
        ),
        filled: true,
        fillColor: background,

        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 13,
        ),

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide:
              const BorderSide(
            color: border,
          ),
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide:
              const BorderSide(
            color: border,
          ),
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide:
              const BorderSide(
            color: primary,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}
