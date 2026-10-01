import 'dart:math' as math;

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
  // ============================================================
  // COLORS
  // ============================================================

  static const Color _navy = Color(0xFF0D2858);
  static const Color _blue = Color(0xFF246BDE);
  static const Color _pageBackground = Color(0xFFF4F7FC);
  static const Color _border = Color(0xFFE3EAF4);
  static const Color _text = Color(0xFF183153);
  static const Color _muted = Color(0xFF71819A);

  // ============================================================
  // STATE
  // ============================================================

  bool _isLoadingStats = true;

  int _totalEmployees = 0;

  // Dữ liệu mẫu cho dashboard.
  // Khi backend có API thống kê riêng thì thay bằng dữ liệu API.
  final List<_AttendanceDayData> _attendanceWeek = const [
    _AttendanceDayData(day: 'T2', present: 42, late: 4, absent: 2),
    _AttendanceDayData(day: 'T3', present: 45, late: 3, absent: 1),
    _AttendanceDayData(day: 'T4', present: 43, late: 5, absent: 1),
    _AttendanceDayData(day: 'T5', present: 46, late: 2, absent: 1),
    _AttendanceDayData(day: 'T6', present: 44, late: 4, absent: 1),
    _AttendanceDayData(day: 'T7', present: 30, late: 2, absent: 1),
    _AttendanceDayData(day: 'CN', present: 12, late: 1, absent: 0),
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> _loadStats() async {
    setState(() {
      _isLoadingStats = true;
    });

    final result = await ApiService.getList(
      '/api/employees',
      bearerToken: AuthState.instance.token,
    );

    if (!mounted) return;

    setState(() {
      _isLoadingStats = false;

      if (result.success && result.data != null) {
        _totalEmployees = result.data!.length;
      }
    });
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _openScreen(Widget screen) {
    if (MediaQuery.sizeOf(context).width < 1000) {
      Navigator.pop(context);
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => screen)).then((
      _,
    ) {
      if (mounted) {
        _loadStats();
      }
    });
  }

  void _goHome() {
    if (MediaQuery.sizeOf(context).width < 1000) {
      Navigator.pop(context);
    }
  }

  void _openFaceManagement() {
    final token = AuthState.instance.token;

    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phiên đăng nhập không hợp lệ.')),
      );
      return;
    }

    if (MediaQuery.sizeOf(context).width < 1000) {
      Navigator.pop(context);
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FaceManagementScreen(token: token)),
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Đăng xuất',
            style: TextStyle(fontWeight: FontWeight.w800, color: _text),
          ),
          content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text(
                'Đăng xuất',
                style: TextStyle(
                  color: Color(0xFFE03131),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    if (!mounted) return;

    AuthState.instance.clear();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1000;

    return Scaffold(
      backgroundColor: _pageBackground,

      drawer: isDesktop
          ? null
          : Drawer(
              width: 270,
              backgroundColor: _navy,
              child: SafeArea(child: _buildSidebar()),
            ),

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
                      onRefresh: _loadStats,
                      color: _blue,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          isDesktop ? 28 : 16,
                          22,
                          isDesktop ? 28 : 16,
                          32,
                        ),
                        child: _buildDashboardContent(isDesktop),
                      ),
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

  // ============================================================
  // SIDEBAR
  // ============================================================

  Widget _buildSidebar() {
    return Container(
      color: _navy,
      child: Column(
        children: [
          // ------------------------------------------------------
          // LOGO
          // ------------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 18, 28),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(5),
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

          // ------------------------------------------------------
          // MENU
          // ------------------------------------------------------
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                // TRANG CHỦ
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
                      onTap: () {
                        _openScreen(const EmployeeListScreen());
                      },
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
                      onTap: () {
                        _openScreen(const IpConfigScreen());
                      },
                    ),
                  ],
                ),

                // BÁO CÁO
                _navItem(
                  icon: Icons.bar_chart_rounded,
                  title: 'Báo cáo',
                  onTap: () {
                    _openScreen(const AttendanceReportScreen());
                  },
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
                      onTap: () {
                        _openScreen(const ShiftChangeApprovalScreen());
                      },
                    ),

                    _navSubItem(
                      title: 'Nghỉ phép',
                      onTap: () {
                        _openScreen(const LeaveApprovalScreen());
                      },
                    ),

                    _navSubItem(
                      title: 'Công tác',
                      onTap: () {
                        _openScreen(const BusinessTripApprovalScreen());
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ------------------------------------------------------
          // BOTTOM MENU
          // ------------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
            child: Column(
              children: [
                const Divider(color: Color(0xFF29436D)),

                _navItem(
                  icon: Icons.lock_outline_rounded,
                  title: 'Đổi mật khẩu',
                  onTap: () {
                    _openScreen(const ChangePasswordScreen());
                  },
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

  // ============================================================
  // SIDEBAR SECTION
  // ============================================================

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
        collapsedIconColor: const Color(0xFFBFD5F5),

        leading: Icon(icon, color: const Color(0xFFD6E4FA), size: 21),

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

  // ============================================================
  // SIDEBAR ITEM
  // ============================================================

  Widget _navItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFFD6E4FA),
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
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
                      fontSize: 13.5,
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

  // ============================================================
  // SIDEBAR SUB ITEM
  // ============================================================

  Widget _navSubItem({
    required String title,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: selected ? _blue : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(13, 10, 9, 10),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  size: selected ? 7 : 5,
                  color: selected ? Colors.white : const Color(0xFF7894BD),
                ),

                const SizedBox(width: 11),

                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFFD0DDF1),
                      fontSize: 12,
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

  // ============================================================
  // TOP BAR
  // ============================================================

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
          if (!isDesktop)
            Builder(
              builder: (context) {
                return IconButton(
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                  icon: const Icon(Icons.menu_rounded, color: _text),
                );
              },
            ),

          if (!isDesktop) const SizedBox(width: 4),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Trang chủ',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: _text,
                  ),
                ),

                SizedBox(height: 2),

                Text(
                  'Tổng quan hoạt động hệ thống',
                  style: TextStyle(fontSize: 11, color: _muted),
                ),
              ],
            ),
          ),

          // USER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F8FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4EEFF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 19,
                    color: _blue,
                  ),
                ),

                if (isDesktop) ...[
                  const SizedBox(width: 9),

                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _text,
                        ),
                      ),

                      SizedBox(height: 1),

                      Text(
                        'Quản trị hệ thống',
                        style: TextStyle(fontSize: 9.5, color: _muted),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DASHBOARD CONTENT
  // ============================================================

  Widget _buildDashboardContent(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --------------------------------------------------------
        // WELCOME
        // --------------------------------------------------------
        _buildWelcome(),

        const SizedBox(height: 22),

        // --------------------------------------------------------
        // 7 DAYS ATTENDANCE
        // --------------------------------------------------------
        _buildSectionTitle(
          title: 'Tổng quan chấm công',
          subtitle: 'Tình hình chấm công trong 7 ngày gần đây',
          icon: Icons.bar_chart_rounded,
        ),

        const SizedBox(height: 11),

        _buildWeeklyAttendanceCard(isDesktop),

        const SizedBox(height: 22),

        // --------------------------------------------------------
        // TODAY + REQUEST TYPES
        // --------------------------------------------------------
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildTodayAttendanceCard()),

              const SizedBox(width: 18),

              Expanded(child: _buildRequestOverviewCard()),
            ],
          )
        else
          Column(
            children: [
              _buildTodayAttendanceCard(),

              const SizedBox(height: 18),

              _buildRequestOverviewCard(),
            ],
          ),

        const SizedBox(height: 22),

        // --------------------------------------------------------
        // PENDING REQUESTS
        // --------------------------------------------------------
        _buildPendingRequestCard(),

        const SizedBox(height: 12),

        // --------------------------------------------------------
        // SMALL INFO
        // --------------------------------------------------------
        _buildDashboardFooter(),
      ],
    );
  }

  // ============================================================
  // WELCOME
  // ============================================================

  Widget _buildWelcome() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF2FF), Color(0xFFF8FAFF)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE8FB)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDCE8FB)),
            ),
            child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xin chào 👋',
                  style: TextStyle(
                    fontSize: 11,
                    color: _muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                SizedBox(height: 3),

                Text(
                  'Chào Quản Trị Viên',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF102A67),
                  ),
                ),

                SizedBox(height: 3),

                Text(
                  'Theo dõi nhanh tình hình hoạt động của công ty hôm nay.',
                  style: TextStyle(fontSize: 11.5, color: _muted),
                ),
              ],
            ),
          ),

          if (_totalEmployees > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDCE8FB)),
              ),
              child: Column(
                children: [
                  Text(
                    _isLoadingStats ? '...' : '$_totalEmployees',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _blue,
                    ),
                  ),
                  const Text(
                    'nhân viên',
                    style: TextStyle(fontSize: 9, color: _muted),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F0FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 19, color: _blue),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _text,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                subtitle,
                style: const TextStyle(fontSize: 10.5, color: _muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // WEEKLY ATTENDANCE CARD
  // ============================================================

  Widget _buildWeeklyAttendanceCard(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tình hình chấm công',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _text,
                      ),
                    ),

                    SizedBox(height: 3),

                    Text(
                      'Số lượng nhân viên theo từng trạng thái',
                      style: TextStyle(fontSize: 10.5, color: _muted),
                    ),
                  ],
                ),
              ),

              _buildLegend('Có mặt', const Color(0xFF20B878)),

              const SizedBox(width: 12),

              _buildLegend('Đi trễ', const Color(0xFFFFA94D)),

              const SizedBox(width: 12),

              _buildLegend('Vắng', const Color(0xFFF06565)),
            ],
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: isDesktop ? 230 : 200,
            child: CustomPaint(
              painter: _WeeklyBarChartPainter(data: _attendanceWeek),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LEGEND
  // ============================================================

  Widget _buildLegend(String title, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),

        const SizedBox(width: 5),

        Text(
          title,
          style: const TextStyle(
            fontSize: 9.5,
            color: _muted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TODAY ATTENDANCE
  // ============================================================

  Widget _buildTodayAttendanceCard() {
    const int present = 44;
    const int late = 4;
    const int absent = 2;

    final int total = present + late + absent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF9F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.access_time_rounded,
                  size: 19,
                  color: Color(0xFF20B878),
                ),
              ),

              const SizedBox(width: 10),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tình hình hôm nay',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _text,
                      ),
                    ),

                    SizedBox(height: 2),

                    Text(
                      'Thống kê chấm công trong ngày',
                      style: TextStyle(fontSize: 10, color: _muted),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Hôm nay',
                  style: TextStyle(
                    fontSize: 9,
                    color: _blue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              SizedBox(
                width: 125,
                height: 125,
                child: CustomPaint(
                  painter: _AttendancePiePainter(
                    present: present,
                    late: late,
                    absent: absent,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$total',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: _text,
                          ),
                        ),
                        const Text(
                          'nhân viên',
                          style: TextStyle(fontSize: 9, color: _muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 22),

              Expanded(
                child: Column(
                  children: [
                    _buildAttendanceStat(
                      label: 'Có mặt',
                      value: '$present',
                      color: const Color(0xFF20B878),
                    ),

                    const SizedBox(height: 12),

                    _buildAttendanceStat(
                      label: 'Đi trễ',
                      value: '$late',
                      color: const Color(0xFFFFA94D),
                    ),

                    const SizedBox(height: 12),

                    _buildAttendanceStat(
                      label: 'Vắng',
                      value: '$absent',
                      color: const Color(0xFFF06565),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ATTENDANCE STAT
  // ============================================================

  Widget _buildAttendanceStat({
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: _muted),
          ),
        ),

        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // REQUEST OVERVIEW
  // ============================================================

  Widget _buildRequestOverviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2E5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.assignment_rounded,
                  size: 19,
                  color: Color(0xFFFF922B),
                ),
              ),

              const SizedBox(width: 10),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tình hình các loại yêu cầu',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _text,
                      ),
                    ),

                    SizedBox(height: 2),

                    Text(
                      'Các yêu cầu đang chờ xử lý',
                      style: TextStyle(fontSize: 10, color: _muted),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _buildRequestTypeItem(
                  icon: Icons.swap_horiz_rounded,
                  title: 'Đổi ca',
                  value: '4',
                  color: const Color(0xFFFF922B),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _buildRequestTypeItem(
                  icon: Icons.calendar_month_rounded,
                  title: 'Nghỉ phép',
                  value: '6',
                  color: const Color(0xFFF5487F),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _buildRequestTypeItem(
                  icon: Icons.business_center_rounded,
                  title: 'Công tác',
                  value: '2',
                  color: const Color(0xFF4A90E2),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FD),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: _muted),

                SizedBox(width: 7),

                Expanded(
                  child: Text(
                    'Các yêu cầu cần được kiểm tra và xử lý.',
                    style: TextStyle(fontSize: 10, color: _muted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REQUEST TYPE ITEM
  // ============================================================

  Widget _buildRequestTypeItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 21, color: color),

          const SizedBox(height: 7),

          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9.5,
              color: _muted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PENDING REQUEST
  // ============================================================

  Widget _buildPendingRequestCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.pending_actions_rounded,
                  size: 19,
                  color: Color(0xFFEF4444),
                ),
              ),

              const SizedBox(width: 10),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Yêu cầu chờ duyệt',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _text,
                      ),
                    ),

                    SizedBox(height: 2),

                    Text(
                      'Các yêu cầu mới nhất cần admin xử lý',
                      style: TextStyle(fontSize: 10, color: _muted),
                    ),
                  ],
                ),
              ),

              TextButton(
                onPressed: () {
                  _openScreen(const LeaveApprovalScreen());
                },
                child: const Text(
                  'Xem tất cả',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: _blue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          _buildPendingItem(
            icon: Icons.calendar_month_rounded,
            title: 'Đơn xin nghỉ phép',
            subtitle: 'Cần kiểm tra và phê duyệt',
            count: '6',
            color: const Color(0xFFF5487F),
            onTap: () {
              _openScreen(const LeaveApprovalScreen());
            },
          ),

          const SizedBox(height: 9),

          _buildPendingItem(
            icon: Icons.swap_horiz_rounded,
            title: 'Yêu cầu đổi ca',
            subtitle: 'Nhân viên đang chờ phản hồi',
            count: '4',
            color: const Color(0xFFFF922B),
            onTap: () {
              _openScreen(const ShiftChangeApprovalScreen());
            },
          ),

          const SizedBox(height: 9),

          _buildPendingItem(
            icon: Icons.business_center_rounded,
            title: 'Đơn công tác',
            subtitle: 'Yêu cầu công tác mới',
            count: '2',
            color: const Color(0xFF4A90E2),
            onTap: () {
              _openScreen(const BusinessTripApprovalScreen());
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PENDING ITEM
  // ============================================================

  Widget _buildPendingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFF8FAFD),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 20, color: color),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: _text,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 9.5, color: _muted),
                    ),
                  ],
                ),
              ),

              Container(
                constraints: const BoxConstraints(minWidth: 30),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  count,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),

              const SizedBox(width: 5),

              const Icon(
                Icons.chevron_right_rounded,
                size: 19,
                color: Color(0xFFA7B4C8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FOOTER
  // ============================================================

  Widget _buildDashboardFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF5FF),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFDCE8FB)),
      ),
      child: Row(
        children: [
          const Icon(Icons.dashboard_customize_rounded, size: 17, color: _blue),

          const SizedBox(width: 8),

          const Expanded(
            child: Text(
              'Dashboard tập trung vào các thông tin tổng quan. '
              'Chi tiết chấm công được xem tại Báo cáo.',
              style: TextStyle(fontSize: 9.5, color: _muted),
            ),
          ),

          TextButton(
            onPressed: () {
              _openScreen(const AttendanceReportScreen());
            },
            child: const Text(
              'Báo cáo',
              style: TextStyle(
                fontSize: 10,
                color: _blue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARD DECORATION
  // ============================================================

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: _border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.025),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

// ================================================================
// ATTENDANCE DAY DATA
// ================================================================

class _AttendanceDayData {
  final String day;
  final int present;
  final int late;
  final int absent;

  const _AttendanceDayData({
    required this.day,
    required this.present,
    required this.late,
    required this.absent,
  });
}

// ================================================================
// WEEKLY BAR CHART
// ================================================================

class _WeeklyBarChartPainter extends CustomPainter {
  final List<_AttendanceDayData> data;

  _WeeklyBarChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const double left = 8;
    const double right = 8;
    const double top = 10;
    const double bottom = 28;

    final chartWidth = size.width - left - right;

    final chartHeight = size.height - top - bottom;

    final maxValue = data
        .map((e) => math.max(e.present, math.max(e.late, e.absent)))
        .reduce(math.max)
        .toDouble();

    // GRID
    final gridPaint = Paint()
      ..color = const Color(0xFFE9EEF6)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = top + chartHeight - (chartHeight * i / 4);

      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );
    }

    final groupWidth = chartWidth / data.length;

    final barWidth = math.min(11.0, groupWidth * 0.15);

    for (int i = 0; i < data.length; i++) {
      final item = data[i];

      final centerX = left + groupWidth * i + groupWidth / 2;

      final values = [item.present, item.late, item.absent];

      final colors = [
        const Color(0xFF20B878),
        const Color(0xFFFFA94D),
        const Color(0xFFF06565),
      ];

      final gap = 3.0;

      final totalWidth = barWidth * 3 + gap * 2;

      final startX = centerX - totalWidth / 2;

      for (int j = 0; j < 3; j++) {
        final value = values[j].toDouble();

        final barHeight = chartHeight * value / maxValue;

        final x = startX + j * (barWidth + gap);

        final y = top + chartHeight - barHeight;

        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          const Radius.circular(4),
        );

        final paint = Paint()..color = colors[j];

        canvas.drawRRect(rect, paint);
      }

      // DAY LABEL
      final textPainter = TextPainter(
        text: TextSpan(
          text: item.day,
          style: const TextStyle(
            fontSize: 9,
            color: Color(0xFF71819A),
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      textPainter.paint(
        canvas,
        Offset(centerX - textPainter.width / 2, size.height - 17),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyBarChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

// ================================================================
// PIE CHART
// ================================================================

class _AttendancePiePainter extends CustomPainter {
  final int present;
  final int late;
  final int absent;

  _AttendancePiePainter({
    required this.present,
    required this.late,
    required this.absent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = present + late + absent;

    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);

    final radius = math.min(size.width, size.height) / 2;

    final strokeWidth = 15.0;

    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    final values = [present, late, absent];

    final colors = [
      const Color(0xFF20B878),
      const Color(0xFFFFA94D),
      const Color(0xFFF06565),
    ];

    double startAngle = -math.pi / 2;

    for (int i = 0; i < values.length; i++) {
      final sweepAngle = (values[i] / total) * math.pi * 2;

      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _AttendancePiePainter oldDelegate) {
    return oldDelegate.present != present ||
        oldDelegate.late != late ||
        oldDelegate.absent != absent;
  }
}
