import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/auth_state.dart';

import 'admin_home_screen.dart';
import 'employee_list_screen.dart';
import 'ip_config_screen.dart';
import 'business_trip_approval_screen.dart';
import 'shift_change_approval_screen.dart';
import 'face_management_screen.dart';
import 'change_password_screen.dart';
import 'login_screen.dart';
import 'attendance_report_screen.dart';

const Color _navy = Color(0xFF0D2858);
const Color _blue = Color(0xFF246BDE);
const Color _bg = Color(0xFFF3F8FF);
const Color _border = Color(0xFFE2EAF7);
const Color _text = Color(0xFF183153);
const Color _muted = Color(0xFF71819A);
const Color _brightBlue = Color(0xFF2864E8);
const Color _red = Color(0xFFD94343);
const Color _textBlue = Color(0xFF31589D);
const Color _green = Color(0xFF1FA971);
const Color _orange = Color(0xFFF59E0B);

class LeaveApprovalScreen extends StatefulWidget {
  const LeaveApprovalScreen({super.key});

  @override
  State<LeaveApprovalScreen> createState() => _LeaveApprovalScreenState();
}

class _LeaveApprovalScreenState extends State<LeaveApprovalScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _pendingRequests = [];
  final Set<String> _processingIds = {};
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  Future<void> _loadPending() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService.getList(
      '/api/leave-requests/pending',
      bearerToken: AuthState.instance.token,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;

      if (result.success) {
        _pendingRequests = result.data!;
      } else {
        _errorMessage = result.errorMessage;
      }
    });
  }

  Future<void> _handleDecision(String id, bool approve) async {
    setState(() => _processingIds.add(id));

    final result = await ApiService.put(
      '/api/leave-requests/$id/${approve ? 'approve' : 'reject'}',
      {},
      bearerToken: AuthState.instance.token,
    );

    if (!mounted) return;

    setState(() => _processingIds.remove(id));

    if (result.success) {
      setState(() {
        _pendingRequests.removeWhere((r) => r['id'] == id);
      });

      final isPaid = result.data?['isPaid'] == true;
      final message = approve
          ? (isPaid
                ? 'Đã duyệt đơn - Nghỉ phép có lương'
                : 'Đã duyệt đơn - Nhân viên này đã hết phép năm')
          : 'Đã từ chối đơn.';
      final backgroundColor = approve ? (isPaid ? _green : _orange) : _red;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: backgroundColor),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'Thao tác thất bại.')),
      );
    }
  }

  String _formatDateRange(Map<String, dynamic> r) {
    final start = DateTime.parse(r['startDate'] as String);

    final end = DateTime.parse(r['endDate'] as String);

    String fmt(DateTime d) {
      return '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/'
          '${d.year}';
    }

    if (start.day == end.day &&
        start.month == end.month &&
        start.year == end.year) {
      return fmt(start);
    }

    return '${fmt(start)} - ${fmt(end)}';
  }

  void _push(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Đăng xuất'),
          content: const Text(
            'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản này không?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _red,
                foregroundColor: _bg,
              ),
              child: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

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
                      title: 'Cấu hình WiFi & GPS',
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

  // AIN CONTENT
  Widget _buildMainContent(bool isDesktop) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth >= 1200 ? 44.0 : 28.0;

        return RefreshIndicator(
          onRefresh: _loadPending,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              30,
              horizontalPadding,
              40,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 650),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPageHeader(isDesktop),
                  const SizedBox(height: 24),
                  _buildRequestSection(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPageHeader(bool isDesktop) {
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
            Icons.event_note_rounded,
            color: AppColors.primaryBlue,
            size: 30,
          ),
        ),

        const SizedBox(width: 16),

        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Duyệt đơn nghỉ phép',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Xem và xử lý các đơn xin nghỉ phép đang chờ phê duyệt.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13.5,
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

  Widget _buildRequestSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSectionHeader(),

          if (_isLoading)
            _buildLoadingState()
          else if (_errorMessage != null)
            _buildErrorState()
          else if (_pendingRequests.isEmpty)
            _buildEmptyState()
          else
            _buildRequestList(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.fact_check_outlined,
              color: AppColors.primaryBlue,
              size: 20,
            ),
          ),

          const SizedBox(width: 11),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Đơn đang chờ duyệt',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${_pendingRequests.length} đơn',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const Spacer(),

          OutlinedButton.icon(
            onPressed: _loadPending,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text(
              'Làm mới',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryBlue,
              side: const BorderSide(color: AppColors.borderColor),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const SizedBox(
      height: 360,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState() {
    return SizedBox(
      height: 360,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: _red, size: 44),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _red, fontSize: 13),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loadPending,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 390,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fact_check_outlined,
                color: AppColors.textSecondary,
                size: 36,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Không có đơn nào đang chờ duyệt',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 7),

            const Text(
              'Hiện tại không có đơn xin nghỉ phép nào cần xử lý.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestList() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.75),
            border: Border(
              top: BorderSide(color: AppColors.borderColor),
              bottom: BorderSide(color: AppColors.borderColor),
            ),
          ),
          child: const Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  'NHÂN VIÊN',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'THỜI GIAN',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'LOẠI NGHỈ',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  'LÝ DO',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(
                width: 210,
                child: Text(
                  'THAO TÁC',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),

        ..._pendingRequests.asMap().entries.map((entry) {
          final index = entry.key;
          final request = entry.value as Map<String, dynamic>;

          return _buildRequestRow(request, index);
        }),
      ],
    );
  }

  Widget _buildRequestRow(Map<String, dynamic> r, int index) {
    final id = r['id'] as String;
    final isProcessing = _processingIds.contains(id);

    final employeeName = r['employeeName'] ?? 'Không rõ';

    final employeeCode = r['employeeCode'] ?? '';

    final type = r['type'] ?? '';

    final reason = r['reason'] ?? '';

    final isLast = index == _pendingRequests.length - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: isLast ? _bg : AppColors.borderColor),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // EMPLOYEE
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.infoBoxBackground,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Center(
                    child: Text(
                      employeeName.toString().isNotEmpty
                          ? employeeName.toString()[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: _blue,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employeeName.toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _text,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        employeeCode.toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _muted, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // DATE
          Expanded(
            flex: 3,
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: _muted,
                  size: 17,
                ),
                const SizedBox(width: 9),
                Flexible(
                  child: Text(
                    _formatDateRange(r),
                    style: const TextStyle(
                      color: _text,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // TYPE
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildLeaveTypeBadge(type.toString()),
            ),
          ),

          // REASON
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.only(right: 18),
              child: Text(
                reason.toString().isEmpty
                    ? 'Không có lý do'
                    : reason.toString(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: reason.toString().isEmpty ? _muted : _text,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ),
          ),

          // ACTIONS
          SizedBox(
            width: 210,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isProcessing
                        ? null
                        : () => _handleDecision(id, false),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text(
                      'Từ chối',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _red,
                      side: const BorderSide(color: _red),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isProcessing
                        ? null
                        : () => _handleDecision(id, true),
                    icon: isProcessing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _bg,
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 16),
                    label: const Text(
                      'Duyệt',
                      style: TextStyle(
                        color: _bg,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: _bg,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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

  Widget _buildLeaveTypeBadge(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: _border,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type.isEmpty ? 'Nghỉ phép' : type,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _blue,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
