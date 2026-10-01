import 'dart:async';

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

const Color _sidebarBg = Color(0xFF13307F);
const Color _brightBlue = Color(0xFF2864E8);
const Color _bg = Color(0xFFF5F9FF);
const Color _navy = Color(0xFF12348F);
const Color _textBlue = Color(0xFF31589D);
const Color _textGrey = Color(0xFF7185A8);
const Color _border = Color(0xFFE2EAF7);
const Color _green = Color(0xFF1FA971);
const Color _red = Color(0xFFEF4444);

int _toInt(dynamic v) {
  if (v is num) return v.toInt();

  return int.tryParse('${v ?? ''}') ?? 0;
}

// STAT CARD META
//
// Thứ tự: 0 Tổng nhân viên, 1 Đúng giờ, 2 Đi trễ, 3 Không đi làm,
//         4 Đi công tác, 5 Nghỉ phép, 6 Khác

class _CardMeta {
  final String label;
  final IconData icon;
  final Color color;
  final Color background;

  // true  = tăng là tốt
  // false = tăng là xấu
  // null  = trung tính
  final bool? positiveIsGood;

  const _CardMeta(
    this.label,
    this.icon,
    this.color,
    this.background,
    this.positiveIsGood,
  );
}

const List<_CardMeta> _cardMetas = [
  _CardMeta(
    'Tổng nhân viên',
    Icons.groups_rounded,
    Color(0xFF2864E8),
    Color(0xFFE2EBFF),
    null,
  ),
  _CardMeta(
    'Đúng giờ',
    Icons.check_circle,
    Color(0xFF1FA971),
    Color(0xFFE3F7EE),
    true,
  ),
  _CardMeta(
    'Đi trễ',
    Icons.access_time_filled,
    Color(0xFFF5A623),
    Color(0xFFFFF1D9),
    false,
  ),
  _CardMeta(
    'Không đi làm',
    Icons.cancel,
    Color(0xFFEF4444),
    Color(0xFFFFE6E6),
    false,
  ),
  _CardMeta(
    'Đi công tác',
    Icons.flight,
    Color(0xFF3B82F6),
    Color(0xFFE2EEFF),
    null,
  ),
  _CardMeta(
    'Nghỉ phép',
    Icons.beach_access,
    Color(0xFF8B5CF6),
    Color(0xFFEFE8FF),
    null,
  ),
  _CardMeta('Khác', Icons.person, Color(0xFF8792A8), Color(0xFFE9EDF4), null),
];

class _MenuChild {
  final String label;
  final VoidCallback onTap;

  _MenuChild(this.label, this.onTap);
}

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // STATE

  bool _isLoadingStats = true;

  String? _statsError;

  int _totalEmployees = 0;

  // 6 giá trị: onTime, late, absent, businessTrip, leave, other
  List<int> _today = List<int>.filled(6, 0);

  List<int> _previous = List<int>.filled(6, 0);

  // Các nhóm menu đang mở.
  final Set<String> _expanded = {'employees', 'attendance', 'requests'};

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

    _loadStats();

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
  //
  // Dùng API báo cáo ở chế độ "ngày" (hôm nay), chỉ lấy số liệu tổng hợp.

  Future<void> _loadStats() async {
    if (mounted) {
      setState(() {
        _isLoadingStats = true;
        _statsError = null;
      });
    }

    try {
      final result = await ApiService.get(
        '/api/admin/reports/attendance?mode=day&page=1&pageSize=1',
        bearerToken: AuthState.instance.token,
      );

      if (!mounted) return;

      final dynamic raw = result.data;

      if (!result.success || raw is! Map) {
        setState(() {
          _isLoadingStats = false;
          _statsError = result.errorMessage ?? 'Không thể tải số liệu.';
        });

        return;
      }

      setState(() {
        _totalEmployees = _toInt(raw['totalEmployees']);
        _today = _parseCounts(raw['summary']);
        _previous = _parseCounts(raw['previousSummary']);
        _isLoadingStats = false;
      });
    } catch (e) {
      debugPrint('Load admin stats error: $e');

      if (!mounted) return;

      setState(() {
        _isLoadingStats = false;
        _statsError = 'Không thể tải số liệu. Vui lòng thử lại.';
      });
    }
  }

  List<int> _parseCounts(dynamic j) {
    if (j is! Map) return List<int>.filled(6, 0);

    return [
      _toInt(j['onTime']),
      _toInt(j['late']),
      _toInt(j['absent']),
      _toInt(j['businessTrip']),
      _toInt(j['leave']),
      _toInt(j['other']),
    ];
  }

  // NAVIGATION

  void _go(Widget Function() builder, bool inDrawer) {
    if (inDrawer) {
      Navigator.of(context).pop();
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => builder())).then((
      _,
    ) {
      if (mounted) {
        _loadStats();
      }
    });
  }

  void _openFaceManagement(bool inDrawer) {
    final token = AuthState.instance.token;

    if (token == null || token.isEmpty) {
      if (inDrawer) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phiên đăng nhập không hợp lệ.')),
      );

      return;
    }

    _go(() => FaceManagementScreen(token: token), inDrawer);
  }

  // LOGOUT

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
            style: TextStyle(fontWeight: FontWeight.w800),
          ),

          content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),

          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Hủy'),
            ),

            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
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
    return Scaffold(
      key: _scaffoldKey,

      backgroundColor: _bg,

      drawer: Drawer(
        width: 280,
        backgroundColor: _sidebarBg,
        child: _buildMenu(inDrawer: true),
      ),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;

            final content = _buildContent(wide);

            if (!wide) return content;

            return Row(
              children: [
                SizedBox(width: 250, child: _buildMenu(inDrawer: false)),

                Expanded(child: content),
              ],
            );
          },
        ),
      ),
    );
  }

  // SIDEBAR / DRAWER

  Widget _buildMenu({required bool inDrawer}) {
    return Container(
      color: _sidebarBg,

      child: SafeArea(
        child: Column(
          children: [
            // LOGO
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),

              child: Container(
                height: 66,

                width: double.infinity,

                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),

                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Text(
                        'AttendGo',
                        style: TextStyle(
                          color: _navy,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 6),

            // MENU
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),

                children: [
                  _menuTile(
                    icon: Icons.home_rounded,
                    label: 'Trang chủ',
                    selected: true,
                    onTap: () {
                      if (inDrawer) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),

                  _menuGroup(
                    id: 'employees',
                    icon: Icons.groups_rounded,
                    label: 'Nhân viên',
                    children: [
                      _MenuChild(
                        'Danh sách nhân viên',
                        () => _go(() => const EmployeeListScreen(), inDrawer),
                      ),

                      _MenuChild(
                        'Thêm khuôn mặt chấm công',
                        () => _openFaceManagement(inDrawer),
                      ),
                    ],
                  ),

                  _menuGroup(
                    id: 'attendance',
                    icon: Icons.access_time_rounded,
                    label: 'Chấm công',
                    children: [
                      _MenuChild(
                        'Cấu hình WiFi & GPS',
                        () => _go(() => const IpConfigScreen(), inDrawer),
                      ),
                    ],
                  ),

                  _menuTile(
                    icon: Icons.bar_chart_rounded,
                    label: 'Báo cáo',
                    onTap: () =>
                        _go(() => const AttendanceReportScreen(), inDrawer),
                  ),

                  _menuGroup(
                    id: 'requests',
                    icon: Icons.description_rounded,
                    label: 'Yêu cầu',
                    children: [
                      _MenuChild(
                        'Đổi ca làm việc',
                        () => _go(
                          () => const ShiftChangeApprovalScreen(),
                          inDrawer,
                        ),
                      ),

                      _MenuChild(
                        'Nghỉ phép',
                        () => _go(() => const LeaveApprovalScreen(), inDrawer),
                      ),

                      _MenuChild(
                        'Công tác',
                        () => _go(
                          () => const BusinessTripApprovalScreen(),
                          inDrawer,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white24, height: 1),

            // TÀI KHOẢN
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),

              child: Column(
                children: [
                  _menuTile(
                    icon: Icons.lock_rounded,
                    label: 'Đổi mật khẩu',
                    onTap: () =>
                        _go(() => const ChangePasswordScreen(), inDrawer),
                  ),

                  _menuTile(
                    icon: Icons.logout_rounded,
                    label: 'Đăng xuất',
                    onTap: () {
                      if (inDrawer) {
                        Navigator.of(context).pop();
                      }

                      _confirmLogout();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool selected = false,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),

      child: Material(
        color: selected ? _brightBlue : Colors.transparent,

        borderRadius: BorderRadius.circular(12),

        child: InkWell(
          borderRadius: BorderRadius.circular(12),

          onTap: onTap,

          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),

            child: Row(
              children: [
                Icon(icon, size: 22, color: Colors.white),

                const SizedBox(width: 14),

                Expanded(
                  child: Text(
                    label,

                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                if (trailing != null) trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuGroup({
    required String id,
    required IconData icon,
    required String label,
    required List<_MenuChild> children,
  }) {
    final expanded = _expanded.contains(id);

    return Column(
      children: [
        _menuTile(
          icon: icon,
          label: label,

          trailing: Icon(
            expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            color: Colors.white70,
            size: 22,
          ),

          onTap: () {
            setState(() {
              if (expanded) {
                _expanded.remove(id);
              } else {
                _expanded.add(id);
              }
            });
          },
        ),

        if (expanded) ...children.map(_menuChildTile),
      ],
    );
  }

  Widget _menuChildTile(_MenuChild child) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),

      onTap: child.onTap,

      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 11, 12, 11),

        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,

              decoration: const BoxDecoration(
                color: Colors.white54,
                shape: BoxShape.circle,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Text(
                child.label,

                style: const TextStyle(color: Colors.white70, fontSize: 13.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // CONTENT

  Widget _buildContent(bool wide) {
    final padding = wide ? 24.0 : 16.0;

    return RefreshIndicator(
      color: _brightBlue,

      onRefresh: _loadStats,

      child: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth = constraints.maxWidth - padding * 2;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),

            padding: EdgeInsets.all(padding),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                _buildHeader(wide),

                const SizedBox(height: 16),

                _buildBanner(contentWidth),

                const SizedBox(height: 16),

                if (_statsError != null) ...[
                  _buildErrorBanner(_statsError!),

                  const SizedBox(height: 16),
                ],

                _buildStatCards(contentWidth),

                const SizedBox(height: 16),

                if (contentWidth >= 820)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Expanded(flex: 2, child: _buildQuickActions()),

                      const SizedBox(width: 16),

                      Expanded(flex: 1, child: _buildSystemInfo()),
                    ],
                  )
                else ...[
                  _buildQuickActions(),

                  const SizedBox(height: 16),

                  _buildSystemInfo(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // HEADER

  Widget _buildHeader(bool wide) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,

      children: [
        if (!wide) ...[
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
              Text(
                'Quản trị hệ thống',

                maxLines: 1,

                overflow: TextOverflow.ellipsis,

                style: TextStyle(
                  color: _navy,
                  fontSize: wide ? 26 : 20,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                'Tổng quan tình hình chấm công và hoạt động công ty',

                maxLines: 2,

                overflow: TextOverflow.ellipsis,

                style: TextStyle(color: _textBlue, fontSize: wide ? 14 : 12),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        _buildUserMenu(wide),
      ],
    );
  }

  Widget _buildUserMenu(bool showName) {
    final name = (AuthState.instance.fullName ?? '').trim();

    final avatarUrl = (AuthState.instance.avatarUrl ?? '').trim();

    final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'A';

    Widget initialAvatar() {
      return Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: _navy,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    final avatar = Container(
      width: 42,
      height: 42,

      decoration: const BoxDecoration(
        color: Color(0xFFDCEBFF),
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
          _go(() => const ChangePasswordScreen(), false);
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
              constraints: const BoxConstraints(maxWidth: 150),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    name.isEmpty ? 'Quản trị viên' : name,

                    maxLines: 1,

                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(
                      color: _navy,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const Text(
                    'Quản trị viên',
                    style: TextStyle(color: _textGrey, fontSize: 11.5),
                  ),
                ],
              ),
            ),
          ],

          const Icon(Icons.keyboard_arrow_down, color: _textGrey),
        ],
      ),
    );
  }

  // BANNER

  Widget _buildBanner(double contentWidth) {
    final name = (AuthState.instance.fullName ?? '').trim();

    final dateText =
        '${_weekdays[_now.weekday % 7]}, '
        '${_now.day.toString().padLeft(2, '0')}/'
        '${_now.month.toString().padLeft(2, '0')}/${_now.year}';

    final timeText =
        '${_now.hour.toString().padLeft(2, '0')}:'
        '${_now.minute.toString().padLeft(2, '0')}';

    final greeting = Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        const Row(
          mainAxisSize: MainAxisSize.min,

          children: [
            Text(
              'Xin chào',
              style: TextStyle(
                color: _brightBlue,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            SizedBox(width: 6),

            Text('👋', style: TextStyle(fontSize: 18)),
          ],
        ),

        const SizedBox(height: 4),

        Text(
          name.isEmpty ? 'Quản trị viên' : name,

          maxLines: 1,

          overflow: TextOverflow.ellipsis,

          style: const TextStyle(
            color: _navy,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Chào mừng bạn quay lại hệ thống AttendGo',
          style: TextStyle(color: _textBlue, fontSize: 13.5),
        ),
      ],
    );

    final dateBox = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(14),

        border: Border.all(color: _border),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          const Icon(Icons.calendar_month_rounded, color: _navy, size: 26),

          const SizedBox(width: 12),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                dateText,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                timeText,
                style: const TextStyle(color: _textBlue, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFE3EEFF), Color(0xFFF1F6FF)],
        ),

        borderRadius: BorderRadius.circular(22),

        border: Border.all(color: const Color(0xFFD6E4FB)),
      ),

      child: contentWidth >= 640
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,

              children: [
                Expanded(child: greeting),
                dateBox,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [greeting, const SizedBox(height: 14), dateBox],
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
            onPressed: _loadStats,

            icon: const Icon(Icons.refresh, size: 18),

            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  // STAT CARDS

  Widget _buildStatCards(double width) {
    final cols = width >= 1000 ? 7 : (width >= 640 ? 4 : 2);

    const spacing = 12.0;

    final itemWidth = (width - spacing * (cols - 1)) / cols;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,

      children: List.generate(_cardMetas.length, (i) {
        return SizedBox(width: itemWidth, child: _buildStatCard(i));
      }),
    );
  }

  Widget _buildStatCard(int index) {
    final meta = _cardMetas[index];

    final isTotal = index == 0;

    final value = isTotal ? _totalEmployees : _today[index - 1];

    final previous = isTotal ? 0 : _previous[index - 1];

    return Container(
      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: _border),

        boxShadow: [
          BoxShadow(
            color: const Color(0xFF47679C).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,

                decoration: BoxDecoration(
                  color: meta.background,
                  shape: BoxShape.circle,
                ),

                child: Icon(meta.icon, color: meta.color, size: 19),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  meta.label,

                  maxLines: 2,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: _navy,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            _isLoadingStats ? '...' : '$value',

            style: TextStyle(
              color: meta.color,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),

          const SizedBox(height: 4),

          if (isTotal)
            const Text(
              'đang hoạt động',
              style: TextStyle(color: _textGrey, fontSize: 10.5),
            )
          else
            _buildDelta(value, previous, meta.positiveIsGood),
        ],
      ),
    );
  }

  Widget _buildDelta(int current, int previous, bool? positiveIsGood) {
    IconData? icon;

    Color color = _textGrey;

    String text;

    if (_isLoadingStats) {
      text = '';
    } else if (previous == 0) {
      if (current == 0) {
        text = '= 0%';
      } else {
        text = 'Mới';

        icon = Icons.arrow_upward_rounded;
      }
    } else {
      final pct = ((current - previous) / previous * 100).round();

      if (pct == 0) {
        text = '= 0%';
      } else {
        final up = pct > 0;

        icon = up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

        text = '${pct.abs()}%';

        if (positiveIsGood != null) {
          color = (up == positiveIsGood) ? _green : _red;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: color),

              const SizedBox(width: 2),
            ],

            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 2),

        const Text(
          'so với hôm trước',
          style: TextStyle(color: _textGrey, fontSize: 10.5),
        ),
      ],
    );
  }

  // THAO TÁC NHANH

  Widget _buildQuickActions() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: _cardDecoration(),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            'Thao tác nhanh',

            style: TextStyle(
              color: _navy,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 14),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Expanded(
                child: _buildQuickTile(
                  icon: Icons.groups_rounded,
                  label: 'Danh sách nhân viên',
                  color: const Color(0xFF2864E8),
                  background: const Color(0xFFEAF2FF),
                  onTap: () => _go(() => const EmployeeListScreen(), false),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _buildQuickTile(
                  icon: Icons.bar_chart_rounded,
                  label: 'Xem báo cáo',
                  color: const Color(0xFF7C4DFF),
                  background: const Color(0xFFF1ECFF),
                  onTap: () => _go(() => const AttendanceReportScreen(), false),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _buildQuickTile(
                  icon: Icons.description_rounded,
                  label: 'Duyệt yêu cầu',
                  color: const Color(0xFFFF8A1F),
                  background: const Color(0xFFFFF1E6),
                  onTap: () => _go(() => const LeaveApprovalScreen(), false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTile({
    required IconData icon,
    required String label,
    required Color color,
    required Color background,
    required VoidCallback onTap,
  }) {
    return Material(
      color: background,

      borderRadius: BorderRadius.circular(16),

      child: InkWell(
        borderRadius: BorderRadius.circular(16),

        onTap: onTap,

        child: Container(
          height: 128,

          padding: const EdgeInsets.all(12),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              Icon(icon, color: color, size: 34),

              const SizedBox(height: 10),

              Text(
                label,

                textAlign: TextAlign.center,

                maxLines: 2,

                overflow: TextOverflow.ellipsis,

                style: TextStyle(
                  color: color,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 8),

              Icon(Icons.arrow_forward_rounded, color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  // THÔNG TIN HỆ THỐNG

  Widget _buildSystemInfo() {
    final present = _today[0] + _today[1];

    final rate = _totalEmployees == 0
        ? '0%'
        : '${(present * 100 / _totalEmployees).toStringAsFixed(1)}%';

    String v(String text) => _isLoadingStats ? '...' : text;

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: _cardDecoration(),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            'Thông tin hệ thống',

            style: TextStyle(
              color: _navy,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          _buildInfoRow(
            Icons.groups_rounded,
            'Tổng số nhân viên',
            v('$_totalEmployees'),
          ),

          _buildInfoRow(
            Icons.how_to_reg_rounded,
            'Đã chấm công hôm nay',
            v('$present'),
          ),

          _buildInfoRow(
            Icons.verified_user_rounded,
            'Tỷ lệ chấm công',
            v(rate),
          ),

          _buildInfoRow(
            Icons.info_outline_rounded,
            'Phiên bản hệ thống',
            'v1.0.0',
            last: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool last = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),

      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFEDF2FA))),
      ),

      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,

            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(10),
            ),

            child: Icon(icon, color: _brightBlue, size: 19),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: _textBlue, fontSize: 13),
            ),
          ),

          Text(
            value,
            style: const TextStyle(
              color: _navy,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
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
