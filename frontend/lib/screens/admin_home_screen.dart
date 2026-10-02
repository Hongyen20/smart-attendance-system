import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_state.dart';

import 'employee_list_screen.dart';
import 'ip_config_screen.dart';
import 'change_password_screen.dart';
import 'leave_approval_screen.dart';
import 'shift_change_approval_screen.dart';
import 'face_management_screen.dart';
import 'business_trip_approval_screen.dart';
import 'attendance_report_screen.dart';
import 'login_screen.dart';

// COLORS

const Color _brightBlue = Color(0xFF2864E8);
const Color _bg = Color(0xFFF3F8FF);
const Color _navy = Color(0xFF0D2858);
const Color _textBlue = Color(0xFF31589D);
const Color _textGrey = Color(0xFF7185A8);
const Color _border = Color(0xFFE2EAF7);
const Color _green = Color(0xFF1FA971);
const Color _red = Color(0xFFEF4444);
const Color _orange = Color(0xFFF59E0B);
const Color _purple = Color(0xFF8B5CF6);
const Color _lightBlue = Color(0xFF3B82F6);
const Color _text = Color(0xFF183153);
const Color _muted = Color(0xFF71819A);
int _toInt(dynamic v) {
  if (v is num) return v.toInt();

  return int.tryParse('${v ?? ''}') ?? 0;
}

// MODELS

class _TrendPoint {
  final String label;
  final int value;

  const _TrendPoint(this.label, this.value);
}

class _Overview {
  final int totalEmployees;

  // onTime, late, absent, businessTrip, leave, other
  final List<int> today;

  final int todayTotal;

  final List<_TrendPoint> trend;

  final int pendingLeave;
  final int pendingTrip;

  // null = backend chưa có số liệu đổi ca.
  final int? pendingShift;

  const _Overview({
    required this.totalEmployees,
    required this.today,
    required this.todayTotal,
    required this.trend,
    required this.pendingLeave,
    required this.pendingTrip,
    required this.pendingShift,
  });

  factory _Overview.fromJson(Map j) {
    final t = j['today'];
    final pending = j['pending'];
    final trendRaw = j['trend'];

    List<int> todayValues = List<int>.filled(6, 0);
    int todayTotal = 0;

    if (t is Map) {
      todayValues = [
        _toInt(t['onTime']),
        _toInt(t['late']),
        _toInt(t['absent']),
        _toInt(t['businessTrip']),
        _toInt(t['leave']),
        _toInt(t['other']),
      ];

      todayTotal = _toInt(t['total']);
    }

    // "2026-09-25" -> "25/09"
    String dayLabel(String s) {
      final parts = s.split('T').first.split('-');

      if (parts.length < 3) return s;

      return '${parts[2]}/${parts[1]}';
    }

    final trend = <_TrendPoint>[];

    if (trendRaw is List) {
      for (final e in trendRaw.whereType<Map>()) {
        trend.add(
          _TrendPoint(dayLabel('${e['date'] ?? ''}'), _toInt(e['checkedIn'])),
        );
      }
    }

    int? shift;

    if (pending is Map && pending['shiftChange'] != null) {
      shift = _toInt(pending['shiftChange']);
    }

    return _Overview(
      totalEmployees: _toInt(j['totalEmployees']),
      today: todayValues,
      todayTotal: todayTotal,
      trend: trend,
      pendingLeave: pending is Map ? _toInt(pending['leave']) : 0,
      pendingTrip: pending is Map ? _toInt(pending['businessTrip']) : 0,
      pendingShift: shift,
    );
  }
}

// class _MenuChild {
//   final String label;
//   final VoidCallback onTap;

//   _MenuChild(this.label, this.onTap);
// }

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // STATE

  bool _isLoading = true;

  String? _error;

  _Overview? _overview;

  // Số ngày của biểu đồ: 7 | 14 | 30
  int _days = 7;

  // Các nhóm menu đang mở.
  //final Set<String> _expanded = {'employees', 'attendance', 'requests'};

  DateTime _now = DateTime.now();

  Timer? _clockTimer;

  static const List<String> _weekdays = [
    'Chủ Nhật',
    'Thứ Hai',
    'Thứ Ba',
    'Thứ Tư',
    'Thứ Năm',
    'Thứ Sáu',
    'Thứ Bảy',
  ];

  // INIT

  @override
  void initState() {
    super.initState();

    _load();

    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();

    super.dispose();
  }

  // LOAD DATA

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final result = await ApiService.get(
        '/api/admin/reports/overview?days=$_days',
        bearerToken: AuthState.instance.token,
      );

      if (!mounted) return;

      final dynamic raw = result.data;

      if (!result.success || raw is! Map) {
        setState(() {
          _isLoading = false;
          _error = result.errorMessage ?? 'Không thể tải số liệu.';
        });

        return;
      }

      setState(() {
        _overview = _Overview.fromJson(raw);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load admin overview error: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = 'Không thể tải số liệu. Vui lòng thử lại.';
      });
    }
  }

  void _changeDays(int days) {
    if (_days == days) return;

    _days = days;

    _load();
  }

  // LOGOUT

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
    if (!mounted) return;

    _logout();
  }

  void _logout() {
    // Xóa token và thông tin đăng nhập.
    AuthState.instance.clear();

    // Quay về màn hình đăng nhập và xóa toàn bộ lịch sử màn hình cũ,
    // để bấm Back không quay lại trang admin được.
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
      backgroundColor: _bg,

      drawer: isDesktop ? null : Drawer(width: 270, child: _buildSidebar()),

      body: SafeArea(
        child: Row(
          children: [
            if (isDesktop) SizedBox(width: 260, child: _buildSidebar()),

            Expanded(
              child: Column(
                children: [
                  _buildUserMenu(isDesktop),

                  Expanded(child: _buildMainContent(isDesktop)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      color: const Color(0xFF0D2858),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 18, 28),
            child: Row(
              children: [
                // LOGO ATTENDGO
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  padding: const EdgeInsets.all(6),
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
                  selected: true,
                  onTap: () {},
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
                      onTap: () => _push(const FaceManagementScreen()),
                    ),
                  ],
                ),

                _navSection(
                  icon: Icons.access_time_rounded,
                  title: 'Chấm công',
                  children: [
                    _navSubItem(
                      title: 'Cấu hình IP & GPS',
                      onTap: () => _push(const IpConfigScreen()),
                    ),
                  ],
                ),

                _navItem(
                  icon: Icons.bar_chart_rounded,
                  title: 'Báo cáo',
                  onTap: () => _push(const AttendanceReportScreen()),
                ),

                const SizedBox(height: 8),

                _navSection(
                  icon: Icons.assignment_rounded,
                  title: 'Yêu cầu',
                  children: [
                    _navSubItem(
                      title: 'Đổi ca',
                      onTap: () => _push(const ShiftChangeApprovalScreen()),
                    ),

                    _navSubItem(
                      title: 'Nghỉ phép',
                      onTap: () => _push(const LeaveApprovalScreen()),
                    ),

                    _navSubItem(
                      title: 'Công tác',
                      onTap: () => _push(const BusinessTripApprovalScreen()),
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
                const Divider(color: Color(0xFF29436D)),

                _navItem(
                  icon: Icons.lock_outline_rounded,
                  title: 'Đổi mật khẩu',
                  onTap: () => _push(const ChangePasswordScreen()),
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

  Widget _navItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFFD6E4FA),
    bool selected = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? const Color(0xFF246BDE) : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected ? Colors.white : iconColor,
                  size: 21,
                ),

                const SizedBox(width: 13),

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

  Widget _navSubItem({
    required String title,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: selected ? const Color(0xFF246BDE) : Colors.transparent,
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

  // NAVIGATION

  void _push(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  // CONTENT

  Widget _buildMainContent(bool isDesktop) {
    final padding = isDesktop ? 24.0 : 16.0;

    return RefreshIndicator(
      color: _brightBlue,

      onRefresh: _load,

      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth - padding * 2;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),

            padding: EdgeInsets.all(padding),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                _buildHeader(isDesktop),

                const SizedBox(height: 16),

                _buildTopRow(w),

                const SizedBox(height: 16),

                if (_error != null) ...[
                  _buildErrorBanner(_error!),

                  const SizedBox(height: 16),
                ],

                _buildMiddleRow(w),

                const SizedBox(height: 16),

                _buildBottomRow(w),
              ],
            ),
          );
        },
      ),
    );
  }

  // HEADER

  Widget _buildHeader(bool isDesktop) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,

      children: [
        if (!isDesktop) ...[
          IconButton(
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),

            icon: const Icon(Icons.menu_rounded, color: _navy, size: 28),

            padding: EdgeInsets.zero,

            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),

          const SizedBox(width: 8),
        ],

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Row(
                children: [
                  Text(
                    'Xin chào',

                    style: TextStyle(
                      color: _navy,
                      fontSize: isDesktop ? 26 : 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(width: 8),

                  Text('👋', style: TextStyle(fontSize: isDesktop ? 24 : 20)),
                ],
              ),

              const SizedBox(height: 3),

              Text(
                'Chúc bạn có một ngày làm việc hiệu quả!',

                maxLines: 2,

                overflow: TextOverflow.ellipsis,

                style: TextStyle(
                  color: _textBlue,
                  fontSize: isDesktop ? 14 : 12,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        _buildBell(),

        const SizedBox(width: 10),

        _buildUserMenu(isDesktop),
      ],
    );
  }

  // CHUÔNG: số đơn đang chờ duyệt

  Widget _buildBell() {
    final o = _overview;

    final shift = o?.pendingShift ?? 0;

    final count = (o?.pendingLeave ?? 0) + (o?.pendingTrip ?? 0) + shift;

    String n(int? v) => v == null ? '–' : '$v';

    return PopupMenuButton<String>(
      tooltip: 'Yêu cầu chờ duyệt',

      offset: const Offset(0, 46),

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),

      onSelected: (value) {
        if (value == 'shift') {
          _push(const ShiftChangeApprovalScreen());
        } else if (value == 'leave') {
          _push(const LeaveApprovalScreen());
        } else if (value == 'trip') {
          _push(const BusinessTripApprovalScreen());
        }
      },

      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'shift',
          child: Text('Đổi ca làm việc (${n(o?.pendingShift)})'),
        ),

        PopupMenuItem<String>(
          value: 'leave',
          child: Text('Nghỉ phép (${n(o?.pendingLeave)})'),
        ),

        PopupMenuItem<String>(
          value: 'trip',
          child: Text('Công tác (${n(o?.pendingTrip)})'),
        ),
      ],

      child: SizedBox(
        width: 44,
        height: 44,

        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,

          children: [
            const Icon(
              Icons.notifications_none_rounded,
              color: _navy,
              size: 28,
            ),

            if (count > 0)
              Positioned(
                top: 2,
                right: 2,

                child: Container(
                  constraints: const BoxConstraints(minWidth: 18),

                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),

                  decoration: BoxDecoration(
                    color: _red,
                    borderRadius: BorderRadius.circular(9),
                  ),

                  child: Text(
                    '$count',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserMenu(bool showName) {
    final name = (AuthState.instance.fullName ?? '').trim();

    final avatarUrl = (AuthState.instance.avatarUrl ?? '').trim();

    // Chữ cái đầu của tên đầu và tên cuối. Ví dụ "Nguyễn Văn A" -> "NA".
    String initials() {
      final parts = name
          .split(RegExp(r'\s+'))
          .where((p) => p.isNotEmpty)
          .toList();

      if (parts.isEmpty) return 'AD';

      if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();

      return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
          .toUpperCase();
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
                errorBuilder: (context, error, stackTrace) => initialAvatar(),
              ),
            )
          : initialAvatar(),
    );

    return PopupMenuButton<String>(
      tooltip: '',

      offset: const Offset(0, 50),

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),

      onSelected: (value) {
        if (value == 'password') {
         _push(const ChangePasswordScreen()) ;
        } else if (value == 'logout') {
          _confirmLogout();
        }
      },

      itemBuilder: (context) => const [
        PopupMenuItem<String>(
          value: 'password',

          child: Row(
            children: [
              Icon(Icons.lock_rounded, size: 20, color: _textBlue),

              SizedBox(width: 10),

              Text('Đổi mật khẩu'),
            ],
          ),
        ),

        PopupMenuItem<String>(
          value: 'logout',

          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 20, color: Color(0xFFE03131)),

              SizedBox(width: 10),

              Text('Đăng xuất', style: TextStyle(color: Color(0xFFE03131))),
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
              constraints: const BoxConstraints(maxWidth: 140),

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

          const Icon(Icons.keyboard_arrow_down, color: _navy),
        ],
      ),
    );
  }

  // HÀNG TRÊN: BANNER + NGÀY GIỜ

  Widget _buildTopRow(double w) {
    final banner = _buildBanner(w >= 900);

    final dateBox = _buildDateBox();

    if (w >= 900) {
      return SizedBox(
        height: 140,

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [
            Expanded(flex: 3, child: banner),

            const SizedBox(width: 16),

            Expanded(flex: 1, child: dateBox),
          ],
        ),
      );
    }

    return Column(children: [banner, const SizedBox(height: 16), dateBox]);
  }

  Widget _buildBanner(bool fixedHeight) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFDDEBFF), Color(0xFFEFF5FF)],
        ),

        borderRadius: BorderRadius.circular(22),

        border: Border.all(color: const Color(0xFFD1E1FA)),
      ),

      child: Stack(
        children: [
          Positioned(
            right: 8,
            top: -6,

            child: Icon(
              Icons.laptop_chromebook_rounded,
              size: 120,
              color: _brightBlue.withValues(alpha: 0.10),
            ),
          ),

          Row(
            children: [
              Container(
                width: 64,
                height: 64,

                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.apartment_rounded,
                  color: _brightBlue,
                  size: 34,
                ),
              ),

              const SizedBox(width: 18),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    const Text(
                      'HỆ THỐNG DOANH NGHIỆP',
                      style: TextStyle(
                        color: _navy,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),

                    const SizedBox(height: 2),

                    const Text(
                      'AttendGo',
                      style: TextStyle(
                        color: _navy,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      'Quản lý tập trung - Hiệu quả vượt trội',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _textBlue,
                        fontSize: fixedHeight ? 14.5 : 13,
                      ),
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

  Widget _buildDateBox() {
    final dateText =
        '${_weekdays[_now.weekday % 7]}, '
        '${_now.day.toString().padLeft(2, '0')}/'
        '${_now.month.toString().padLeft(2, '0')}/${_now.year}';

    final timeText =
        '${_now.hour.toString().padLeft(2, '0')}:'
        '${_now.minute.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),

      decoration: _cardDecoration(),

      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,

            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(14),
            ),

            child: const Icon(
              Icons.calendar_month_rounded,
              color: _navy,
              size: 28,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  dateText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  timeText,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ERROR

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: const Color(0xFFFFD6D6)),
      ),

      child: Row(
        children: [
          const Icon(Icons.error_outline, color: _red, size: 24),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: _navy, fontSize: 13),
            ),
          ),

          TextButton.icon(
            onPressed: _load,

            icon: const Icon(Icons.refresh, size: 18),

            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  // HÀNG GIỮA: BIỂU ĐỒ 7 NGÀY + HÔM NAY + LOẠI YÊU CẦU

  Widget _buildMiddleRow(double w) {
    if (w >= 1000) {
      return SizedBox(
        height: 360,

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [
            Expanded(flex: 5, child: _buildTrendCard(fixed: true)),

            const SizedBox(width: 16),

            Expanded(flex: 4, child: _buildTodayCard()),

            const SizedBox(width: 16),

            Expanded(flex: 4, child: _buildRequestTypesCard()),
          ],
        ),
      );
    }

    if (w >= 640) {
      return Column(
        children: [
          _buildTrendCard(fixed: false),

          const SizedBox(height: 16),

          SizedBox(
            height: 360,

            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,

              children: [
                Expanded(child: _buildTodayCard()),

                const SizedBox(width: 16),

                Expanded(child: _buildRequestTypesCard()),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildTrendCard(fixed: false),

        const SizedBox(height: 16),

        _buildTodayCard(),

        const SizedBox(height: 16),

        _buildRequestTypesCard(),
      ],
    );
  }

  // THẺ: TÌNH HÌNH CHẤM CÔNG N NGÀY GẦN ĐÂY

  Widget _buildTrendCard({required bool fixed}) {
    final points = _overview?.trend ?? const <_TrendPoint>[];

    Widget chart;

    if (_isLoading && _overview == null) {
      chart = const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2.6,
            color: _brightBlue,
          ),
        ),
      );
    } else if (points.isEmpty) {
      chart = const Center(
        child: Text(
          'Chưa có dữ liệu chấm công.',
          style: TextStyle(color: _textGrey, fontSize: 13),
        ),
      );
    } else {
      chart = CustomPaint(
        size: Size.infinite,
        painter: _LineChartPainter(points: points),
      );
    }

    final dropdown = Container(
      height: 36,

      padding: const EdgeInsets.symmetric(horizontal: 10),

      decoration: BoxDecoration(
        color: const Color(0xFFF1F6FF),

        borderRadius: BorderRadius.circular(10),

        border: Border.all(color: const Color(0xFFCFDDF5)),
      ),

      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _days,

          isDense: true,

          icon: const Icon(Icons.keyboard_arrow_down, color: _navy, size: 20),

          borderRadius: BorderRadius.circular(10),

          items: const [
            DropdownMenuItem(
              value: 7,
              child: Text('7 ngày qua', style: TextStyle(fontSize: 12.5)),
            ),

            DropdownMenuItem(
              value: 14,
              child: Text('14 ngày qua', style: TextStyle(fontSize: 12.5)),
            ),

            DropdownMenuItem(
              value: 30,
              child: Text('30 ngày qua', style: TextStyle(fontSize: 12.5)),
            ),
          ],

          style: const TextStyle(color: _navy, fontWeight: FontWeight.w600),

          onChanged: (value) {
            if (value == null) return;

            _changeDays(value);
          },
        ),
      ),
    );

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: _cardDecoration(),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              _titleIcon(Icons.bar_chart_rounded),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  'Tình hình chấm công $_days ngày gần đây',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              dropdown,
            ],
          ),

          const SizedBox(height: 14),

          if (fixed)
            Expanded(child: chart)
          else
            SizedBox(height: 240, child: chart),
        ],
      ),
    );
  }

  Widget _titleIcon(IconData icon) {
    return Container(
      width: 34,
      height: 34,

      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(10),
      ),

      child: Icon(icon, color: _brightBlue, size: 20),
    );
  }

  // THẺ: TÌNH HÌNH CHẤM CÔNG HÔM NAY

  Widget _buildTodayCard() {
    final o = _overview;

    final loading = o == null;

    String v(int? x) => loading ? '...' : '${x ?? 0}';

    final total = o?.todayTotal ?? 0;

    String pct(int value) {
      if (loading || total == 0) return '(0%)';

      return '(${(value * 100 / total).toStringAsFixed(1)}%)';
    }

    final onTime = o?.today[0] ?? 0;

    final late = o?.today[1] ?? 0;

    Widget statColumn({
      required IconData icon,
      required Color color,
      required String label,
      required int value,
    }) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,

                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),

                  child: Icon(icon, color: Colors.white, size: 15),
                ),

                const SizedBox(width: 8),

                Text(
                  label,
                  style: const TextStyle(color: _textBlue, fontSize: 13.5),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              v(value),
              style: TextStyle(
                color: color,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),

            const SizedBox(height: 2),

            Text(pct(value), style: TextStyle(color: color, fontSize: 13)),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: _cardDecoration(),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              _titleIcon(Icons.access_time_rounded),

              const SizedBox(width: 10),

              const Expanded(
                child: Text(
                  'Tình hình chấm công hôm nay',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _navy,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Container(
                width: 58,
                height: 58,

                decoration: const BoxDecoration(
                  color: Color(0xFFEAF2FF),
                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.access_time_rounded,
                  color: _brightBlue,
                  size: 30,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      v(total),
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),

                    const Text(
                      'Tổng số lượt chấm công',
                      style: TextStyle(color: _textGrey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: Color(0xFFE6EDF8)),
          ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              statColumn(
                icon: Icons.check_rounded,
                color: _green,
                label: 'Đúng giờ',
                value: onTime,
              ),

              Container(
                width: 1,
                height: 84,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: const Color(0xFFE6EDF8),
              ),

              statColumn(
                icon: Icons.priority_high_rounded,
                color: _red,
                label: 'Đi trễ',
                value: late,
              ),
            ],
          ),

          const Spacer(),

          Material(
            color: const Color(0xFFEAF2FF),

            borderRadius: BorderRadius.circular(12),

            child: InkWell(
              borderRadius: BorderRadius.circular(12),

              onTap: () => _push(const AttendanceReportScreen()),

              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),

                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Xem chi tiết báo cáo',
                        style: TextStyle(
                          color: _brightBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    Icon(Icons.chevron_right, color: _brightBlue, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // THẺ: TÌNH HÌNH CÁC LOẠI YÊU CẦU (đang chờ duyệt)

  Widget _buildRequestTypesCard() {
    final o = _overview;

    final loading = o == null;

    final shift = o?.pendingShift;

    final leave = o?.pendingLeave;

    final trip = o?.pendingTrip;

    final total = (shift ?? 0) + (leave ?? 0) + (trip ?? 0);

    String count(int? x) => loading ? '...' : (x == null ? '–' : '$x');

    String pct(int? x) {
      if (loading || x == null) return '';

      if (total == 0) return '(0%)';

      return '(${(x * 100 / total).toStringAsFixed(1)}%)';
    }

    Widget row({
      required IconData icon,
      required Color color,
      required String label,
      required int? value,
      required bool last,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10),

        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: Color(0xFFEDF2FA))),
        ),

        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,

              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),

              child: Icon(icon, color: color, size: 21),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: _navy, fontSize: 13.5),
              ),
            ),

            Text(
              count(value),
              style: const TextStyle(
                color: _navy,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(width: 8),

            SizedBox(
              width: 58,
              child: Text(
                pct(value),
                textAlign: TextAlign.right,
                style: const TextStyle(color: _textGrey, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: _cardDecoration(),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              _titleIcon(Icons.description_rounded),

              const SizedBox(width: 10),

              const Expanded(
                child: Text(
                  'Tình hình các loại yêu cầu',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _navy,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          row(
            icon: Icons.swap_horiz_rounded,
            color: _orange,
            label: 'Đổi ca làm việc',
            value: shift,
            last: false,
          ),

          row(
            icon: Icons.beach_access,
            color: _purple,
            label: 'Nghỉ phép',
            value: leave,
            last: false,
          ),

          row(
            icon: Icons.flight,
            color: _lightBlue,
            label: 'Công tác',
            value: trip,
            last: true,
          ),
        ],
      ),
    );
  }

  // HÀNG DƯỚI: YÊU CẦU CHỜ DUYỆT + GIỚI THIỆU

  Widget _buildBottomRow(double w) {
    if (w >= 900) {
      return SizedBox(
        height: 330,

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [
            Expanded(flex: 5, child: _buildPendingCard()),

            const SizedBox(width: 16),

            Expanded(flex: 6, child: _buildPromoCard()),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildPendingCard(),

        const SizedBox(height: 16),

        SizedBox(height: 220, child: _buildPromoCard()),
      ],
    );
  }

  Widget _buildPendingCard() {
    final o = _overview;

    final loading = o == null;

    String count(int? x) => loading ? '...' : (x == null ? '–' : '$x');

    Widget item({
      required IconData icon,
      required Color color,
      required String label,
      required int? value,
      required VoidCallback onTap,
    }) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),

        child: Material(
          color: Colors.white,

          borderRadius: BorderRadius.circular(14),

          child: InkWell(
            borderRadius: BorderRadius.circular(14),

            onTap: onTap,

            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),

              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE4EBF6)),
              ),

              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,

                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),

                    child: Icon(icon, color: color, size: 22),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(color: _navy, fontSize: 14),
                    ),
                  ),

                  Container(
                    constraints: const BoxConstraints(minWidth: 34),

                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),

                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                    ),

                    child: Text(
                      count(value),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  const Icon(Icons.chevron_right, color: _textGrey, size: 22),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: _cardDecoration(),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              _titleIcon(Icons.description_rounded),

              const SizedBox(width: 10),

              const Expanded(
                child: Text(
                  'Yêu cầu chờ duyệt',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          item(
            icon: Icons.swap_horiz_rounded,
            color: _orange,
            label: 'Đổi ca làm việc',
            value: o?.pendingShift,
            onTap: () => _push(const ShiftChangeApprovalScreen()),
          ),

          item(
            icon: Icons.beach_access,
            color: _purple,
            label: 'Nghỉ phép',
            value: o?.pendingLeave,
            onTap: () => _push(const LeaveApprovalScreen()),
          ),

          item(
            icon: Icons.flight,
            color: _lightBlue,
            label: 'Công tác',
            value: o?.pendingTrip,
            onTap: () => _push(const BusinessTripApprovalScreen()),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCard() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(24),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE3EEFF), Color(0xFFF3F8FF)],
        ),

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: const Color(0xFFD1E1FA)),
      ),

      child: Stack(
        children: [
          Positioned(
            right: 0,
            bottom: 0,

            child: Icon(
              Icons.insights_rounded,
              size: 150,
              color: _brightBlue.withValues(alpha: 0.10),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              const Text(
                'Hiệu suất tốt hơn\ncùng AttendGo',
                style: TextStyle(
                  color: _navy,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Hệ thống chấm công thông minh giúp doanh nghiệp\n'
                'quản lý nhân sự hiệu quả, minh bạch và chính xác.',
                style: TextStyle(color: _textBlue, fontSize: 13, height: 1.45),
              ),

              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: () => _push(const AttendanceReportScreen()),

                icon: const Icon(Icons.arrow_forward_rounded, size: 18),

                label: const Text(
                  'Xem báo cáo',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),

                style: ElevatedButton.styleFrom(
                  backgroundColor: _brightBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,

      borderRadius: BorderRadius.circular(18),

      border: Border.all(color: _border),

      boxShadow: [
        BoxShadow(
          color: const Color(0xFF47679C).withValues(alpha: 0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

// CHART HELPERS

void _drawText(
  Canvas canvas,
  String text,
  TextStyle style,
  Offset at, {
  double anchorX = 0.5,
  double anchorY = 0.5,
}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();

  painter.paint(
    canvas,
    Offset(at.dx - painter.width * anchorX, at.dy - painter.height * anchorY),
  );
}

double _niceStep(double x) {
  if (x <= 0) return 1;

  final exp = math.pow(10, (math.log(x) / math.ln10).floor()).toDouble();

  final f = x / exp;

  final nf = f <= 1 ? 1.0 : (f <= 2 ? 2.0 : (f <= 5 ? 5.0 : 10.0));

  final step = nf * exp;

  return step < 1 ? 1 : step;
}

// LINE CHART PAINTER (đường cong + vùng tô + điểm)

class _LineChartPainter extends CustomPainter {
  final List<_TrendPoint> points;

  _LineChartPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    const left = 36.0;
    const right = 14.0;
    const top = 10.0;
    const bottom = 24.0;

    final w = size.width - left - right;
    final h = size.height - top - bottom;

    if (w <= 0 || h <= 0 || points.isEmpty) return;

    var maxValue = 0;

    for (final p in points) {
      maxValue = math.max(maxValue, p.value);
    }

    final step = _niceStep(maxValue <= 0 ? 1 : maxValue / 4);

    final maxY = step * 4;

    // GRID + NHÃN TRỤC Y

    final gridPaint = Paint()
      ..color = const Color(0xFFE4EBF6)
      ..strokeWidth = 1;

    for (var i = 0; i <= 4; i++) {
      final y = top + h - h * i / 4;

      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );

      _drawText(
        canvas,
        '${(step * i).round()}',
        const TextStyle(color: _textGrey, fontSize: 10.5),
        Offset(left - 6, y),
        anchorX: 1,
      );
    }

    // TỌA ĐỘ CÁC ĐIỂM

    final n = points.length;

    Offset pos(int i) {
      final x = n == 1 ? left + w / 2 : left + w * i / (n - 1);

      final y = top + h - h * points[i].value / maxY;

      return Offset(x, y);
    }

    final path = Path()..moveTo(pos(0).dx, pos(0).dy);

    for (var i = 1; i < n; i++) {
      final p0 = pos(i - 1);
      final p1 = pos(i);

      final cx = (p0.dx + p1.dx) / 2;

      path.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
    }

    // VÙNG TÔ DƯỚI ĐƯỜNG

    final fill = Path.from(path)
      ..lineTo(pos(n - 1).dx, top + h)
      ..lineTo(pos(0).dx, top + h)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF2864E8).withValues(alpha: 0.22),
            const Color(0xFF2864E8).withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromLTWH(left, top, w, h)),
    );

    // ĐƯỜNG

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF2864E8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );

    // ĐIỂM + NHÃN TRỤC X

    final labelEvery = n <= 8 ? 1 : (n / 6).ceil();

    for (var i = 0; i < n; i++) {
      final p = pos(i);

      canvas.drawCircle(p, 4.4, Paint()..color = Colors.white);

      canvas.drawCircle(p, 3.4, Paint()..color = const Color(0xFF2864E8));

      if (i % labelEvery == 0) {
        _drawText(
          canvas,
          points[i].label,
          const TextStyle(color: _textGrey, fontSize: 10.5),
          Offset(p.dx, top + h + 6),
          anchorY: 0,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) => true;
}
