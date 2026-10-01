import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_state.dart';

import 'admin_home_screen.dart';
import 'employee_list_screen.dart';
import 'ip_config_screen.dart';
import 'leave_approval_screen.dart';
import 'change_password_screen.dart';
import 'login_screen.dart';

// COLORS

const Color _navy = Color(0xFF12348F);
const Color _blue = Color(0xFF1464E8);
const Color _bg = Color(0xFFF5F9FF);
const Color _textBlue = Color(0xFF31589D);
const Color _textGrey = Color(0xFF7185A8);
const Color _border = Color(0xFFE2EAF7);
const Color _green = Color(0xFF1FA971);
const Color _red = Color(0xFFEF4444);

// STATUS META
//
// Thứ tự cố định (khớp với _Counts.values):
// 0 OnTime, 1 Late, 2 Absent, 3 BusinessTrip, 4 Leave, 5 Other

class _StatusMeta {
  final String key;
  final String label;
  final String shortLabel;
  final Color color;
  final Color background;
  final IconData icon;

  const _StatusMeta(
    this.key,
    this.label,
    this.shortLabel,
    this.color,
    this.background,
    this.icon,
  );
}

const List<_StatusMeta> _statusList = [
  _StatusMeta(
    'OnTime',
    'Đi đúng giờ',
    'Đúng giờ',
    Color(0xFF1FA971),
    Color(0xFFE3F7EE),
    Icons.check_circle,
  ),
  _StatusMeta(
    'Late',
    'Đi trễ',
    'Đi trễ',
    Color(0xFFF5A623),
    Color(0xFFFFF1D9),
    Icons.access_time_filled,
  ),
  _StatusMeta(
    'Absent',
    'Không đi làm',
    'Không đi làm',
    Color(0xFFEF4444),
    Color(0xFFFFE6E6),
    Icons.cancel,
  ),
  _StatusMeta(
    'BusinessTrip',
    'Đi công tác',
    'Công tác',
    Color(0xFF3B82F6),
    Color(0xFFE2EEFF),
    Icons.flight,
  ),
  _StatusMeta(
    'Leave',
    'Nghỉ phép',
    'Nghỉ phép',
    Color(0xFF8B5CF6),
    Color(0xFFEFE8FF),
    Icons.beach_access,
  ),
  _StatusMeta(
    'Other',
    'Khác',
    'Khác',
    Color(0xFF8792A8),
    Color(0xFFE9EDF4),
    Icons.person,
  ),
];

_StatusMeta _metaOf(String key) {
  return _statusList.firstWhere(
    (m) => m.key.toLowerCase() == key.toLowerCase(),
    orElse: () => _statusList.last,
  );
}

// DATA MODELS

int _toInt(dynamic v) {
  if (v is num) return v.toInt();

  return int.tryParse('${v ?? ''}') ?? 0;
}

class _Counts {
  final int onTime;
  final int late;
  final int absent;
  final int businessTrip;
  final int leave;
  final int other;

  const _Counts({
    this.onTime = 0,
    this.late = 0,
    this.absent = 0,
    this.businessTrip = 0,
    this.leave = 0,
    this.other = 0,
  });

  factory _Counts.fromJson(dynamic j) {
    if (j is! Map) return const _Counts();

    return _Counts(
      onTime: _toInt(j['onTime']),
      late: _toInt(j['late']),
      absent: _toInt(j['absent']),
      businessTrip: _toInt(j['businessTrip']),
      leave: _toInt(j['leave']),
      other: _toInt(j['other']),
    );
  }

  List<int> get values => [onTime, late, absent, businessTrip, leave, other];

  int get total => values.fold(0, (a, b) => a + b);
}

class _ChartPoint {
  final String label;
  final _Counts counts;

  const _ChartPoint(this.label, this.counts);
}

class _DetailItem {
  final String date;
  final String employeeCode;
  final String fullName;
  final String status;
  final String? checkInTime;
  final String? checkOutTime;
  final String note;

  const _DetailItem({
    required this.date,
    required this.employeeCode,
    required this.fullName,
    required this.status,
    required this.checkInTime,
    required this.checkOutTime,
    required this.note,
  });

  factory _DetailItem.fromJson(Map j) {
    return _DetailItem(
      date: '${j['date'] ?? ''}',
      employeeCode: '${j['employeeCode'] ?? ''}',
      fullName: '${j['fullName'] ?? ''}',
      status: '${j['status'] ?? 'Other'}',
      checkInTime: j['checkInTime']?.toString(),
      checkOutTime: j['checkOutTime']?.toString(),
      note: '${j['note'] ?? ''}',
    );
  }
}

class _ReportData {
  final int totalEmployees;
  final _Counts summary;
  final _Counts previous;
  final List<_ChartPoint> daily;
  final List<_ChartPoint> monthly;
  final List<_DetailItem> items;
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;

  const _ReportData({
    required this.totalEmployees,
    required this.summary,
    required this.previous,
    required this.daily,
    required this.monthly,
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
  });

  factory _ReportData.fromJson(Map<String, dynamic> j) {
    // "2026-09-05" -> "05/09"
    String dayLabel(String s) {
      final parts = s.split('T').first.split('-');

      if (parts.length < 3) return s;

      return '${parts[2]}/${parts[1]}';
    }

    // "2026-09" -> "T9"
    String monthLabel(String s) {
      final parts = s.split('-');

      if (parts.length < 2) return s;

      return 'T${int.tryParse(parts[1]) ?? parts[1]}';
    }

    final dailyRaw = j['daily'];
    final monthlyRaw = j['monthly'];
    final itemsRaw = j['items'];

    return _ReportData(
      totalEmployees: _toInt(j['totalEmployees']),
      summary: _Counts.fromJson(j['summary']),
      previous: _Counts.fromJson(j['previousSummary']),

      daily: dailyRaw is List
          ? dailyRaw
                .whereType<Map>()
                .map(
                  (e) => _ChartPoint(
                    dayLabel('${e['date'] ?? ''}'),
                    _Counts.fromJson(e),
                  ),
                )
                .toList()
          : const [],

      monthly: monthlyRaw is List
          ? monthlyRaw
                .whereType<Map>()
                .map(
                  (e) => _ChartPoint(
                    monthLabel('${e['month'] ?? ''}'),
                    _Counts.fromJson(e),
                  ),
                )
                .toList()
          : const [],

      items: itemsRaw is List
          ? itemsRaw
                .whereType<Map>()
                .map((e) => _DetailItem.fromJson(e))
                .toList()
          : const [],

      page: _toInt(j['page']) == 0 ? 1 : _toInt(j['page']),
      pageSize: _toInt(j['pageSize']) == 0 ? 10 : _toInt(j['pageSize']),
      totalItems: _toInt(j['totalItems']),
      totalPages: _toInt(j['totalPages']) == 0 ? 1 : _toInt(j['totalPages']),
    );
  }
}

// SCREEN

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  static const int _pageSize = 10;

  late final List<DateTime> _monthOptions;

  late int _year;
  late int _month;

  // 'day' = xem 1 ngày | 'month' = xem cả tháng
  String _mode = 'day';

  late DateTime _selectedDate;

  // '' = tất cả trạng thái
  // hoặc: OnTime | Late | Absent | BusinessTrip | Leave | Other
  String _statusFilter = '';

  int _page = 1;

  String _search = '';

  // 'day' | 'month'
  String _chartMode = 'day';

  bool _isLoading = true;
  bool _isRefreshing = false;

  String? _error;

  _ReportData? _data;

  int _requestId = 0;

  Timer? _searchDebounce;

  final TextEditingController _searchController = TextEditingController();

  // INIT

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _monthOptions = List.generate(
      12,
      (i) => DateTime(now.year, now.month - i, 1),
    );

    _year = now.year;
    _month = now.month;

    _selectedDate = DateTime(now.year, now.month, now.day);

    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();

    super.dispose();
  }

  // LOAD

  Future<void> _load() async {
    final requestId = ++_requestId;

    setState(() {
      if (_data == null) {
        _isLoading = true;
      } else {
        _isRefreshing = true;
      }

      _error = null;
    });

    final scope = _mode == 'day'
        ? 'mode=day&date=${_selectedDate.year}-${_p2(_selectedDate.month)}-${_p2(_selectedDate.day)}'
        : 'mode=month&year=$_year&month=$_month';

    final query =
        '$scope&page=$_page&pageSize=$_pageSize'
        '&status=${Uri.encodeQueryComponent(_statusFilter)}'
        '&search=${Uri.encodeQueryComponent(_search.trim())}';

    try {
      final result = await ApiService.get(
        '/api/admin/reports/attendance?$query',
        bearerToken: AuthState.instance.token,
      );

      // Bỏ qua kết quả của request cũ.
      if (!mounted || requestId != _requestId) return;

      if (!result.success) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
          _error = result.errorMessage ?? 'Không thể tải báo cáo.';
        });

        return;
      }

      // dynamic để kiểm tra kiểu an toàn, kể cả khi data có kiểu Map<String, dynamic>?
      final dynamic raw = result.data;

      if (raw is! Map) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
          _error = 'Dữ liệu báo cáo không hợp lệ.';
        });

        return;
      }

      final parsed = _ReportData.fromJson(Map<String, dynamic>.from(raw));

      setState(() {
        _data = parsed;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      debugPrint('Load report error: $e');

      if (!mounted || requestId != _requestId) return;

      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _error = 'Không thể tải báo cáo. Vui lòng thử lại.';
      });
    }
  }

  void _changeMonth(DateTime value) {
    _year = value.year;
    _month = value.month;
    _page = 1;

    _load();
  }

  void _changeMode(String mode) {
    if (_mode == mode) return;

    _mode = mode;
    _page = 1;

    _load();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 2, 1, 1),
      lastDate: DateTime(now.year, now.month, now.day),
    );

    if (picked == null || !mounted) return;

    _selectedDate = DateTime(picked.year, picked.month, picked.day);
    _page = 1;

    _load();
  }

  void _changeStatus(String status) {
    if (_statusFilter == status) return;

    _statusFilter = status;
    _page = 1;

    _load();
  }

  void _goToPage(int page) {
    final data = _data;

    if (data == null) return;

    if (page < 1 || page > data.totalPages || page == _page) return;

    _page = page;

    _load();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;

      _search = value;
      _page = 1;

      _load();
    });
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

    AuthState.instance.clear();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // NAVIGATION

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
      (route) => false,
    );
  }

  void _push(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  // HELPERS

  String _p2(int v) => v.toString().padLeft(2, '0');

  String _fmtTime(String? iso) {
    if (iso == null || iso.isEmpty) return '-';

    final dt = DateTime.tryParse(iso);

    if (dt == null) return '-';

    final local = dt.toLocal();

    return '${_p2(local.hour)}:${_p2(local.minute)}';
  }

  String _fmtDate(String iso) {
    final parts = iso.split('T').first.split('-');

    if (parts.length < 3) return iso;

    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  String get _prevLabel =>
      _mode == 'day' ? 'so với hôm trước' : 'so với tháng trước';

  // BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;

            final content = _buildContent(wide);

            if (!wide) return content;

            return Row(
              children: [
                SizedBox(width: 260, child: _buildSidebar()),

                Expanded(child: content),
              ],
            );
          },
        ),
      ),
    );
  }

  // SIDEBAR

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
                  onTap: _goHome,
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
                      onTap: () {
                        // Giữ nguyên nếu AttendanceReportScreen
                        // chưa sử dụng FaceManagementScreen.
                        // Có thể thêm navigation sau nếu cần.
                      },
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
                  selected: true,
                  onTap: () {},
                ),

                const SizedBox(height: 8),

                _navSection(
                  icon: Icons.assignment_rounded,
                  title: 'Yêu cầu',
                  children: [
                    _navSubItem(
                      title: 'Đổi ca',
                      onTap: () {
                        // Navigation giữ nguyên cấu trúc sidebar.
                      },
                    ),

                    _navSubItem(
                      title: 'Nghỉ phép',
                      onTap: () => _push(const LeaveApprovalScreen()),
                    ),

                    _navSubItem(
                      title: 'Công tác',
                      onTap: () {
                        // Navigation có thể thêm BusinessTripApprovalScreen
                        // nếu cần import màn hình này.
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
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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

  // CONTENT

  Widget _buildContent(bool wide) {
    final padding = wide ? 24.0 : 16.0;

    return RefreshIndicator(
      color: _blue,

      onRefresh: _load,

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

                _buildFilterBar(contentWidth),

                const SizedBox(height: 16),

                ..._buildBody(contentWidth),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildBody(double contentWidth) {
    if (_isLoading) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: 80),

          child: Center(child: CircularProgressIndicator(color: _blue)),
        ),
      ];
    }

    final data = _data;

    if (data == null) {
      return [_buildErrorCard(_error ?? 'Không có dữ liệu.')];
    }

    final chartsSideBySide = contentWidth >= 820;

    return [
      if (_error != null) ...[
        _buildErrorCard(_error!, compact: true),

        const SizedBox(height: 16),
      ],

      _buildStatCards(data, contentWidth),

      const SizedBox(height: 16),

      if (chartsSideBySide)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Expanded(flex: 5, child: _buildDonutCard(data, compact: false)),

            const SizedBox(width: 16),

            Expanded(flex: 6, child: _buildBarCard(data, fixedHeight: true)),
          ],
        )
      else ...[
        _buildDonutCard(data, compact: true),

        const SizedBox(height: 16),

        _buildBarCard(data, fixedHeight: false),
      ],

      const SizedBox(height: 16),

      _buildDetailCard(data, contentWidth),
    ];
  }

  // HEADER

  Widget _buildHeader(bool wide) {
    final canPop = Navigator.of(context).canPop();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,

      children: [
        if (!wide && canPop) ...[
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),

            icon: const Icon(Icons.arrow_back_rounded, color: _navy),

            padding: EdgeInsets.zero,

            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),

          const SizedBox(width: 6),
        ],

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                'Báo cáo chấm công',

                maxLines: 1,

                overflow: TextOverflow.ellipsis,

                style: TextStyle(
                  color: _navy,
                  fontSize: wide ? 30 : 22,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                'Theo dõi tình hình đi làm của nhân viên trong công ty',

                maxLines: 2,

                overflow: TextOverflow.ellipsis,

                style: TextStyle(color: _textBlue, fontSize: wide ? 15 : 12.5),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        OutlinedButton.icon(
          onPressed: _confirmLogout,

          icon: const Icon(Icons.logout_rounded, size: 20),

          label: Text(wide ? 'Đăng xuất' : ''),

          style: OutlinedButton.styleFrom(
            foregroundColor: _navy,

            backgroundColor: Colors.white,

            side: const BorderSide(color: Color(0xFFCFDDF5)),

            padding: EdgeInsets.symmetric(
              horizontal: wide ? 20 : 12,
              vertical: 14,
            ),

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  // FILTER BAR
  //
  // [Ngày | Tháng] [📅 ngày / tháng] [Trạng thái ▼] [🔍 Nhân viên] [Xuất báo cáo]

  Widget _buildFilterBar(double contentWidth) {
    final inline = contentWidth >= 1000;

    final exportButton = ElevatedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Chức năng xuất báo cáo sẽ được bổ sung sau.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
      },

      icon: const Icon(Icons.download_rounded, size: 20),

      label: const Text(
        'Xuất báo cáo',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),

      style: ElevatedButton.styleFrom(
        backgroundColor: _blue,

        foregroundColor: Colors.white,

        elevation: 0,

        minimumSize: const Size(0, 46),

        padding: const EdgeInsets.symmetric(horizontal: 20),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    final searchBox = SizedBox(
      height: 46,

      child: TextField(
        controller: _searchController,

        onChanged: _onSearchChanged,

        style: const TextStyle(color: _textBlue, fontSize: 13.5),

        decoration: InputDecoration(
          hintText: 'Tìm nhân viên (tên hoặc mã NV)...',

          hintStyle: const TextStyle(color: _textGrey, fontSize: 13),

          prefixIcon: const Icon(Icons.search, color: _textGrey, size: 20),

          filled: true,

          fillColor: const Color(0xFFF8FAFF),

          contentPadding: EdgeInsets.zero,

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD3DEFA)),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD3DEFA)),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _blue, width: 1.4),
          ),
        ),
      ),
    );

    final modeToggle = _buildModeToggle();

    final dateField = _mode == 'day' ? _buildDateField() : _buildMonthField();

    final statusDropdown = _buildStatusDropdown();

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(14),

      decoration: _cardDecoration(),

      child: inline
          ? Row(
              children: [
                modeToggle,

                const SizedBox(width: 12),

                dateField,

                const SizedBox(width: 12),

                statusDropdown,

                const SizedBox(width: 12),

                Expanded(child: searchBox),

                const SizedBox(width: 12),

                exportButton,
              ],
            )
          : Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,

              children: [
                modeToggle,

                dateField,

                statusDropdown,

                SizedBox(
                  width: math.max(0, contentWidth - 28),
                  child: searchBox,
                ),

                exportButton,
              ],
            ),
    );
  }

  // NGÀY | THÁNG

  Widget _buildModeToggle() {
    Widget option(String mode, String label, IconData icon) {
      final selected = _mode == mode;

      return GestureDetector(
        onTap: () => _changeMode(mode),

        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),

          alignment: Alignment.center,

          decoration: BoxDecoration(
            color: selected ? _blue : Colors.transparent,

            borderRadius: BorderRadius.circular(9),
          ),

          child: Row(
            mainAxisSize: MainAxisSize.min,

            children: [
              Icon(icon, size: 17, color: selected ? Colors.white : _textBlue),

              const SizedBox(width: 7),

              Text(
                label,

                style: TextStyle(
                  color: selected ? Colors.white : _textBlue,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 46,

      padding: const EdgeInsets.all(3),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: const Color(0xFFCFDDF5)),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          option('day', 'Ngày', Icons.calendar_today_rounded),

          option('month', 'Tháng', Icons.calendar_month_rounded),
        ],
      ),
    );
  }

  // Ô CHỌN NGÀY (chế độ Ngày)

  Widget _buildDateField() {
    final label =
        '${_p2(_selectedDate.day)}/${_p2(_selectedDate.month)}/${_selectedDate.year}';

    return InkWell(
      borderRadius: BorderRadius.circular(12),

      onTap: _pickDate,

      child: Container(
        height: 46,

        padding: const EdgeInsets.symmetric(horizontal: 14),

        decoration: BoxDecoration(
          color: const Color(0xFFEAF3FF),

          borderRadius: BorderRadius.circular(12),

          border: Border.all(color: const Color(0xFFCFDDF5)),
        ),

        child: Row(
          mainAxisSize: MainAxisSize.min,

          children: [
            const Icon(Icons.calendar_month_rounded, size: 20, color: _blue),

            const SizedBox(width: 10),

            Text(
              label,

              style: const TextStyle(
                color: _navy,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(width: 8),

            const Icon(Icons.keyboard_arrow_down, color: _navy),
          ],
        ),
      ),
    );
  }

  // Ô CHỌN THÁNG (chế độ Tháng)

  Widget _buildMonthField() {
    final selected = _monthOptions.firstWhere(
      (d) => d.year == _year && d.month == _month,
      orElse: () => _monthOptions.first,
    );

    return Container(
      height: 46,

      padding: const EdgeInsets.symmetric(horizontal: 14),

      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: const Color(0xFFCFDDF5)),
      ),

      child: DropdownButtonHideUnderline(
        child: DropdownButton<DateTime>(
          value: selected,

          icon: const Icon(Icons.keyboard_arrow_down, color: _navy),

          borderRadius: BorderRadius.circular(12),

          items: _monthOptions.map((d) {
            return DropdownMenuItem<DateTime>(
              value: d,

              child: Row(
                mainAxisSize: MainAxisSize.min,

                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    size: 20,
                    color: _blue,
                  ),

                  const SizedBox(width: 10),

                  Text(
                    'Tháng ${d.month}/${d.year}',

                    style: const TextStyle(
                      color: _navy,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),

          onChanged: (value) {
            if (value == null) return;

            _changeMonth(value);
          },
        ),
      ),
    );
  }

  // Ô LỌC TRẠNG THÁI

  Widget _buildStatusDropdown() {
    const itemStyle = TextStyle(
      color: _navy,
      fontSize: 13.5,
      fontWeight: FontWeight.w600,
    );

    return Container(
      height: 46,

      padding: const EdgeInsets.symmetric(horizontal: 14),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: const Color(0xFFCFDDF5)),
      ),

      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _statusFilter,

          icon: const Icon(Icons.keyboard_arrow_down, color: _navy),

          borderRadius: BorderRadius.circular(12),

          items: [
            const DropdownMenuItem<String>(
              value: '',
              child: Text('Tất cả trạng thái', style: itemStyle),
            ),

            ..._statusList.map((m) {
              return DropdownMenuItem<String>(
                value: m.key,
                child: Text(m.label, style: itemStyle),
              );
            }),
          ],

          onChanged: (value) {
            if (value == null) return;

            _changeStatus(value);
          },
        ),
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

  // STAT CARDS

  Widget _buildStatCards(_ReportData data, double width) {
    final cols = width >= 880 ? 6 : (width >= 560 ? 3 : 2);

    const spacing = 12.0;

    final itemWidth = (width - spacing * (cols - 1)) / cols;

    final current = data.summary.values;

    final previous = data.previous.values;

    // true  = tăng là tốt
    // false = tăng là xấu
    // null  = trung tính
    const positiveIsGood = <bool?>[true, false, false, null, null, null];

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,

      children: List.generate(_statusList.length, (i) {
        return SizedBox(
          width: itemWidth,

          child: _buildStatCard(
            meta: _statusList[i],
            value: current[i],
            previous: previous[i],
            positiveIsGood: positiveIsGood[i],
          ),
        );
      }),
    );
  }

  Widget _buildStatCard({
    required _StatusMeta meta,
    required int value,
    required int previous,
    required bool? positiveIsGood,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: meta.background.withValues(alpha: 0.6),

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: meta.color.withValues(alpha: 0.14)),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Container(
            width: 38,
            height: 38,

            decoration: BoxDecoration(
              color: meta.color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),

            child: Icon(meta.icon, color: meta.color, size: 21),
          ),

          const SizedBox(height: 10),

          Text(
            '$value',

            style: const TextStyle(
              color: _navy,
              fontSize: 27,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            meta.label,

            maxLines: 1,

            overflow: TextOverflow.ellipsis,

            style: const TextStyle(
              color: _navy,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          _buildDelta(value, previous, positiveIsGood),
        ],
      ),
    );
  }

  Widget _buildDelta(int current, int previous, bool? positiveIsGood) {
    IconData? icon;

    Color color = _textGrey;

    String text;

    if (previous == 0) {
      if (current == 0) {
        text = '= 0% $_prevLabel';
      } else {
        text = 'Mới $_prevLabel';

        icon = Icons.arrow_upward_rounded;
      }
    } else {
      final pct = ((current - previous) / previous * 100).round();

      if (pct == 0) {
        text = '= 0% $_prevLabel';
      } else {
        final up = pct > 0;

        icon = up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

        text = '${pct.abs()}% $_prevLabel';

        if (positiveIsGood != null) {
          color = (up == positiveIsGood) ? _green : _red;
        }
      }
    }

    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: color),

          const SizedBox(width: 2),
        ],

        Expanded(
          child: Text(
            text,

            maxLines: 1,

            overflow: TextOverflow.ellipsis,

            style: TextStyle(color: color, fontSize: 10.5),
          ),
        ),
      ],
    );
  }

  // DONUT CARD

  Widget _buildDonutCard(_ReportData data, {required bool compact}) {
    final counts = data.summary;

    final total = counts.total;

    final donut = SizedBox(
      width: 190,
      height: 190,

      child: CustomPaint(
        painter: _DonutPainter(
          values: counts.values.map((v) => v.toDouble()).toList(),
          colors: _statusList.map((m) => m.color).toList(),
          total: total,
          centerLabel: _mode == 'day' ? 'Tổng nhân viên' : 'Tổng lượt',
        ),
      ),
    );

    final legend = Column(
      mainAxisSize: MainAxisSize.min,

      children: List.generate(_statusList.length, (i) {
        final meta = _statusList[i];

        final value = counts.values[i];

        final pct = total == 0 ? 0.0 : value * 100 / total;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),

          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,

                decoration: BoxDecoration(
                  color: meta.color,
                  shape: BoxShape.circle,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  meta.label,

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(color: _textBlue, fontSize: 12.5),
                ),
              ),

              const SizedBox(width: 8),

              Text(
                '$value (${pct.toStringAsFixed(1)}%)',

                style: const TextStyle(
                  color: _navy,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }),
    );

    final card = Container(
      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: _cardDecoration(),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            'Tổng quan tình hình chấm công',

            style: TextStyle(
              color: _navy,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 14),

          if (compact) ...[
            Center(child: donut),

            const SizedBox(height: 14),

            legend,
          ] else
            Expanded(
              child: Row(
                children: [
                  donut,

                  const SizedBox(width: 20),

                  Expanded(child: Center(child: legend)),
                ],
              ),
            ),
        ],
      ),
    );

    // Chế độ 2 cột: cố định chiều cao để 2 thẻ biểu đồ bằng nhau.
    if (!compact) {
      return SizedBox(height: 360, child: card);
    }

    return card;
  }

  // BAR CARD

  Widget _buildBarCard(_ReportData data, {required bool fixedHeight}) {
    final points = _chartMode == 'day' ? data.daily : data.monthly;

    final chart = SizedBox(
      height: 220,

      child: points.isEmpty
          ? const Center(
              child: Text(
                'Chưa có dữ liệu biểu đồ.',
                style: TextStyle(color: _textGrey, fontSize: 13),
              ),
            )
          : CustomPaint(
              size: Size.infinite,

              painter: _StackedBarPainter(
                points: points,
                colors: _statusList.map((m) => m.color).toList(),
              ),
            ),
    );

    final legend = Wrap(
      spacing: 14,
      runSpacing: 6,

      children: _statusList.map((m) {
        return Row(
          mainAxisSize: MainAxisSize.min,

          children: [
            Container(
              width: 10,
              height: 10,

              decoration: BoxDecoration(color: m.color, shape: BoxShape.circle),
            ),

            const SizedBox(width: 5),

            Text(
              m.shortLabel,
              style: const TextStyle(color: _textBlue, fontSize: 11.5),
            ),
          ],
        );
      }).toList(),
    );

    final card = Container(
      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: _cardDecoration(),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _chartMode == 'day'
                      ? 'Biểu đồ theo ngày'
                      : 'Biểu đồ theo tháng',

                  style: const TextStyle(
                    color: _navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              _buildChartToggle(),
            ],
          ),

          const SizedBox(height: 14),

          chart,

          const SizedBox(height: 12),

          legend,
        ],
      ),
    );

    if (fixedHeight) {
      return SizedBox(height: 360, child: card);
    }

    return card;
  }

  Widget _buildChartToggle() {
    Widget option(String mode, String label) {
      final selected = _chartMode == mode;

      return GestureDetector(
        onTap: () {
          setState(() {
            _chartMode = mode;
          });
        },

        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),

          decoration: BoxDecoration(
            color: selected ? _blue : Colors.transparent,

            borderRadius: BorderRadius.circular(18),
          ),

          child: Text(
            label,

            style: TextStyle(
              color: selected ? Colors.white : _textBlue,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(21),

        border: Border.all(color: const Color(0xFFCFDDF5)),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [option('day', 'Ngày'), option('month', 'Tháng')],
      ),
    );
  }

  // DETAIL CARD
  //
  // Chi tiết danh sách chấm công:
  // [Tất cả (n)] [Đúng giờ (n)] [Đi trễ (n)] ... + bảng chi tiết.

  Widget _buildDetailCard(_ReportData data, double contentWidth) {
    final wideTable = contentWidth >= 760;

    final summary = data.summary;

    final chips = Wrap(
      spacing: 8,
      runSpacing: 8,

      children: [
        _buildFilterChip('', 'Tất cả (${summary.total})'),

        ...List.generate(_statusList.length, (i) {
          return _buildFilterChip(
            _statusList[i].key,
            '${_statusList[i].shortLabel} (${summary.values[i]})',
          );
        }),
      ],
    );

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: _cardDecoration(),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            'Chi tiết danh sách chấm công',

            style: TextStyle(
              color: _navy,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 14),

          chips,

          const SizedBox(height: 14),

          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),

              child: LinearProgressIndicator(minHeight: 2, color: _blue),
            ),

          if (data.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),

              child: Center(
                child: Text(
                  'Không có dữ liệu chấm công phù hợp.',
                  style: TextStyle(color: _textGrey, fontSize: 13),
                ),
              ),
            )
          else if (wideTable)
            _buildTable(data)
          else
            _buildCardList(data),

          const SizedBox(height: 14),

          _buildPagination(data, wideTable),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final selected = _statusFilter == key;

    return GestureDetector(
      onTap: () => _changeStatus(key),

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),

        decoration: BoxDecoration(
          color: selected ? _blue : Colors.white,

          borderRadius: BorderRadius.circular(18),

          border: Border.all(color: selected ? _blue : const Color(0xFFCFDDF5)),
        ),

        child: Text(
          label,

          style: TextStyle(
            color: selected ? Colors.white : _textBlue,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // TABLE (màn hình rộng)
  //
  // STT | Mã NV | Họ và tên | Ngày | Giờ vào | Giờ ra | Trạng thái | Ghi chú

  static const List<int> _flex = [1, 2, 4, 2, 2, 2, 3, 4];

  Widget _buildTable(_ReportData data) {
    const headers = [
      'STT',
      'Mã NV',
      'Họ và tên',
      'Ngày',
      'Giờ vào',
      'Giờ ra',
      'Trạng thái',
      'Ghi chú',
    ];

    Widget cell(int i, Widget child) {
      return Expanded(flex: _flex[i], child: child);
    }

    Widget text(String value, {bool bold = false}) {
      return Text(
        value,

        maxLines: 1,

        overflow: TextOverflow.ellipsis,

        style: TextStyle(
          color: _navy,
          fontSize: 13,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),

          decoration: BoxDecoration(
            color: const Color(0xFFF1F6FF),

            borderRadius: BorderRadius.circular(10),
          ),

          child: Row(
            children: List.generate(headers.length, (i) {
              return cell(
                i,
                Text(
                  headers[i],

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: _textBlue,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }),
          ),
        ),

        ...List.generate(data.items.length, (index) {
          final item = data.items[index];

          final stt = (data.page - 1) * data.pageSize + index + 1;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),

            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEDF2FA))),
            ),

            child: Row(
              children: [
                cell(0, text('$stt')),

                cell(1, text(item.employeeCode)),

                cell(2, text(item.fullName, bold: true)),

                cell(3, text(_fmtDate(item.date))),

                cell(4, text(_fmtTime(item.checkInTime))),

                cell(5, text(_fmtTime(item.checkOutTime))),

                cell(
                  6,
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildStatusChip(item.status),
                  ),
                ),

                cell(7, text(item.note.isEmpty ? '-' : item.note)),
              ],
            ),
          );
        }),
      ],
    );
  }

  // CARD LIST (màn hình hẹp / điện thoại)

  Widget _buildCardList(_ReportData data) {
    return Column(
      children: List.generate(data.items.length, (index) {
        final item = data.items[index];

        final stt = (data.page - 1) * data.pageSize + index + 1;

        return Container(
          width: double.infinity,

          margin: const EdgeInsets.only(bottom: 10),

          padding: const EdgeInsets.all(14),

          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFF),

            borderRadius: BorderRadius.circular(14),

            border: Border.all(color: const Color(0xFFE4EBF6)),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$stt. ${item.fullName}',

                      maxLines: 1,

                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        color: _navy,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  _buildStatusChip(item.status),
                ],
              ),

              const SizedBox(height: 4),

              Text(
                '${item.employeeCode}  •  ${_fmtDate(item.date)}',

                style: const TextStyle(color: _textGrey, fontSize: 12),
              ),

              const SizedBox(height: 8),

              Text(
                'Vào ${_fmtTime(item.checkInTime)}   •   '
                'Ra ${_fmtTime(item.checkOutTime)}',

                style: const TextStyle(color: _textBlue, fontSize: 12.5),
              ),

              if (item.note.isNotEmpty) ...[
                const SizedBox(height: 4),

                Text(
                  item.note,
                  style: const TextStyle(color: _textGrey, fontSize: 12),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatusChip(String status) {
    final meta = _metaOf(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),

      decoration: BoxDecoration(
        color: meta.background,

        borderRadius: BorderRadius.circular(16),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          Icon(meta.icon, size: 14, color: meta.color),

          const SizedBox(width: 5),

          Text(
            meta.shortLabel,

            style: TextStyle(
              color: meta.color,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // PAGINATION

  Widget _buildPagination(_ReportData data, bool wide) {
    final info = Text(
      'Hiển thị ${data.items.length} trong tổng số ${data.totalItems} ${_mode == 'day' ? 'nhân viên' : 'bản ghi'}',

      style: const TextStyle(color: _textGrey, fontSize: 12.5),
    );

    final pager = _buildPager(data);

    if (wide) {
      return Row(
        children: [
          Expanded(child: info),
          pager,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [info, const SizedBox(height: 10), pager],
    );
  }

  Widget _buildPager(_ReportData data) {
    final current = data.page;

    final last = data.totalPages;

    // 1, trang trước, trang hiện tại, trang sau, trang cuối
    final pages = <int>{
      1,
      current - 1,
      current,
      current + 1,
      last,
    }.where((p) => p >= 1 && p <= last).toList()..sort();

    final children = <Widget>[
      _pagerButton(
        child: const Icon(Icons.chevron_left, size: 20, color: _navy),
        onTap: current > 1 ? () => _goToPage(current - 1) : null,
      ),
    ];

    for (var i = 0; i < pages.length; i++) {
      if (i > 0 && pages[i] - pages[i - 1] > 1) {
        children.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),

            child: Text('...', style: TextStyle(color: _textGrey)),
          ),
        );
      }

      final page = pages[i];

      final selected = page == current;

      children.add(
        _pagerButton(
          selected: selected,

          child: Text(
            '$page',

            style: TextStyle(
              color: selected ? Colors.white : _navy,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),

          onTap: () => _goToPage(page),
        ),
      );
    }

    children.add(
      _pagerButton(
        child: const Icon(Icons.chevron_right, size: 20, color: _navy),
        onTap: current < last ? () => _goToPage(current + 1) : null,
      ),
    );

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,

      children: children,
    );
  }

  Widget _pagerButton({
    required Widget child,
    required VoidCallback? onTap,
    bool selected = false,
  }) {
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,

      child: Material(
        color: selected ? _blue : Colors.white,

        borderRadius: BorderRadius.circular(9),

        child: InkWell(
          borderRadius: BorderRadius.circular(9),

          onTap: onTap,

          child: Container(
            width: 36,
            height: 36,

            alignment: Alignment.center,

            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),

              border: Border.all(
                color: selected ? _blue : const Color(0xFFCFDDF5),
              ),
            ),

            child: child,
          ),
        ),
      ),
    );
  }

  // ERROR

  Widget _buildErrorCard(String message, {bool compact = false}) {
    return Container(
      width: double.infinity,

      padding: EdgeInsets.all(compact ? 14 : 24),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: const Color(0xFFFFD6D6)),
      ),

      child: Row(
        children: [
          const Icon(Icons.error_outline, color: _red, size: 26),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: _navy, fontSize: 13.5),
            ),
          ),

          const SizedBox(width: 8),

          TextButton.icon(
            onPressed: _load,

            icon: const Icon(Icons.refresh, size: 18),

            label: const Text('Thử lại'),
          ),
        ],
      ),
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

// DONUT PAINTER

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final int total;
  final String centerLabel;

  _DonutPainter({
    required this.values,
    required this.colors,
    required this.total,
    required this.centerLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);

    final center = Offset(size.width / 2, size.height / 2);

    final radius = side / 2;

    final stroke = radius * 0.42;

    final ringRadius = radius - stroke / 2;

    final rect = Rect.fromCircle(center: center, radius: ringRadius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..isAntiAlias = true;

    if (total <= 0) {
      paint.color = const Color(0xFFE4EBF6);

      canvas.drawCircle(center, ringRadius, paint);
    } else {
      var start = -math.pi / 2;

      for (var i = 0; i < values.length; i++) {
        final v = values[i];

        if (v <= 0) continue;

        final sweep = v / total * 2 * math.pi;

        paint.color = colors[i];

        canvas.drawArc(rect, start, sweep, false, paint);

        // Nhãn % trong cung đủ lớn.
        final pct = v * 100 / total;

        if (pct >= 7) {
          final mid = start + sweep / 2;

          final pos = Offset(
            center.dx + math.cos(mid) * ringRadius,
            center.dy + math.sin(mid) * ringRadius,
          );

          _drawText(
            canvas,
            '${pct.toStringAsFixed(1)}%',
            const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
            pos,
          );
        }

        start += sweep;
      }
    }

    // Chữ ở giữa.
    _drawText(
      canvas,
      centerLabel,
      const TextStyle(color: _textGrey, fontSize: 12),
      Offset(center.dx, center.dy - 12),
    );

    _drawText(
      canvas,
      '$total',
      const TextStyle(color: _navy, fontSize: 22, fontWeight: FontWeight.w800),
      Offset(center.dx, center.dy + 10),
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}

// STACKED BAR PAINTER
//
// Mỗi ngày (hoặc tháng) là 1 cột, các trạng thái xếp chồng lên nhau
// để vẫn dễ đọc khi tháng có 20+ ngày làm việc.

class _StackedBarPainter extends CustomPainter {
  final List<_ChartPoint> points;
  final List<Color> colors;

  _StackedBarPainter({required this.points, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    const left = 34.0;
    const bottom = 24.0;
    const top = 8.0;

    final chartW = size.width - left;
    final chartH = size.height - bottom - top;

    if (chartW <= 0 || chartH <= 0 || points.isEmpty) return;

    var maxTotal = 0;

    for (final p in points) {
      maxTotal = math.max(maxTotal, p.counts.total);
    }

    final step = _niceStep(maxTotal <= 0 ? 1 : maxTotal / 4);

    final maxY = step * 4;

    // GRID + NHÃN TRỤC Y

    final gridPaint = Paint()
      ..color = const Color(0xFFE4EBF6)
      ..strokeWidth = 1;

    for (var i = 0; i <= 4; i++) {
      final y = top + chartH - chartH * i / 4;

      canvas.drawLine(Offset(left, y), Offset(size.width, y), gridPaint);

      _drawText(
        canvas,
        '${(step * i).round()}',
        const TextStyle(color: _textGrey, fontSize: 10.5),
        Offset(left - 6, y),
        anchorX: 1,
      );
    }

    // CỘT

    final groupW = chartW / points.length;

    final barW = math.min(groupW * 0.62, 26.0);

    final labelEvery = math.max(
      1,
      (points.length / math.max(1, (chartW / 44).floor())).ceil(),
    );

    for (var idx = 0; idx < points.length; idx++) {
      final point = points[idx];

      final cx = left + groupW * idx + groupW / 2;

      var yBottom = top + chartH;

      final values = point.counts.values;

      for (var j = 0; j < values.length; j++) {
        final v = values[j];

        if (v <= 0) continue;

        final h = chartH * v / maxY;

        canvas.drawRect(
          Rect.fromLTWH(cx - barW / 2, yBottom - h, barW, h),
          Paint()..color = colors[j],
        );

        yBottom -= h;
      }

      if (idx % labelEvery == 0) {
        _drawText(
          canvas,
          point.label,
          const TextStyle(color: _textGrey, fontSize: 10.5),
          Offset(cx, top + chartH + 6),
          anchorY: 0,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StackedBarPainter oldDelegate) => true;
}
