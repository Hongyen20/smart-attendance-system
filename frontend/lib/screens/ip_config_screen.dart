import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/auth_state.dart';

import 'admin_home_screen.dart';
import 'employee_list_screen.dart';
import 'ip_config_form_screen.dart';
import 'leave_approval_screen.dart';
import 'business_trip_approval_screen.dart';
import 'shift_change_approval_screen.dart';
import 'face_management_screen.dart';
import 'change_password_screen.dart';
import 'login_screen.dart';
import 'attendance_report_screen.dart';

class IpConfigScreen extends StatefulWidget {
  const IpConfigScreen({super.key});

  @override
  State<IpConfigScreen> createState() => _IpConfigScreenState();
}

const Color _navy = Color(0xFF0D2858);
const Color _bg = Color(0xFFF3F8FF);
const Color _brightBlue = Color(0xFF2864E8);
const Color _textBlue = Color(0xFF31589D);

class _IpConfigScreenState extends State<IpConfigScreen> {
  bool _isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String? _errorMessage;
  List<dynamic> _configs = [];

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService.getList(
      '/api/ip-configs',
      bearerToken: AuthState.instance.token,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;

      if (result.success) {
        _configs = result.data!;
      } else {
        _errorMessage = result.errorMessage;
      }
    });
  }

  Future<void> _handleDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa cấu hình của WiFi này?'),
        content: const Text(
          'Nhân viên sẽ không thể check-in bằng WiFi này nữa sau khi xóa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Xóa',
              style: TextStyle(color: AppColors.dangerRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await ApiService.delete(
      '/api/ip-configs/$id',
      bearerToken: AuthState.instance.token,
    );

    if (result.success) {
      _loadConfigs();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'Xóa thất bại.')),
      );
    }
  }

  Future<void> _addIp() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const IpConfigFormScreen()),
    );

    if (created == true) {
      _loadConfigs();
    }
  }

  Future<void> _editIp(Map<String, dynamic> config) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => IpConfigFormScreen(existingConfig: config),
      ),
    );

    if (updated == true) {
      _loadConfigs();
    }
  }

  void _push(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản này không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
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
                      onRefresh: _loadConfigs,
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
                  onTap: () => _push(const AdminHomeScreen()),
                ),

                const SizedBox(height: 8),

                // NHÂN VIÊN
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

                // CHẤM CÔNG
                _navSection(
                  icon: Icons.access_time_rounded,
                  title: 'Chấm công',
                  children: [
                    _navSubItem(
                      title: 'Cấu hình WiFi & GPS',
                      selected: true,
                      onTap: () {
                        // Đang ở màn này.
                        if (MediaQuery.sizeOf(context).width < 1000) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                ),

                // BÁO CÁO
                _navItem(
                  icon: Icons.bar_chart_rounded,
                  title: 'Báo cáo',
                  onTap: () => _push(const AttendanceReportScreen()),
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

          // ACCOUNT
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

  //MAIN CONTENT

  Widget _buildMainContent(bool isDesktop) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth >= 1200 ? 44.0 : 28.0;

        return RefreshIndicator(
          onRefresh: _loadConfigs,
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
                  _buildContentCard(),
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
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.location_on_outlined,
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
                'Cấu hình WiFi & GPS',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Danh sách các địa điểm được phép chấm công theo Wifi và bán kính.',
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

  Widget _buildContentCard() {
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
          _buildCardHeader(),
          if (_isLoading)
            _buildLoadingState()
          else if (_errorMessage != null)
            _buildErrorState()
          else if (_configs.isEmpty)
            _buildEmptyState()
          else
            _buildConfigTable(),
        ],
      ),
    );
  }

  Widget _buildCardHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 18, 18),
      child: Row(
        children: [
          const Icon(
            Icons.location_on_outlined,
            color: AppColors.primaryBlue,
            size: 21,
          ),
          const SizedBox(width: 10),
          Text(
            '${_configs.length} địa điểm',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _addIp,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text(
              'Thêm WiFi',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
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
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.dangerRed,
                size: 44,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.dangerRed,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loadConfigs,
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
      height: 330,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  color: AppColors.textSecondary,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Chưa có cấu hình WiFi',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Nhân viên sẽ không thể check-in cho tới khi\nthêm ít nhất một cấu hình WiFi.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _addIp,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Thêm WiFi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CONFIG TABLE
  // ============================================================

  Widget _buildConfigTable() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
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
                  'Địa chỉ IP',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Bán kính',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Trạng thái',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(
                width: 70,
                child: Text(
                  'Thao tác',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),

        ..._configs.asMap().entries.map((entry) {
          final index = entry.key;
          final config = entry.value as Map<String, dynamic>;

          return _buildTableRow(config, index);
        }),
      ],
    );
  }

  Widget _buildTableRow(Map<String, dynamic> c, int index) {
    final isActive = c['isActive'] == true;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: index == _configs.length - 1
                ? Colors.transparent
                : AppColors.borderColor,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.successGreenBg
                        : AppColors.dangerRedBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.public_rounded,
                    color: isActive
                        ? AppColors.successGreen
                        : AppColors.dangerRed,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    c['allowedIp'] ?? '',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              '${c['radiusMeters']}m',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildStatusBadge(isActive),
            ),
          ),

          SizedBox(
            width: 70,
            child: Center(
              child: PopupMenuButton<String>(
                tooltip: 'Thao tác',
                icon: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
                padding: EdgeInsets.zero,
                onSelected: (value) async {
                  if (value == 'edit') {
                    await _editIp(c);
                  } else if (value == 'delete') {
                    final id = c['id']?.toString();

                    if (id != null && id.isNotEmpty) {
                      await _handleDelete(id);
                    }
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 10),
                        Text('Sửa'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: AppColors.dangerRed,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Xóa',
                          style: TextStyle(color: AppColors.dangerRed),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? AppColors.successGreenBg : AppColors.dangerRedBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: isActive ? AppColors.successGreen : AppColors.dangerRed,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            isActive ? 'Đang hoạt động' : 'Đã tạm ngưng',
            style: TextStyle(
              color: isActive ? AppColors.successGreen : AppColors.dangerRed,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
