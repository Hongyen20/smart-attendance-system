import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_state.dart';

import 'employee_list_screen.dart';
import 'ip_config_screen.dart';
import 'change_password_screen.dart';
import 'leave_approval_screen.dart';
import 'shift_change_approval_screen.dart';
import 'face_management_screen.dart';
import 'login_screen.dart';
import 'attendance_report_screen.dart';
import 'admin_home_screen.dart';

class BusinessTripApprovalScreen extends StatefulWidget {
  const BusinessTripApprovalScreen({super.key});

  @override
  State<BusinessTripApprovalScreen> createState() =>
      _BusinessTripApprovalScreenState();
}

const Color _navy = Color(0xFF0D2858);
const Color _blue = Color(0xFF246BDE);
const Color _bg = Color(0xFFF3F8FF);
const Color _border = Color(0xFFE2EAF7);
const Color _text = Color(0xFF183153);
const Color _muted = Color(0xFF71819A);
const Color _brightBlue = Color(0xFF2864E8);
const Color _red = Color(0xFFD94343);
const Color _textBlue = Color(0xFF31589D);

class _BusinessTripApprovalScreenState
    extends State<BusinessTripApprovalScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final ScrollController _tableHorizontalController = ScrollController();

  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  @override
  void dispose() {
    _tableHorizontalController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService.getList(
      '/api/business-trip-requests/pending',
      bearerToken: AuthState.instance.token,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;

      if (result.success) {
        _requests = result.data ?? [];
      } else {
        _errorMessage =
            result.errorMessage ?? 'Không thể tải danh sách yêu cầu.';
      }
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    try {
      return DateTime.parse(value.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  Future<void> _approveRequest(Map<String, dynamic> request) async {
    final id = request['id']?.toString();

    if (id == null || id.isEmpty) {
      _showMessage('Không xác định được yêu cầu.');
      return;
    }

    final employee = _employeeName(request);

    final confirmed = await _showConfirmDialog(
      title: 'Duyệt yêu cầu công tác',
      message: 'Bạn có chắc muốn duyệt yêu cầu đi công tác của $employee?',
      confirmText: 'Duyệt yêu cầu',
      confirmColor: const Color(0xFF15966A),
    );

    if (!confirmed) return;

    await _updateRequestStatus(
      id: id,
      action: 'approve',
      successMessage: 'Đã duyệt yêu cầu đi công tác.',
    );
  }

  Future<void> _rejectRequest(Map<String, dynamic> request) async {
    final id = request['id']?.toString();

    if (id == null || id.isEmpty) {
      _showMessage('Không xác định được yêu cầu.');
      return;
    }

    final employee = _employeeName(request);

    final confirmed = await _showConfirmDialog(
      title: 'Từ chối yêu cầu công tác',
      message: 'Bạn có chắc muốn từ chối yêu cầu đi công tác của $employee?',
      confirmText: 'Từ chối yêu cầu',
      confirmColor: const Color(0xFFD94343),
    );

    if (!confirmed) return;

    await _updateRequestStatus(
      id: id,
      action: 'reject',
      successMessage: 'Đã từ chối yêu cầu đi công tác.',
    );
  }

  Future<void> _updateRequestStatus({
    required String id,
    required String action,
    required String successMessage,
  }) async {
    final result = await ApiService.put(
      '/api/business-trip-requests/$id/$action',
      {},
      bearerToken: AuthState.instance.token,
    );

    if (!mounted) return;

    if (result.success) {
      _showMessage(successMessage);
      await _loadRequests();
    } else {
      _showMessage(
        result.errorMessage ?? 'Không thể cập nhật yêu cầu.',
      );
    }
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: _text,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: _muted,
              height: 1.5,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: confirmColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _employeeName(Map<String, dynamic> request) {
    final name = request['employeeName']?.toString().trim();

    if (name != null && name.isNotEmpty) {
      return name;
    }

    final username = request['employeeUsername']?.toString().trim();

    if (username != null && username.isNotEmpty) {
      return username;
    }

    return 'nhân viên này';
  }

  void _push(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Đăng xuất',
            style: TextStyle(
              color: _text,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Bạn có chắc chắn muốn đăng xuất không?',
            style: TextStyle(color: _muted),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                'Đăng xuất',
                style: TextStyle(
                  color: _red,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    _logout();
  }

  void _logout() {
    AuthState.instance.clear();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1000;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bg,
      drawer: isDesktop
          ? null
          : Drawer(
              width: 270,
              child: _buildSidebar(),
            ),
      body: SafeArea(
        child: Row(
          children: [
            if (isDesktop)
              SizedBox(
                width: 260,
                child: _buildSidebar(),
              ),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadRequests,
                      child: _buildMainContent(isDesktop),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // SIDEBAR

  Widget _buildSidebar() {
    return Container(
      color: _navy,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 18, 28),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AttendGo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Smart Attendance System',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFFB8C9E5),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _navItem(
                  icon: Icons.home_rounded,
                  title: 'Trang chủ',
                  onTap: () => _push(const AdminHomeScreen()),
                ),
                const SizedBox(height: 8),
                _navSection(
                  icon: Icons.groups_rounded,
                  title: 'Nhân viên',
                  children: [
                    _navSubItem(
                      title: 'Danh sách nhân viên',
                      onTap: () => _push(const EmployeeListScreen()),
                    ),
                    _navSubItem(
                      title: 'Thêm khuôn mặt chấm công',
                      onTap: () => _push(
                        const FaceManagementScreen(),
                      ),
                    ),
                  ],
                ),
                _navSection(
                  icon: Icons.access_time_rounded,
                  title: 'Chấm công',
                  children: [
                    _navSubItem(
                      title: 'Cấu hình WiFi & GPS',
                      onTap: () => _push(const IpConfigScreen()),
                    ),
                  ],
                ),
                _navItem(
                  icon: Icons.bar_chart_rounded,
                  title: 'Báo cáo',
                  onTap: () => _push(
                    const AttendanceReportScreen(),
                  ),
                ),
                const SizedBox(height: 8),
                _navSection(
                  icon: Icons.assignment_rounded,
                  title: 'Yêu cầu',
                  initiallyExpanded: true,
                  children: [
                    _navSubItem(
                      title: 'Đổi ca',
                      onTap: () => _push(
                        const ShiftChangeApprovalScreen(),
                      ),
                    ),
                    _navSubItem(
                      title: 'Nghỉ phép',
                      onTap: () => _push(
                        const LeaveApprovalScreen(),
                      ),
                    ),
                    _navSubItem(
                      title: 'Công tác',
                      selected: true,
                      onTap: () {
                        if (MediaQuery.sizeOf(context).width < 1000) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
            child: Column(
              children: [
                const Divider(
                  color: Color(0xFF29436D),
                ),
                _navItem(
                  icon: Icons.lock_outline_rounded,
                  title: 'Đổi mật khẩu',
                  onTap: () => _push(
                    const ChangePasswordScreen(),
                  ),
                ),
                _navItem(
                  icon: Icons.logout_rounded,
                  title: 'Đăng xuất',
                  iconColor: const Color(0xFFFFB4B4),
                  onTap: _confirmLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 19,
                color: iconColor ?? const Color(0xFFBFD5F5),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFD0DDF1),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
    bool initiallyExpanded = false,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: Colors.white.withOpacity(0.05),
        highlightColor: Colors.white.withOpacity(0.04),
      ),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.only(
          left: 12,
          bottom: 6,
        ),
        iconColor: const Color(0xFFBFD5F5),
        collapsedIconColor: const Color(0xFF7894BD),
        leading: Icon(
          icon,
          size: 19,
          color: const Color(0xFFBFD5F5),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFFD0DDF1),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        children: children,
      ),
    );
  }

  Widget _navSubItem({
    required String title,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        right: 4,
        bottom: 3,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: onTap,
          child: Container(
            height: 38,
            padding: const EdgeInsets.only(
              left: 34,
              right: 10,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF246BDE)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? Colors.white
                        : const Color(0xFF7894BD),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : const Color(0xFFBFD0E8),
                      fontSize: 11.5,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserMenu(bool showName) {
    final name = (AuthState.instance.fullName ?? '').trim();
    final avatarUrl = (AuthState.instance.avatarUrl ?? '').trim();

    String initials() {
      final parts = name
          .split(RegExp(r'\s+'))
          .where((p) => p.isNotEmpty)
          .toList();

      if (parts.isEmpty) return 'AD';

      if (parts.length == 1) {
        return parts.first
            .substring(0, 1)
            .toUpperCase();
      }

      return (
        parts.first.substring(0, 1) +
        parts.last.substring(0, 1)
      ).toUpperCase();
    }

    Widget initialAvatar() {
      return Center(
        child: Text(
          initials(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    final avatar = Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        color: _brightBlue,
        shape: BoxShape.circle,
      ),
      child: avatarUrl.isNotEmpty
          ? ClipOval(
              child: Image.network(
                avatarUrl,
                width: 42,
                height: 42,
                fit: BoxFit.cover,
                errorBuilder: (
                  context,
                  error,
                  stackTrace,
                ) =>
                    initialAvatar(),
              ),
            )
          : initialAvatar(),
    );

    return PopupMenuButton<String>(
      tooltip: '',
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      onSelected: (value) {
        if (value == 'password') {
          _push(const ChangePasswordScreen());
        } else if (value == 'logout') {
          _confirmLogout();
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem<String>(
          value: 'password',
          child: Row(
            children: [
              Icon(
                Icons.lock_rounded,
                size: 20,
                color: _textBlue,
              ),
              SizedBox(width: 10),
              Text('Đổi mật khẩu'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(
                Icons.logout_rounded,
                size: 20,
                color: Color(0xFFE03131),
              ),
              SizedBox(width: 10),
              Text(
                'Đăng xuất',
                style: TextStyle(
                  color: Color(0xFFE03131),
                ),
              ),
            ],
          ),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          avatar,
          if (showName) ...[
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 140,
              ),
              child: Text(
                name.isEmpty ? 'Admin' : name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const Icon(
            Icons.keyboard_arrow_down,
            color: _navy,
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(bool isDesktop) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(
        isDesktop ? 28 : 16,
      ),
      children: [
        _buildPageIntro(isDesktop),
        const SizedBox(height: 22),
        _buildSummaryCard(),
        const SizedBox(height: 18),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.only(top: 70),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else if (_errorMessage != null)
          _buildErrorState()
        else if (_requests.isEmpty)
          _buildEmptyState()
        else if (isDesktop)
          _buildDesktopTable()
        else
          ..._requests.asMap().entries.map((entry) {
            final request =
                Map<String, dynamic>.from(
              entry.value as Map,
            );

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildRequestCard(request),
            );
          }),
      ],
    );
  }

  Widget _buildPageIntro(bool isDesktop) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: isDesktop ? 54 : 46,
          height: isDesktop ? 54 : 46,
          decoration: BoxDecoration(
            color: const Color(0xFFE4EEFF),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.flight_takeoff_rounded,
            color: _blue,
            size: 27,
          ),
        ),
        const SizedBox(width: 15),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Yêu cầu đi công tác',
                style: TextStyle(
                  color: _text,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Xem thông tin và duyệt hoặc từ chối yêu cầu của nhân viên.',
                style: TextStyle(
                  color: _muted,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _buildUserMenu(isDesktop),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 17,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFEAF3FF),
            Color(0xFFF7FAFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFFDCE8FB),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFD7E7FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.pending_actions_rounded,
              color: _blue,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yêu cầu đang chờ duyệt',
                  style: TextStyle(
                    color: _text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Các yêu cầu công tác chưa được xử lý',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${_requests.length}',
            style: const TextStyle(
              color: _blue,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080D2858),
            blurRadius: 18,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Scrollbar(
          controller: _tableHorizontalController,
          thumbVisibility: true,
          trackVisibility: true,
          thickness: 8,
          radius: const Radius.circular(10),
          child: SingleChildScrollView(
            controller: _tableHorizontalController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 10),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                const Color(0xFFF3F7FD),
              ),
              dataRowMinHeight: 76,
              dataRowMaxHeight: 100,
              headingTextStyle: const TextStyle(
                color: _muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              dataTextStyle: const TextStyle(
                color: _text,
                fontSize: 12,
              ),
              columnSpacing: 26,
              horizontalMargin: 22,
              columns: const [
                DataColumn(
                  label: SizedBox(
                    width: 28,
                    child: Text('STT'),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 170,
                    child: Text('NHÂN VIÊN'),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 100,
                    child: Text('THỜI GIAN ĐI'),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 100,
                    child: Text('THỜI GIAN VỀ'),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 140,
                    child: Text('ĐỊA ĐIỂM'),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 175,
                    child: Text('LÝ DO'),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 190,
                    child: Text('THAO TÁC'),
                  ),
                ),
              ],
              rows: _requests.asMap().entries.map((entry) {
                final index = entry.key;

                final request =
                    Map<String, dynamic>.from(
                  entry.value as Map,
                );

                return DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: _muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      _employeeCell(request),
                    ),
                    DataCell(
                      _dateCell(request['startDate']),
                    ),
                    DataCell(
                      _dateCell(request['endDate']),
                    ),
                    DataCell(
                      SizedBox(
                        width: 140,
                        child: Text(
                          _stringValue(
                            request['destination'],
                            'Chưa cập nhật',
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 175,
                        child: Text(
                          _stringValue(
                            request['reason'],
                            'Không có lý do',
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 190,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ActionButton(
                              label: 'Duyệt',
                              icon: Icons.check_rounded,
                              color: const Color(0xFF15966A),
                              onPressed: () =>
                                  _approveRequest(request),
                            ),
                            const SizedBox(width: 8),
                            _ActionButton(
                              label: 'Từ chối',
                              icon: Icons.close_rounded,
                              color: const Color(0xFFD94343),
                              outlined: true,
                              onPressed: () =>
                                  _rejectRequest(request),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _employeeCell(
    Map<String, dynamic> request,
  ) {
    final name = _employeeName(request);
    final username =
        request['employeeUsername']?.toString().trim() ?? '';

    return SizedBox(
      width: 170,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _text,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          if (username.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '@$username',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _muted,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dateCell(dynamic value) {
    final date = _parseDate(value);

    if (date == null) {
      return const Text('Không xác định');
    }

    return SizedBox(
      width: 100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_formatDate(date)),
          const SizedBox(height: 4),
          Text(
            '${date.hour.toString().padLeft(2, '0')}:'
            '${date.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(
              color: _muted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(
    Map<String, dynamic> request,
  ) {
    final startDate =
        _parseDate(request['startDate']);
    final endDate =
        _parseDate(request['endDate']);

    final destination = _stringValue(
      request['destination'],
      'Chưa cập nhật',
    );

    final reason = _stringValue(
      request['reason'],
      'Không có lý do',
    );

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _employeeName(request),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          _infoRow(
            Icons.calendar_month_outlined,
            'Thời gian',
            '${startDate == null ? 'Không xác định' : _formatDate(startDate)}'
                ' – '
                '${endDate == null ? 'Không xác định' : _formatDate(endDate)}',
          ),
          const SizedBox(height: 10),
          _infoRow(
            Icons.location_on_outlined,
            'Địa điểm',
            destination,
          ),
          const SizedBox(height: 10),
          _infoRow(
            Icons.notes_rounded,
            'Lý do',
            reason,
          ),
          const SizedBox(height: 16),
          const Divider(
            color: _border,
            height: 1,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Từ chối',
                  icon: Icons.close_rounded,
                  color: const Color(0xFFD94343),
                  outlined: true,
                  expand: true,
                  onPressed: () =>
                      _rejectRequest(request),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  label: 'Duyệt',
                  icon: Icons.check_rounded,
                  color: const Color(0xFF15966A),
                  expand: true,
                  onPressed: () =>
                      _approveRequest(request),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: _muted,
          size: 17,
        ),
        const SizedBox(width: 9),
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: _text,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  String _stringValue(
    dynamic value,
    String fallback,
  ) {
    final text = value?.toString().trim();

    return text == null || text.isEmpty
        ? fallback
        : text;
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 58,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.task_alt_rounded,
            size: 52,
            color: Color(0xFF91A4C0),
          ),
          SizedBox(height: 14),
          Text(
            'Không có yêu cầu công tác đang chờ duyệt',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Các yêu cầu mới sẽ xuất hiện tại đây.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFF4CACA),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 42,
            color: Color(0xFFD94343),
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? 'Đã xảy ra lỗi.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _text,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loadRequests,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label: const Text('Thử lại'),
            style: FilledButton.styleFrom(
              backgroundColor: _blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.outlined = false,
    this.expand = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool outlined;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = outlined
        ? OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(
              icon,
              size: 16,
            ),
            label: Text(label),
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(
                color: color.withOpacity(0.55),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
              textStyle: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        : FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(
              icon,
              size: 16,
            ),
            label: Text(label),
            style: FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
              textStyle: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          );

    return expand
        ? SizedBox(
            width: double.infinity,
            child: button,
          )
        : button;
  }
}
