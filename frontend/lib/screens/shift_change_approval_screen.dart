import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/auth_state.dart';

import 'employee_list_screen.dart';
import 'ip_config_screen.dart';
import 'change_password_screen.dart';
import 'leave_approval_screen.dart';
import 'face_management_screen.dart';
import 'business_trip_approval_screen.dart';
import 'login_screen.dart';
import 'attendance_report_screen.dart';

class ShiftChangeApprovalScreen extends StatefulWidget {
  const ShiftChangeApprovalScreen({super.key});

  @override
  State<ShiftChangeApprovalScreen> createState() =>
      _ShiftChangeApprovalScreenState();
}

class _ShiftChangeApprovalScreenState extends State<ShiftChangeApprovalScreen> {
  // COLORS - đồng bộ với BusinessTripApprovalScreen

  static const Color _navy = Color(0xFF0D2858);
  static const Color _blue = Color(0xFF246BDE);
  static const Color _pageBackground = Color(0xFFF4F7FC);
  static const Color _border = Color(0xFFE3EAF4);
  static const Color _text = Color(0xFF183153);
  static const Color _muted = Color(0xFF71819A);

  static const Color _green = Color(0xFF15966A);
  static const Color _greenBg = Color(0xFFEAF8F2);

  static const Color _red = Color(0xFFD94343);
  static const Color _redBg = Color(0xFFFFF0F0);

  static const Color _orange = Color(0xFFE88922);
  static const Color _orangeBg = Color(0xFFFFF6E9);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isLoading = true;
  String? _errorMessage;

  List<dynamic> _pendingRequests = [];

  final Set<String> _processingIds = {};

  // LIFECYCLE

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  // API

  Future<void> _loadPending() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService.getList(
      '/api/shift-change-requests/pending',
      bearerToken: AuthState.instance.token,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;

      if (result.success) {
        _pendingRequests = result.data ?? [];
      } else {
        _errorMessage =
            result.errorMessage ?? 'Không thể tải danh sách yêu cầu.';
      }
    });
  }

  Future<void> _handleDecision(String id, bool approve) async {
    setState(() {
      _processingIds.add(id);
    });

    final result = await ApiService.put(
      '/api/shift-change-requests/$id/${approve ? 'approve' : 'reject'}',
      {},
      bearerToken: AuthState.instance.token,
    );

    if (!mounted) return;

    setState(() {
      _processingIds.remove(id);
    });

    if (result.success) {
      setState(() {
        _pendingRequests.removeWhere((r) => r['id']?.toString() == id);
      });

      _showMessage(
        approve
            ? 'Đã duyệt - ca làm việc mới đã được áp dụng.'
            : 'Đã từ chối - ca hiện tại giữ nguyên.',
        backgroundColor: approve ? _green : _red,
      );
    } else {
      _showMessage(result.errorMessage ?? 'Thao tác thất bại.');
    }
  }

  // HELPERS

  String _formatDate(dynamic value) {
    if (value == null) return '--';

    try {
      final date = DateTime.parse(value.toString()).toLocal();

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (_) {
      return value.toString();
    }
  }

  String _employeeName(Map<String, dynamic> request) {
    final name = request['employeeName']?.toString().trim();

    if (name != null && name.isNotEmpty) {
      return name;
    }

    return 'Không rõ';
  }

  String _employeeCode(Map<String, dynamic> request) {
    final code = request['employeeCode']?.toString().trim();

    if (code != null && code.isNotEmpty) {
      return code;
    }

    return '--';
  }

  String _shiftType(Map<String, dynamic> request) {
    final type = request['requestedShiftType']?.toString();

    if (type == 'Flexible') {
      return 'Linh hoạt';
    }

    return 'Cố định';
  }

  String _requestedTime(Map<String, dynamic> request) {
    final start = request['requestedStartTime']?.toString() ?? '--';
    final end = request['requestedEndTime']?.toString() ?? '--';

    return '$start - $end';
  }

  String _requestedHours(Map<String, dynamic> request) {
    final hours = request['requestedHours'];

    if (hours == null) {
      return '--';
    }

    return '$hours giờ';
  }

  void _showMessage(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
      ),
    );
  }

  void _openScreen(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _goHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _openFaceManagement() {
    final token = AuthState.instance.token;

    if (token == null || token.isEmpty) {
      _showMessage('Phiên đăng nhập không hợp lệ.');
      return;
    }

    _openScreen(FaceManagementScreen(token: token));
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
            style: TextStyle(color: _text, fontWeight: FontWeight.w800),
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
                style: TextStyle(color: _red, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    AuthState.instance.clear();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1000;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _pageBackground,

      drawer: isDesktop ? null : Drawer(width: 270, child: _buildSidebar()),

      body: SafeArea(
        child: Row(
          children: [
            if (isDesktop) SizedBox(width: 260, child: _buildSidebar()),

            Expanded(
              child: Column(
                children: [
                  _buildTopBar(isDesktop),

                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadPending,
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
          // LOGO
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

          // NAVIGATION
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _navItem(
                  icon: Icons.home_rounded,
                  title: 'Trang chủ',
                  onTap: _goHome,
                ),

                const SizedBox(height: 8),

                // NHÂN VIÊN
                _navSection(
                  icon: Icons.groups_rounded,
                  title: 'Nhân viên',
                  children: [
                    _navSubItem(
                      title: 'Danh sách nhân viên',
                      onTap: () => _openScreen(const EmployeeListScreen()),
                    ),

                    _navSubItem(
                      title: 'Thêm khuôn mặt chấm công',
                      onTap: _openFaceManagement,
                    ),
                  ],
                ),

                // CHẤM CÔNG
                _navSection(
                  icon: Icons.access_time_rounded,
                  title: 'Chấm công',
                  children: [
                    _navSubItem(
                      title: 'Cấu hình IP & GPS',
                      onTap: () => _openScreen(const IpConfigScreen()),
                    ),
                  ],
                ),

                // BÁO CÁO
                _navItem(
                  icon: Icons.bar_chart_rounded,
                  title: 'Báo cáo',
                  onTap: () => _openScreen(const AttendanceReportScreen()),
                ),

                const SizedBox(height: 8),

                // YÊU CẦU
                _navSection(
                  icon: Icons.assignment_rounded,
                  title: 'Yêu cầu',
                  initiallyExpanded: true,
                  children: [
                    _navSubItem(
                      title: 'Đổi ca',
                      selected: true,
                      onTap: () {
                        // Đang ở màn này.
                        if (MediaQuery.sizeOf(context).width < 1000) {
                          Navigator.pop(context);
                        }
                      },
                    ),

                    _navSubItem(
                      title: 'Nghỉ phép',
                      onTap: () => _openScreen(const LeaveApprovalScreen()),
                    ),

                    _navSubItem(
                      title: 'Công tác',
                      onTap: () =>
                          _openScreen(const BusinessTripApprovalScreen()),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ACCOUNT
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
            child: Column(
              children: [
                const Divider(color: Color(0xFF29436D)),

                _navItem(
                  icon: Icons.lock_outline_rounded,
                  title: 'Đổi mật khẩu',
                  onTap: () => _openScreen(const ChangePasswordScreen()),
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

  // SIDEBAR NAV ITEM

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
              Icon(icon, size: 19, color: iconColor ?? const Color(0xFFBFD5F5)),

              const SizedBox(width: 11),

              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFFD0DDF1),
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

  // SIDEBAR SECTION

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
        childrenPadding: const EdgeInsets.only(left: 12, bottom: 6),
        iconColor: const Color(0xFFBFD5F5),
        collapsedIconColor: const Color(0xFF7894BD),
        leading: Icon(icon, size: 19, color: const Color(0xFFBFD5F5)),
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

  // SIDEBAR SUB ITEM

  Widget _navSubItem({
    required String title,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 4, bottom: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: onTap,
          child: Container(
            height: 38,
            padding: const EdgeInsets.only(left: 34, right: 10),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF246BDE) : Colors.transparent,
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
                    color: selected ? Colors.white : const Color(0xFF7894BD),
                  ),
                ),

                const SizedBox(width: 9),

                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFFBFD0E8),
                      fontSize: 11.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
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

  Widget _buildTopBar(bool isDesktop) {
    return Container(
      height: 72,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 28 : 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          if (!isDesktop) ...[
            IconButton(
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
              icon: const Icon(Icons.menu_rounded, color: _navy),
              tooltip: 'Mở menu',
            ),
            const SizedBox(width: 6),
          ],

          const Expanded(
            child: Text(
              'Duyệt yêu cầu đổi ca',
              style: TextStyle(
                color: _text,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          IconButton(
            onPressed: _isLoading ? null : _loadPending,
            icon: const Icon(Icons.refresh_rounded),
            color: _blue,
            tooltip: 'Làm mới',
          ),

          const SizedBox(width: 8),

          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.swap_horiz_rounded, color: _blue, size: 20),
          ),

          if (isDesktop) ...[
            const SizedBox(width: 10),

            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quản trị viên',
                  style: TextStyle(
                    color: _text,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'AttendGo Admin',
                  style: TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),

            const SizedBox(width: 18),
          ],
        ],
      ),
    );
  }

  // MAIN CONTENT

  Widget _buildMainContent(bool isDesktop) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(isDesktop ? 28 : 16),
      children: [
        _buildPageIntro(isDesktop),

        const SizedBox(height: 22),

        _buildSummaryCard(),

        const SizedBox(height: 18),

        if (_isLoading)
          const Padding(
            padding: EdgeInsets.only(top: 70),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_errorMessage != null)
          _buildErrorState()
        else if (_pendingRequests.isEmpty)
          _buildEmptyState()
        else if (isDesktop)
          _buildDesktopTable()
        else
          ..._pendingRequests.map((item) {
            final request = Map<String, dynamic>.from(item as Map);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildMobileCard(request),
            );
          }),
      ],
    );
  }

  // PAGE INTRO

  Widget _buildPageIntro(bool isDesktop) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2FF),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.swap_horiz_rounded, color: _blue, size: 27),
        ),

        const SizedBox(width: 14),

        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Yêu cầu đổi ca',
                style: TextStyle(
                  color: _text,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),

              SizedBox(height: 4),

              Text(
                'Kiểm tra và phê duyệt các yêu cầu thay đổi ca làm việc của nhân viên.',
                style: TextStyle(color: _muted, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // SUMMARY

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _orangeBg,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.pending_actions_rounded,
              color: _orange,
              size: 23,
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yêu cầu đang chờ duyệt',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),

                SizedBox(height: 3),

                Text(
                  'Danh sách yêu cầu đổi ca',
                  style: TextStyle(
                    color: _text,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: _orangeBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_pendingRequests.length} yêu cầu',
              style: const TextStyle(
                color: _orange,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // DESKTOP TABLE

  Widget _buildDesktopTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // HEADER
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            color: const Color(0xFFF8FAFD),
            child: Row(
              children: [
                const SizedBox(
                  width: 220,
                  child: Text(
                    'NHÂN VIÊN',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),

                const SizedBox(
                  width: 130,
                  child: Text(
                    'LOẠI CA',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),

                const SizedBox(
                  width: 125,
                  child: Text(
                    'NGÀY ÁP DỤNG',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),

                const SizedBox(
                  width: 150,
                  child: Text(
                    'THỜI GIAN',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),

                const SizedBox(
                  width: 90,
                  child: Text(
                    'SỐ GIỜ',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),

                const Expanded(
                  child: Text(
                    'LÝ DO',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),

                const SizedBox(
                  width: 190,
                  child: Text(
                    'THAO TÁC',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: _muted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: _border),

          // ROWS
          ..._pendingRequests.asMap().entries.map((entry) {
            final index = entry.key;

            final request = Map<String, dynamic>.from(entry.value as Map);

            return _buildDesktopRow(request, index);
          }),
        ],
      ),
    );
  }

  // DESKTOP ROW

  Widget _buildDesktopRow(Map<String, dynamic> request, int index) {
    final id = request['id']?.toString() ?? '';

    final isProcessing = _processingIds.contains(id);

    final employee = _employeeName(request);

    final code = _employeeCode(request);

    final type = _shiftType(request);

    final effectiveDate = _formatDate(request['effectiveDate']);

    final time = _requestedTime(request);

    final hours = _requestedHours(request);

    final reason = request['reason']?.toString().trim();

    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: index.isEven ? Colors.white : const Color(0xFFFCFDFE),
        border: const Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          // EMPLOYEE
          SizedBox(
            width: 220,
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FF),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    employee.isNotEmpty ? employee[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: _blue,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        employee,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _text,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        code,
                        style: const TextStyle(color: _muted, fontSize: 10.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // TYPE
          SizedBox(
            width: 130,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildShiftTypeBadge(type),
            ),
          ),

          // DATE
          SizedBox(
            width: 125,
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: _muted,
                ),

                const SizedBox(width: 7),

                Text(
                  effectiveDate,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // TIME
          SizedBox(
            width: 150,
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 15, color: _muted),

                const SizedBox(width: 7),

                Flexible(
                  child: Text(
                    time,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _text,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // HOURS
          SizedBox(
            width: 90,
            child: Text(
              hours,
              style: const TextStyle(
                color: _text,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          // REASON
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 18),
              child: Text(
                reason == null || reason.isEmpty ? 'Không có lý do' : reason,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: reason == null || reason.isEmpty ? _muted : _text,
                  fontSize: 11.5,
                  fontStyle: reason == null || reason.isEmpty
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),
            ),
          ),

          // ACTIONS
          SizedBox(
            width: 190,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildRejectButton(id, isProcessing),

                const SizedBox(width: 8),

                _buildApproveButton(id, isProcessing),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // SHIFT TYPE BADGE

  Widget _buildShiftTypeBadge(String type) {
    final flexible = type == 'Linh hoạt';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: flexible ? const Color(0xFFEAF2FF) : const Color(0xFFF0EBFF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        type,
        style: TextStyle(
          color: flexible ? _blue : const Color(0xFF7454C8),
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // APPROVE BUTTON

  Widget _buildApproveButton(String id, bool isProcessing) {
    return SizedBox(
      height: 34,
      child: ElevatedButton.icon(
        onPressed: isProcessing ? null : () => _handleDecision(id, true),
        icon: isProcessing
            ? const SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.check_rounded, size: 15),
        label: const Text(
          'Duyệt',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFB8CFC5),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
      ),
    );
  }

  // REJECT BUTTON

  Widget _buildRejectButton(String id, bool isProcessing) {
    return SizedBox(
      height: 34,
      child: OutlinedButton.icon(
        onPressed: isProcessing ? null : () => _handleDecision(id, false),
        icon: const Icon(Icons.close_rounded, size: 15),
        label: const Text(
          'Từ chối',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _red,
          side: const BorderSide(color: _red),
          disabledForegroundColor: const Color(0xFFBDA0A0),
          padding: const EdgeInsets.symmetric(horizontal: 11),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
      ),
    );
  }

  // MOBILE CARD

  Widget _buildMobileCard(Map<String, dynamic> request) {
    final id = request['id']?.toString() ?? '';

    final isProcessing = _processingIds.contains(id);

    final employee = _employeeName(request);

    final code = _employeeCode(request);

    final type = _shiftType(request);

    final reason = request['reason']?.toString();

    return Container(
      padding: const EdgeInsets.all(16),
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  employee.isNotEmpty ? employee[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: _blue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: _text,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      code,
                      style: const TextStyle(fontSize: 11, color: _muted),
                    ),
                  ],
                ),
              ),

              _buildShiftTypeBadge(type),
            ],
          ),

          const SizedBox(height: 15),

          _buildMobileInfoRow(
            Icons.calendar_today_outlined,
            'Áp dụng từ',
            _formatDate(request['effectiveDate']),
          ),

          const SizedBox(height: 8),

          _buildMobileInfoRow(
            Icons.access_time_rounded,
            'Thời gian',
            '${_requestedTime(request)}'
                '  (${_requestedHours(request)})',
          ),

          if (reason != null && reason.trim().isNotEmpty) ...[
            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                reason,
                style: const TextStyle(fontSize: 12, color: _text, height: 1.4),
              ),
            ),
          ],

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(child: _buildRejectButton(id, isProcessing)),

              const SizedBox(width: 9),

              Expanded(child: _buildApproveButton(id, isProcessing)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: _muted),

        const SizedBox(width: 8),

        Text('$label: ', style: const TextStyle(fontSize: 11.5, color: _muted)),

        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 11.5,
              color: _text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ERROR STATE

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _redBg,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: _red,
              size: 28,
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            'Không thể tải dữ liệu',
            style: TextStyle(
              color: _text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            _errorMessage ?? 'Đã xảy ra lỗi không xác định.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 12),
          ),

          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: _loadPending,
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _blue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // EMPTY STATE

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 55, horizontal: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5FA),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.task_alt_rounded, color: _muted, size: 32),
          ),

          const SizedBox(height: 16),

          const Text(
            'Không có yêu cầu đang chờ duyệt',
            style: TextStyle(
              color: _text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Hiện tại chưa có nhân viên nào gửi yêu cầu đổi ca.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
