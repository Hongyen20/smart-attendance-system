import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/auth_state.dart';

import 'employee_list_screen.dart';
import 'ip_config_screen.dart';
import 'change_password_screen.dart';
import 'leave_approval_screen.dart';
import 'shift_change_approval_screen.dart';
import 'face_management_screen.dart';
import 'business_trip_approval_screen.dart';
import 'login_screen.dart';
import 'attendance_report_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  static const Color _navy = Color(0xFF102A67);
  static const Color _blue = Color(0xFF2864E8);
  static const Color _bg = Color(0xFFF4F7FC);
  static const Color _border = Color(0xFFE3EAF5);
  static const Color _muted = Color(0xFF78869D);
  static const Color _green = Color(0xFF20A875);
  static const Color _red = Color(0xFFE03131);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isLoadingStats = true;
  bool _isLoadingActivities = true;

  int _totalEmployees = 0;
  final int _currentlyWorking = 0;
  final int _pendingLeaveRequests = 0;

  List<dynamic> _recentActivities = [];
  String? _activityError;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadRecentActivities();
  }

  Future<void> _loadStats() async {
    try {
      final result = await ApiService.getList(
        '/api/employees',
        bearerToken: AuthState.instance.token,
      );

      if (!mounted) return;

      setState(() {
        _isLoadingStats = false;

        if (result.success) {
          _totalEmployees = result.data?.length ?? 0;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingStats = false);
      debugPrint('Load employee stats error: $e');
    }
  }

  Future<void> _loadRecentActivities() async {
    if (mounted) {
      setState(() {
        _isLoadingActivities = true;
        _activityError = null;
      });
    }

    try {
      final result = await ApiService.getList(
        '/api/audit-logs/recent?limit=8',
        bearerToken: AuthState.instance.token,
      );

      if (!mounted) return;

      setState(() {
        _isLoadingActivities = false;

        if (result.success) {
          _recentActivities = result.data ?? [];
        } else {
          _activityError =
              result.errorMessage ?? 'Không thể tải hoạt động gần đây.';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingActivities = false;
        _activityError = 'Không thể tải hoạt động gần đây.';
      });

      debugPrint('Load audit logs error: $e');
    }
  }

  void _openScreen(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)).then((
      _,
    ) {
      if (!mounted) return;
      _loadStats();
      _loadRecentActivities();
    });
  }

  void _openFaceManagement() {
    final token = AuthState.instance.token;

    if (token == null || token.isEmpty) {
      _showMessage('Phiên đăng nhập không hợp lệ.');
      return;
    }

    _openScreen(FaceManagementScreen(token: token));
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Đăng xuất',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    AuthState.instance.clear();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 1000;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bg,
      drawer: desktop ? null : Drawer(width: 270, child: _buildSidebar()),
      body: SafeArea(
        child: Row(
          children: [
            if (desktop) SizedBox(width: 260, child: _buildSidebar()),
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(desktop),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        await Future.wait([
                          _loadStats(),
                          _loadRecentActivities(),
                        ]);
                      },
                      child: _buildDashboard(desktop),
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
            padding: const EdgeInsets.fromLTRB(20, 24, 16, 28),
            child: Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    color: Color(0xFF78B9FF),
                    size: 27,
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
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'SMART ATTENDANCE',
                        style: TextStyle(
                          color: Color(0xFFB8C9E5),
                          fontSize: 9,
                          letterSpacing: 1,
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
                  Icons.home_rounded,
                  'Trang chủ',
                  selected: true,
                  onTap: () {
                    if (MediaQuery.sizeOf(context).width < 1000) {
                      Navigator.pop(context);
                    }
                  },
                ),
                const SizedBox(height: 8),
                _navSection(Icons.groups_rounded, 'Nhân viên', [
                  _navChild(
                    'Danh sách nhân viên',
                    () => _openScreen(const EmployeeListScreen()),
                  ),
                  _navChild('Thêm khuôn mặt chấm công', _openFaceManagement),
                ]),
                _navSection(Icons.access_time_rounded, 'Chấm công', [
                  _navChild(
                    'Cấu hình IP & GPS',
                    () => _openScreen(const IpConfigScreen()),
                  ),
                  _navChild(
                    'Báo cáo chấm công',
                    () => _openScreen(const AttendanceReportScreen()),
                  ),
                ]),
                _navSection(Icons.assignment_rounded, 'Yêu cầu', [
                  _navChild(
                    'Đổi ca',
                    () => _openScreen(const ShiftChangeApprovalScreen()),
                  ),
                  _navChild(
                    'Nghỉ phép',
                    () => _openScreen(const LeaveApprovalScreen()),
                  ),
                  _navChild(
                    'Công tác',
                    () => _openScreen(const BusinessTripApprovalScreen()),
                  ),
                ]),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
            child: Column(
              children: [
                const Divider(color: Color(0xFF29436D)),
                _navItem(
                  Icons.lock_outline_rounded,
                  'Đổi mật khẩu',
                  onTap: () => _openScreen(const ChangePasswordScreen()),
                ),
                _navItem(
                  Icons.logout_rounded,
                  'Đăng xuất',
                  onTap: _confirmLogout,
                  iconColor: const Color(0xFFFFB4B4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navSection(IconData icon, String title, List<Widget> children) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.only(left: 12, bottom: 6),
        leading: Icon(icon, color: const Color(0xFFD6E4FA), size: 21),
        iconColor: Colors.white,
        collapsedIconColor: const Color(0xFFBFD5F5),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: children,
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String title, {
    required VoidCallback onTap,
    bool selected = false,
    Color iconColor = const Color(0xFFD6E4FA),
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? _blue : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 21),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
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

  Widget _navChild(String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 5, color: Color(0xFF7894BD)),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFFD0DDF1),
                      fontSize: 12,
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

  // TOP BAR

  Widget _buildTopBar(bool desktop) {
    return Container(
      height: 72,
      padding: EdgeInsets.symmetric(horizontal: desktop ? 28 : 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          if (!desktop) ...[
            IconButton(
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              icon: const Icon(Icons.menu_rounded),
              color: _navy,
            ),
            const SizedBox(width: 4),
          ],
          const Expanded(
            child: Text(
              'Tổng quan',
              style: TextStyle(
                color: _navy,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Làm mới dữ liệu',
            onPressed: () {
              _loadStats();
              _loadRecentActivities();
            },
            icon: const Icon(Icons.refresh_rounded),
            color: _blue,
          ),
          const SizedBox(width: 8),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.admin_panel_settings_rounded, color: _blue),
          ),
          if (desktop) ...[
            const SizedBox(width: 10),
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quản trị viên',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'AttendGo Admin',
                  style: TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }

  // DASHBOARD

  Widget _buildDashboard(bool desktop) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(desktop ? 28 : 16),
      children: [
        _buildWelcomeSection(),
        const SizedBox(height: 22),
        _buildOverviewCard(),
        const SizedBox(height: 24),
        _buildSectionTitle('Quản lý nhân sự', Icons.groups_rounded),
        const SizedBox(height: 12),
        _buildFunctionGrid([
          _FunctionData(
            icon: Icons.groups_rounded,
            title: 'Nhân viên',
            subtitle: 'Danh sách nhân viên',
            color: const Color(0xFF3182F6),
            onTap: () => _openScreen(const EmployeeListScreen()),
          ),
          _FunctionData(
            icon: Icons.face_retouching_natural_rounded,
            title: 'Khuôn mặt',
            subtitle: 'Thêm khuôn mặt chấm công',
            color: const Color(0xFF7C4DFF),
            onTap: _openFaceManagement,
          ),
          _FunctionData(
            icon: Icons.router_rounded,
            title: 'Cấu hình IP & GPS',
            subtitle: 'Thiết lập vị trí chấm công',
            color: const Color(0xFF20A875),
            onTap: () => _openScreen(const IpConfigScreen()),
          ),
        ]),
        const SizedBox(height: 24),
        _buildSectionTitle('Chấm công và yêu cầu', Icons.access_time_rounded),
        const SizedBox(height: 12),
        _buildFunctionGrid([
          _FunctionData(
            icon: Icons.bar_chart_rounded,
            title: 'Báo cáo',
            subtitle: 'Thống kê chấm công',
            color: const Color(0xFF2864E8),
            onTap: () => _openScreen(const AttendanceReportScreen()),
          ),
          _FunctionData(
            icon: Icons.swap_horiz_rounded,
            title: 'Đổi ca',
            subtitle: 'Duyệt yêu cầu đổi ca',
            color: const Color(0xFFFF922B),
            onTap: () => _openScreen(const ShiftChangeApprovalScreen()),
          ),
          _FunctionData(
            icon: Icons.calendar_month_rounded,
            title: 'Nghỉ phép',
            subtitle: 'Duyệt đơn nghỉ phép',
            color: const Color(0xFFF5487F),
            onTap: () => _openScreen(const LeaveApprovalScreen()),
          ),
          _FunctionData(
            icon: Icons.business_center_rounded,
            title: 'Công tác',
            subtitle: 'Duyệt đơn công tác',
            color: const Color(0xFF4A90E2),
            onTap: () => _openScreen(const BusinessTripApprovalScreen()),
          ),
          _FunctionData(
            icon: Icons.lock_rounded,
            title: 'Đổi mật khẩu',
            subtitle: 'Bảo mật tài khoản',
            color: const Color(0xFF7950F2),
            onTap: () => _openScreen(const ChangePasswordScreen()),
          ),
        ]),
        const SizedBox(height: 24),
        _buildRecentActivities(),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: _border),
          ),
          padding: const EdgeInsets.all(5),
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.verified_user_rounded, color: _blue, size: 32),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chào Quản Trị Viên',
                style: TextStyle(
                  color: _navy,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Đây là tổng quan hoạt động của bạn hôm nay.',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEAF3FF), Color(0xFFF7FAFF)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE9FF)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _overviewItem(
              Icons.groups_rounded,
              'Tổng nhân viên',
              _isLoadingStats ? '...' : '$_totalEmployees',
              const Color(0xFF3182F6),
            ),
          ),
          _verticalDivider(),
          Expanded(
            child: _overviewItem(
              Icons.access_time_filled_rounded,
              'Đang làm việc',
              '$_currentlyWorking',
              _green,
            ),
          ),
          _verticalDivider(),
          Expanded(
            child: _overviewItem(
              Icons.event_available_rounded,
              'Chờ duyệt',
              '$_pendingLeaveRequests',
              const Color(0xFFFF922B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _overviewItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.13),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 9),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: const TextStyle(color: _muted, fontSize: 10.5),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 72,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: const Color(0xFFD9E3F4),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _blue, size: 22),
        const SizedBox(width: 9),
        Text(
          title,
          style: const TextStyle(
            color: _navy,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildFunctionGrid(List<_FunctionData> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 4
            : constraints.maxWidth >= 650
            ? 3
            : 2;

        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: items.map((item) {
            return SizedBox(width: width, child: _functionCard(item));
          }).toList(),
        );
      },
    );
  }

  Widget _functionCard(_FunctionData item) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: item.onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 132),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color, size: 24),
              ),
              const SizedBox(height: 13),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                item.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // RECENT AUDIT ACTIVITIES

  Widget _buildRecentActivities() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.history_rounded, color: _blue),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hoạt động gần đây',
                      style: TextStyle(
                        color: _navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Lịch sử thao tác trong công ty',
                      style: TextStyle(color: _muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Làm mới',
                onPressed: _isLoadingActivities ? null : _loadRecentActivities,
                icon: const Icon(Icons.refresh_rounded),
                color: _blue,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingActivities)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_activityError != null)
            _activityMessage(
              Icons.cloud_off_rounded,
              _activityError!,
              retry: true,
            )
          else if (_recentActivities.isEmpty)
            _activityMessage(
              Icons.history_toggle_off_rounded,
              'Chưa có hoạt động nào được ghi nhận.',
            )
          else
            ..._recentActivities.map((item) {
              final log = Map<String, dynamic>.from(item as Map);
              return _buildActivityItem(log);
            }),
        ],
      ),
    );
  }

  Widget _activityMessage(IconData icon, String message, {bool retry = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 36, color: _muted),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
            if (retry)
              TextButton(
                onPressed: _loadRecentActivities,
                child: const Text('Thử lại'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> log) {
    final action = (log['action'] ?? 'Hoạt động').toString();
    final details = (log['details'] ?? '').toString().trim();
    final userId = (log['userId'] ?? '').toString();
    final ip = (log['ipAddress'] ?? '').toString();

    final rawDate = log['createdAt'] ?? log['CreatedAt'];
    final date = DateTime.tryParse((rawDate ?? '').toString())?.toLocal();

    final timeText = date == null
        ? 'Không xác định thời gian'
        : '${date.day.toString().padLeft(2, '0')}/'
              '${date.month.toString().padLeft(2, '0')}/'
              '${date.year} · '
              '${date.hour.toString().padLeft(2, '0')}:'
              '${date.minute.toString().padLeft(2, '0')}';

    final normalized = action.toLowerCase();

    IconData icon = Icons.receipt_long_rounded;
    Color color = _blue;
    Color background = const Color(0xFFEAF2FF);

    if (normalized.contains('login') || normalized.contains('đăng nhập')) {
      icon = Icons.login_rounded;
      color = _green;
      background = const Color(0xFFE3F7EE);
    } else if (normalized.contains('attendance') ||
        normalized.contains('checkin') ||
        normalized.contains('checkout') ||
        normalized.contains('chấm công')) {
      icon = Icons.access_time_rounded;
      color = const Color(0xFF7C4DFF);
      background = const Color(0xFFF1ECFF);
    } else if (normalized.contains('delete') ||
        normalized.contains('reject') ||
        normalized.contains('xóa') ||
        normalized.contains('từ chối')) {
      icon = Icons.warning_amber_rounded;
      color = _red;
      background = const Color(0xFFFFE6E6);
    } else if (normalized.contains('create') ||
        normalized.contains('update') ||
        normalized.contains('approve') ||
        normalized.contains('tạo') ||
        normalized.contains('cập nhật') ||
        normalized.contains('duyệt')) {
      icon = Icons.edit_note_rounded;
      color = const Color(0xFF1686C9);
      background = const Color(0xFFE4F5FF);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEDF2FA))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    details,
                    style: const TextStyle(
                      color: Color(0xFF52627A),
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    if (userId.isNotEmpty)
                      _metadata(Icons.person_outline_rounded, userId),
                    if (ip.isNotEmpty) _metadata(Icons.lan_outlined, ip),
                    _metadata(Icons.schedule_rounded, timeText),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metadata(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: _muted),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(color: _muted, fontSize: 10)),
      ],
    );
  }
}

class _FunctionData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _FunctionData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}
