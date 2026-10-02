import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_state.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final String employeeId;

  const EmployeeDetailScreen({super.key, required this.employeeId});

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isResettingPassword = false;
  bool _isChangingStatus = false;

  String? _errorMessage;

  Map<String, dynamic>? _employee;

  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadEmployee();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // LOAD EMPLOYEE

  Future<void> _loadEmployee() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService.get(
      '/api/employees/${widget.employeeId}',
      bearerToken: AuthState.instance.token,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;

      if (result.success) {
        _employee = Map<String, dynamic>.from(result.data!);

        _fullNameController.text = (_employee!['fullName'] ?? '').toString();

        _usernameController.text = (_employee!['username'] ?? '').toString();

        _emailController.text = (_employee!['email'] ?? '').toString();

        _phoneController.text = (_employee!['phone'] ?? '').toString();
      } else {
        _errorMessage = result.errorMessage;
      }
    });
  }

  // SAVE

  Future<void> _handleSave() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final result = await ApiService.put('/api/employees/${widget.employeeId}', {
      'fullName': _fullNameController.text.trim(),
      'username': _usernameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'annualLeaveDays': _employee?['annualLeaveDays'] ?? 12,
    }, bearerToken: AuthState.instance.token);

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (result.success) {
      setState(() {
        _employee = Map<String, dynamic>.from(result.data!);
        _hasChanges = true;
      });

      _showSnackBar(
        'Đã lưu thông tin nhân viên.',
        backgroundColor: const Color(0xFF16A34A),
        icon: Icons.check_circle_outline,
      );
    } else {
      setState(() {
        _errorMessage = result.errorMessage;
      });
    }
  }

  // RESET PASSWORD

  Future<void> _handleResetPassword() async {
    final email = (_employee?['email'] ?? '').toString();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Cấp lại mật khẩu?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF202A3D),
            ),
          ),
          content: Text(
            'Hệ thống sẽ sinh mật khẩu mới và gửi qua email '
            '($email).\n\n'
            'Mật khẩu cũ sẽ không còn sử dụng được.',
            style: const TextStyle(
              fontSize: 14,
              height: 1.55,
              color: Color(0xFF737D92),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Hủy',
                style: TextStyle(
                  color: Color(0xFF737D92),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2864E8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Cấp lại',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isResettingPassword = true;
    });

    final result = await ApiService.post(
      '/api/employees/${widget.employeeId}/reset-password',
      {},
      bearerToken: AuthState.instance.token,
    );

    if (!mounted) return;

    setState(() {
      _isResettingPassword = false;
    });

    if (result.success) {
      final emailSent = result.data?['emailSent'] == true;

      _showSnackBar(
        emailSent
            ? 'Đã cấp lại mật khẩu và gửi email thành công.'
            : 'Đã cấp lại mật khẩu nhưng gửi email thất bại.',
        backgroundColor: emailSent
            ? const Color(0xFF16A34A)
            : const Color(0xFF64748B),
        icon: emailSent
            ? Icons.mark_email_read_outlined
            : Icons.warning_amber_rounded,
      );
    } else {
      _showSnackBar(
        result.errorMessage ?? 'Cấp lại mật khẩu thất bại.',
        backgroundColor: const Color(0xFFE53935),
        icon: Icons.error_outline,
      );
    }
  }

  // LOCK / UNLOCK

  bool get _isActive {
    final status = (_employee?['status'] ?? '').toString();

    return status.toLowerCase() == 'active';
  }

  Future<void> _handleChangeStatus() async {
    final currentlyActive = _isActive;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            currentlyActive ? 'Khóa nhân viên?' : 'Mở khóa nhân viên?',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF202A3D),
            ),
          ),
          content: Text(
            currentlyActive
                ? 'Nhân viên sẽ không thể đăng nhập và thực hiện '
                      'các thao tác trên hệ thống.\n\n'
                      'Dữ liệu nhân viên và lịch sử chấm công vẫn được giữ lại.'
                : 'Nhân viên sẽ được phép đăng nhập và sử dụng '
                      'hệ thống trở lại.',
            style: const TextStyle(
              fontSize: 14,
              height: 1.55,
              color: Color(0xFF737D92),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Hủy',
                style: TextStyle(
                  color: Color(0xFF737D92),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: currentlyActive
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF16A34A),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                currentlyActive ? 'Khóa nhân viên' : 'Mở khóa',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isChangingStatus = true;
    });

    final newStatus = currentlyActive ? 'Inactive' : 'Active';

    final result = await ApiService.put(
      '/api/employees/${widget.employeeId}/status',
      {'status': newStatus},
      bearerToken: AuthState.instance.token,
    );

    if (!mounted) return;

    setState(() {
      _isChangingStatus = false;
    });

    if (result.success) {
      setState(() {
        _employee = Map<String, dynamic>.from(result.data!);
        _hasChanges = true;
      });

      _showSnackBar(
        currentlyActive ? 'Đã khóa nhân viên.' : 'Đã mở khóa nhân viên.',
        backgroundColor: currentlyActive
            ? const Color(0xFFEF4444)
            : const Color(0xFF16A34A),
        icon: currentlyActive
            ? Icons.lock_outline_rounded
            : Icons.lock_open_outlined,
      );
    } else {
      _showSnackBar(
        result.errorMessage ?? 'Không thể thay đổi trạng thái nhân viên.',
        backgroundColor: const Color(0xFFE53935),
        icon: Icons.error_outline,
      );
    }
  }

  // SNACKBAR

  void _showSnackBar(
    String message, {
    required Color backgroundColor,
    required IconData icon,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 21),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        Navigator.pop(context, _hasChanges);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F7FF),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? _buildLoading()
                    : _employee == null
                    ? _buildErrorState()
                    : _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // HEADER

  Widget _buildHeader() {
    return Container(
      height: 76,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2EAF7))),
      ),
      child: Row(
        children: [
          Material(
            color: const Color(0xFFEAF0FF),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                Navigator.pop(context, _hasChanges);
              },
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF244397),
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Chi tiết nhân viên',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF244397),
            ),
          ),
          const Spacer(),
          if (_employee != null) _buildStatusChip(),
        ],
      ),
    );
  }

  // CONTENT

  Widget _buildContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 950;

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            isDesktop ? 34 : 18,
            24,
            isDesktop ? 34 : 18,
            34,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1450),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEmployeeHeader(),

                  const SizedBox(height: 20),

                  if (isDesktop) _buildDesktopBody() else _buildMobileBody(),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    _buildErrorMessage(),
                  ],

                  const SizedBox(height: 20),

                  _buildBottomActions(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // EMPLOYEE HEADER

  Widget _buildEmployeeHeader() {
    final fullName = (_employee?['fullName'] ?? '').toString();

    final username = (_employee?['username'] ?? '').toString();

    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';

    final employeeId = (_employee?['id'] ?? widget.employeeId).toString();

    final hasFace = _employee?['hasFace'] == true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE7F8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF53689E).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: const BoxDecoration(
              color: Color(0xFFE5EFFF),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Color(0xFF2454B8),
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          const SizedBox(width: 20),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName.isEmpty ? 'Không rõ tên' : fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF183B80),
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  '@$username',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6D7FA2),
                  ),
                ),

                const SizedBox(height: 13),

                Wrap(
                  spacing: 18,
                  runSpacing: 8,
                  children: [
                    _buildMiniInfo(
                      icon: Icons.badge_outlined,
                      text: employeeId,
                    ),
                    _buildMiniInfo(
                      icon: hasFace
                          ? Icons.face_retouching_natural
                          : Icons.face_retouching_off,
                      text: hasFace ? 'Đã có khuôn mặt' : 'Chưa có khuôn mặt',
                      color: hasFace
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF718096),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          _buildStatusChip(),
        ],
      ),
    );
  }

  Widget _buildMiniInfo({
    required IconData icon,
    required String text,
    Color color = const Color(0xFF31589D),
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // STATUS

  Widget _buildStatusChip() {
    final active = _isActive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE7F9EF) : const Color(0xFFFFE9EA),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: active ? const Color(0xFFB9EBCF) : const Color(0xFFFFC8CB),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: active ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            active ? 'Đang làm việc' : 'Đã khóa',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: active ? const Color(0xFF138A3F) : const Color(0xFFD9363E),
            ),
          ),
        ],
      ),
    );
  }

  // DESKTOP BODY

  Widget _buildDesktopBody() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 7, child: _buildPersonalInfoCard()),
        const SizedBox(width: 20),
        Expanded(flex: 4, child: _buildAccountCard()),
      ],
    );
  }

  // MOBILE BODY

  Widget _buildMobileBody() {
    return Column(
      children: [
        _buildPersonalInfoCard(),
        const SizedBox(height: 16),
        _buildAccountCard(),
      ],
    );
  }

  // PERSONAL INFORMATION

  Widget _buildPersonalInfoCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.person_outline_rounded,
            title: 'Thông tin cá nhân',
            subtitle: 'Thông tin cơ bản của nhân viên',
          ),

          const SizedBox(height: 24),

          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 650;

              if (twoColumns) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _fullNameController,
                            label: 'Họ tên',
                            icon: Icons.person_outline,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: _buildTextField(
                            controller: _usernameController,
                            label: 'Tên đăng nhập',
                            icon: Icons.account_circle_outlined,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: _buildTextField(
                            controller: _phoneController,
                            label: 'Số điện thoại',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    _buildAdditionalInfo(),
                  ],
                );
              }

              return Column(
                children: [
                  _buildTextField(
                    controller: _fullNameController,
                    label: 'Họ tên',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 18),
                  _buildTextField(
                    controller: _usernameController,
                    label: 'Tên đăng nhập',
                    icon: Icons.account_circle_outlined,
                  ),
                  const SizedBox(height: 18),
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 18),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Số điện thoại',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 22),
                  _buildAdditionalInfo(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ADDITIONAL INFORMATION

  Widget _buildAdditionalInfo() {
    final role = (_employee?['role'] ?? 'Employee').toString();

    final leaveDays = (_employee?['annualLeaveDays'] ?? 0).toString();

    final shiftType = (_employee?['currentShiftType'] ?? '').toString();

    final shiftStart = (_employee?['currentShiftStart'] ?? '').toString();

    final shiftEnd = (_employee?['currentShiftEnd'] ?? '').toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE5EBF5))),
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 18,
        children: [
          _buildReadOnlyInfo(
            label: 'Vai trò',
            value: role == 'Employee' ? 'Nhân viên' : role,
            icon: Icons.badge_outlined,
          ),
          _buildReadOnlyInfo(
            label: 'Ngày phép năm',
            value: '$leaveDays ngày',
            icon: Icons.calendar_month_outlined,
          ),
          if (shiftType.isNotEmpty)
            _buildReadOnlyInfo(
              label: 'Ca làm việc',
              value: shiftType,
              icon: Icons.access_time_rounded,
            ),
          if (shiftStart.isNotEmpty || shiftEnd.isNotEmpty)
            _buildReadOnlyInfo(
              label: 'Khung giờ',
              value:
                  '${shiftStart.isEmpty ? '--' : shiftStart}'
                  ' - '
                  '${shiftEnd.isEmpty ? '--' : shiftEnd}',
              icon: Icons.schedule_outlined,
            ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyInfo({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return SizedBox(
      width: 210,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: const Color(0xFF6A82B5)),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7B8AA6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF31589D),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ACCOUNT CARD

  Widget _buildAccountCard() {
    final active = _isActive;

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 25),

          _buildAccountAction(
            icon: Icons.key_rounded,
            iconBackground: const Color(0xFFEAF1FF),
            iconColor: const Color(0xFF2864E8),
            title: 'Cấp lại mật khẩu',
            description:
                'Hệ thống sẽ sinh mật khẩu mới và gửi qua email của nhân viên.',
            buttonText: _isResettingPassword
                ? 'Đang gửi...'
                : 'Cấp lại mật khẩu',
            buttonIcon: Icons.email_outlined,
            buttonColor: const Color(0xFF2864E8),
            loading: _isResettingPassword,
            onPressed: _isResettingPassword ? null : _handleResetPassword,
          ),

          const SizedBox(height: 25),

          Container(height: 1, color: const Color(0xFFE6EBF3)),

          const SizedBox(height: 25),

          _buildAccountAction(
            icon: active
                ? Icons.lock_outline_rounded
                : Icons.lock_open_outlined,
            iconBackground: active
                ? const Color(0xFFFFEEEE)
                : const Color(0xFFEAF9F2),
            iconColor: active
                ? const Color(0xFFEF4444)
                : const Color(0xFF16A34A),
            title: active ? 'Khóa nhân viên' : 'Mở khóa nhân viên',
            description: active
                ? 'Nhân viên sẽ không thể đăng nhập hoặc thực hiện thao tác trên hệ thống.'
                : 'Nhân viên sẽ có thể đăng nhập và sử dụng hệ thống trở lại.',
            buttonText: _isChangingStatus
                ? 'Đang xử lý...'
                : active
                ? 'Khóa nhân viên'
                : 'Mở khóa nhân viên',
            buttonIcon: active
                ? Icons.lock_outline_rounded
                : Icons.lock_open_outlined,
            buttonColor: active
                ? const Color(0xFFEF4444)
                : const Color(0xFF16A34A),
            loading: _isChangingStatus,
            onPressed: _isChangingStatus ? null : _handleChangeStatus,
          ),

          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: active ? const Color(0xFFFFF4F4) : const Color(0xFFEAF9F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active
                    ? const Color(0xFFFFD5D5)
                    : const Color(0xFFC6EED8),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  active
                      ? Icons.info_outline_rounded
                      : Icons.check_circle_outline,
                  size: 19,
                  color: active
                      ? const Color(0xFFDC4148)
                      : const Color(0xFF16934A),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    active
                        ? 'Khóa nhân viên không xóa dữ liệu. '
                              'Bạn có thể mở khóa tài khoản bất cứ lúc nào.'
                        : 'Tài khoản đang bị khóa. '
                              'Bạn có thể mở khóa để nhân viên sử dụng lại hệ thống.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: active
                          ? const Color(0xFFD13D44)
                          : const Color(0xFF21844A),
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

  // ACCOUNT ACTION

  Widget _buildAccountAction({
    required IconData icon,
    required Color iconBackground,
    required Color iconColor,
    required String title,
    required String description,
    required String buttonText,
    required IconData buttonIcon,
    required Color buttonColor,
    required VoidCallback? onPressed,
    required bool loading,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 23),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF243B69),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: Color(0xFF7383A0),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 15),

        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: buttonColor,
              side: BorderSide(color: buttonColor, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            child: loading
                ? SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: buttonColor,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(buttonIcon, size: 19, color: buttonColor),
                      const SizedBox(width: 8),
                      Text(
                        buttonText,
                        style: TextStyle(
                          color: buttonColor,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // CARD

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE7F8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF53689E).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  // CARD HEADER

  Widget _buildCardHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF1FF),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: const Color(0xFF2454B8), size: 23),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF243B69),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Color(0xFF7A8BAA)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // TEXT FIELD

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF58709D),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF263A62),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF6B82B1), size: 20),
            filled: true,
            fillColor: const Color(0xFFF8FAFE),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: Color(0xFFD7E3F5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: Color(0xFFD7E3F5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(
                color: Color(0xFF4C75D8),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ERROR MESSAGE

  Widget _buildErrorMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD2D2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFE53935), size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
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

  // BOTTOM ACTIONS

  Widget _buildBottomActions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE7F8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            onPressed: _hasChanges
                ? () {
                    _loadEmployee();
                    setState(() {
                      _hasChanges = false;
                    });
                  }
                : () {
                    Navigator.pop(context, false);
                  },
            icon: const Icon(Icons.refresh_rounded, size: 19),
            label: Text(_hasChanges ? 'Khôi phục' : 'Hủy'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF31589D),
              side: const BorderSide(color: Color(0xFF9BB8E8)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _handleSave,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined, size: 19),
              label: Text(_isSaving ? 'Đang lưu...' : 'Lưu thay đổi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1464E8),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF9DB7E8),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // LOADING

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF244397)),
    );
  }

  // ERROR STATE

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEEE),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Color(0xFFE53935),
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Không thể tải thông tin',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF263A62),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Không tải được thông tin nhân viên.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Color(0xFF737D92),
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _loadEmployee,
              icon: const Icon(Icons.refresh, color: Color(0xFF244397)),
              label: const Text(
                'Thử lại',
                style: TextStyle(
                  color: Color(0xFF244397),
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF244397)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
