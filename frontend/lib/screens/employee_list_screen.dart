import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_state.dart';

import 'admin_home_screen.dart';
import 'ip_config_screen.dart';
import 'leave_approval_screen.dart';
import 'change_password_screen.dart';

import 'create_employee_screen.dart';
import 'employee_detail_screen.dart';
import 'face_management_screen.dart';
import 'business_trip_approval_screen.dart';
import 'shift_change_approval_screen.dart';
import 'attendance_report_screen.dart';
import 'login_screen.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

const Color _brightBlue = Color(0xFF2864E8);
const Color _bg = Color(0xFFF3F8FF);
const Color _navy = Color(0xFF0D2858);
const Color _textBlue = Color(0xFF31589D);
const Color _muted = Color(0xFF7185A8);
const Color _green = Color(0xFF1FA971);
const Color _orange = Color(0xFFF59E0B);

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  bool _isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String? _errorMessage;

  List<dynamic> _employees = [];

  String _searchQuery = '';

  String _selectedFilter = 'Tất cả';

  final TextEditingController _searchController = TextEditingController();

  // INIT

  @override
  void initState() {
    super.initState();

    _loadEmployees();
  }

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  // ROLE

  bool _isAdminAccount(dynamic employee) {
    if (employee is! Map) {
      return false;
    }

    final role = (employee['role'] ?? employee['roleName'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    return role == 'admin';
  }

  // LOAD EMPLOYEES

  Future<void> _loadEmployees() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final result = await ApiService.getList(
      '/api/employees',
      bearerToken: AuthState.instance.token,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;

      if (result.success) {
        _employees = (result.data ?? [])
            .where((employee) => !_isAdminAccount(employee))
            .toList();
      } else {
        _errorMessage = result.errorMessage;
      }
    });
  }

  // FILTER EMPLOYEES

  List<dynamic> get _filteredEmployees {
    Iterable<dynamic> result = _employees;

    // SEARCH
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();

      result = result.where((employee) {
        final e = employee as Map<String, dynamic>;

        final fullName = (e['fullName'] ?? '').toString().toLowerCase();

        final username = (e['username'] ?? '').toString().toLowerCase();

        final employeeCode =
            (e['employeeCode'] ?? e['employee_code'] ?? e['code'] ?? '')
                .toString()
                .toLowerCase();

        return fullName.contains(query) ||
            username.contains(query) ||
            employeeCode.contains(query);
      });
    }

    // STATUS FILTER
    if (_selectedFilter != 'Tất cả') {
      result = result.where((employee) {
        final e = employee as Map<String, dynamic>;

        final status = (e['status'] ?? 'Active').toString();

        if (_selectedFilter == 'Đang làm việc') {
          return status == 'Active' ||
              status == 'Working' ||
              status == 'Present';
        }

        if (_selectedFilter == 'Nghỉ phép') {
          return status == 'Leave' ||
              status == 'OnLeave' ||
              status == 'On Leave';
        }

        if (_selectedFilter == 'Chờ duyệt') {
          return status == 'Pending' || status == 'Waiting';
        }

        return true;
      });
    }

    return result.toList();
  }

  // STATISTICS

  int get _totalEmployees {
    return _employees.length;
  }

  int get _workingEmployees {
    return _employees.where((employee) {
      final e = employee as Map<String, dynamic>;

      final status = (e['status'] ?? 'Active').toString();

      return status == 'Active' || status == 'Working' || status == 'Present';
    }).length;
  }

  int get _pendingEmployees {
    return _employees.where((employee) {
      final e = employee as Map<String, dynamic>;

      final status = (e['status'] ?? '').toString();

      return status == 'Pending' || status == 'Waiting';
    }).length;
  }

  // NAVIGATION

  void _push(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
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
                  // _buildUserMenu(isDesktop),
                  Expanded(child: _buildContent(isDesktop)),
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
                  onTap: () => _push(const AdminHomeScreen()),
                ),

                const SizedBox(height: 8),

                _navSection(
                  icon: Icons.groups_rounded,
                  title: 'Nhân viên',
                  children: [
                    _navSubItem(
                      title: 'Danh sách nhân viên',
                      selected: true,
                      onTap: () {
                        // Đang ở màn này.
                        if (MediaQuery.sizeOf(context).width < 1000) {
                          Navigator.pop(context);
                        }
                      },
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

  // CONTENT

  Widget _buildContent(bool isDesktop) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
      children: [
        _buildPageHeader(isDesktop),

        const SizedBox(height: 20),

        _buildStatistics(),

        const SizedBox(height: 24),

        _buildToolbar(),

        const SizedBox(height: 16),

        _buildEmployeeTable(),
      ],
    );
  }

  // PAGE HEADER

  Widget _buildPageHeader(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFDDEEFF), Color(0xFFD8EDFF)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              color: Color(0xFFBFD9FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.groups_rounded,
              color: _brightBlue,
              size: 34,
            ),
          ),

          const SizedBox(width: 18),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Danh sách nhân viên',
                  style: TextStyle(
                    color: _textBlue,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'Quản lý và theo dõi thông tin nhân viên',
                  style: TextStyle(color: _textBlue, fontSize: 12.5),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),
          _buildUserMenu(isDesktop),
        ],
      ),
    );
  }

  // STATISTICS

  Widget _buildStatistics() {
    return Container(
      height: 112,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAF7)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF47679C).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatisticItem(
              title: 'Tổng nhân viên',
              value: _isLoading ? '...' : _totalEmployees.toString(),
              valueColor: _brightBlue,
              icon: Icons.groups_outlined,
            ),
          ),

          _buildStatisticDivider(),

          Expanded(
            child: _buildStatisticItem(
              title: 'Đang làm việc',
              value: _isLoading ? '...' : _workingEmployees.toString(),
              valueColor: _green,
              icon: Icons.person_outline,
            ),
          ),

          _buildStatisticDivider(),

          Expanded(
            child: _buildStatisticItem(
              title: 'Chờ duyệt',
              value: _isLoading ? '...' : _pendingEmployees.toString(),
              valueColor: _orange,
              icon: Icons.pending_actions_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticItem({
    required String title,
    required String value,
    required Color valueColor,
    required IconData icon,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: valueColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: valueColor, size: 24),
        ),

        const SizedBox(width: 14),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 3),

            Text(
              title,
              style: const TextStyle(
                color: _textBlue,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatisticDivider() {
    return Container(width: 1, height: 55, color: const Color(0xFFD5E0F1));
  }

  // TOOLBAR

  Widget _buildToolbar() {
    return Row(
      children: [
        const Text(
          'Danh sách nhân viên',
          style: TextStyle(
            color: _textBlue,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),

        const Spacer(),

        _buildSearchBox(),

        const SizedBox(width: 12),

        _buildFilterDropdown(),

        const SizedBox(width: 12),

        SizedBox(
          height: 44,
          child: ElevatedButton.icon(
            onPressed: _addEmployee,
            icon: const Icon(Icons.add, size: 19),
            label: const Text(
              'Thêm nhân viên',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _brightBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // SEARCH

  Widget _buildSearchBox() {
    return Container(
      width: 280,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD8E4F5)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: const TextStyle(color: _textBlue, fontSize: 12.5),
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.search, color: _muted, size: 21),
          hintText: 'Tìm kiếm nhân viên...',
          hintStyle: const TextStyle(color: _muted, fontSize: 12),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();

                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  icon: const Icon(Icons.close, color: _muted, size: 18),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // FILTER

  Widget _buildFilterDropdown() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD8E4F5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFilter,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: _textBlue,
            size: 20,
          ),
          borderRadius: BorderRadius.circular(12),
          items: const [
            DropdownMenuItem(
              value: 'Tất cả',
              child: Text('Tất cả', style: TextStyle(fontSize: 12)),
            ),
            DropdownMenuItem(
              value: 'Đang làm việc',
              child: Text('Đang làm việc', style: TextStyle(fontSize: 12)),
            ),
            DropdownMenuItem(
              value: 'Nghỉ phép',
              child: Text('Nghỉ phép', style: TextStyle(fontSize: 12)),
            ),
            DropdownMenuItem(
              value: 'Chờ duyệt',
              child: Text('Chờ duyệt', style: TextStyle(fontSize: 12)),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              _selectedFilter = value;
            });
          },
          style: const TextStyle(
            color: _textBlue,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // EMPLOYEE TABLE

  Widget _buildEmployeeTable() {
    if (_isLoading) {
      return Container(
        height: 260,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2EAF7)),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: _brightBlue),
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    final employees = _filteredEmployees;

    if (employees.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAF7)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF47679C).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTableHeader(),

          const Divider(height: 1, color: Color(0xFFE5EBF5)),

          ...employees.map(
            (employee) => _buildTableRow(employee as Map<String, dynamic>),
          ),
        ],
      ),
    );
  }

  // TABLE HEADER

  Widget _buildTableHeader() {
    return SizedBox(
      height: 54,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            const SizedBox(
              width: 55,
              child: Text(
                'STT',
                style: TextStyle(
                  color: _muted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const Expanded(
              flex: 3,
              child: Text(
                'NHÂN VIÊN',
                style: TextStyle(
                  color: _muted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const Expanded(
              flex: 2,
              child: Text(
                'TÀI KHOẢN',
                style: TextStyle(
                  color: _muted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const Expanded(
              flex: 2,
              child: Text(
                'TRẠNG THÁI',
                style: TextStyle(
                  color: _muted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(
              width: 70,
              child: Text(
                'THAO TÁC',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _muted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TABLE ROW

  Widget _buildTableRow(Map<String, dynamic> employee) {
    final index = _filteredEmployees.indexOf(employee);

    final id =
        employee['id'] ?? employee['employeeId'] ?? employee['employee_id'];

    final fullName = (employee['fullName'] ?? employee['name'] ?? '')
        .toString();

    final username = (employee['username'] ?? '').toString();

    final employeeCode =
        (employee['employeeCode'] ??
                employee['employee_code'] ??
                employee['code'] ??
                '')
            .toString();

    final status = (employee['status'] ?? 'Active').toString();

    final avatarUrl =
        (employee['avatar'] ??
                employee['avatarUrl'] ??
                employee['photoUrl'] ??
                '')
            .toString();

    final statusData = _getStatusData(status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openEmployeeDetail(employee),
        child: Container(
          height: 82,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFEAF0F7))),
          ),
          child: Row(
            children: [
              // STT
              SizedBox(
                width: 55,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // EMPLOYEE
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    _buildEmployeeAvatar(
                      fullName: fullName,
                      avatarUrl: avatarUrl,
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName.isEmpty ? 'Chưa có tên' : fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _textBlue,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 4),

                          if (employeeCode.isNotEmpty)
                            Text(
                              employeeCode,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 10.5,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ACCOUNT
              Expanded(
                flex: 2,
                child: Text(
                  username.isEmpty ? '—' : '@$username',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _textBlue, fontSize: 12),
                ),
              ),

              // STATUS
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: statusData.background,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: statusData.color,
                            shape: BoxShape.circle,
                          ),
                        ),

                        const SizedBox(width: 6),

                        Text(
                          statusData.label,
                          style: TextStyle(
                            color: statusData.color,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ACTION
              SizedBox(
                width: 70,
                child: Center(
                  child: PopupMenuButton<String>(
                    tooltip: 'Thao tác',
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: _muted,
                      size: 21,
                    ),
                    onSelected: (value) {
                      if (value == 'detail') {
                        if (id == null) return;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                EmployeeDetailScreen(employeeId: id.toString()),
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'detail',
                        child: Row(
                          children: [
                            Icon(Icons.person_outline_rounded, size: 18),
                            SizedBox(width: 10),
                            Text('Xem chi tiết'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // STATUS DATA

  _StatusData _getStatusData(String status) {
    if (status == 'Leave' || status == 'OnLeave' || status == 'On Leave') {
      return const _StatusData(
        label: 'Nghỉ phép',
        color: Color(0xFF1167D8),
        background: Color(0xFFE4F0FF),
      );
    }

    if (status == 'Active' || status == 'Working' || status == 'Present') {
      return const _StatusData(
        label: 'Đang làm việc',
        color: _green,
        background: Color(0xFFDDF8E8),
      );
    }

    if (status == 'Pending' || status == 'Waiting') {
      return const _StatusData(
        label: 'Chờ duyệt',
        color: _orange,
        background: Color(0xFFFFE9D9),
      );
    }

    return const _StatusData(
      label: 'Không hoạt động',
      color: Color(0xFF8A94A8),
      background: Color(0xFFE9EDF4),
    );
  }

  // EMPLOYEE AVATAR

  Widget _buildEmployeeAvatar({
    required String fullName,
    required String avatarUrl,
  }) {
    final initial = fullName.trim().isNotEmpty
        ? fullName.trim().substring(0, 1).toUpperCase()
        : '?';

    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: Color(0xFFDDEEFF),
        shape: BoxShape.circle,
      ),
      child: avatarUrl.isNotEmpty
          ? ClipOval(
              child: Image.network(
                avatarUrl,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildInitialAvatar(initial);
                },
              ),
            )
          : _buildInitialAvatar(initial),
    );
  }

  Widget _buildInitialAvatar(String initial) {
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: _textBlue,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // EMPLOYEE DETAIL

  Future<void> _openEmployeeDetail(Map<String, dynamic> employee) async {
    final id = employee['id'];

    if (id == null) return;

    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EmployeeDetailScreen(employeeId: id.toString()),
      ),
    );

    if (changed == true) {
      _loadEmployees();
    }
  }

  // ADD EMPLOYEE

  Future<void> _addEmployee() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateEmployeeScreen()),
    );

    if (created == true) {
      _loadEmployees();
    }
  }

  // ERROR STATE

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              color: Color(0xFFFFEEEE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              color: Color(0xFFE53935),
              size: 32,
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            'Không thể tải danh sách nhân viên',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textBlue,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            _errorMessage ?? 'Đã xảy ra lỗi.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 12),
          ),

          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: _loadEmployees,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Thử lại', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _brightBlue,
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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 55, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: Color(0xFFE6F0FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.groups_outlined,
              color: _brightBlue,
              size: 36,
            ),
          ),

          const SizedBox(height: 15),

          Text(
            _searchQuery.isNotEmpty
                ? 'Không tìm thấy nhân viên phù hợp.'
                : 'Chưa có nhân viên nào.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // LOGOUT

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Đăng xuất',
            style: TextStyle(color: _textBlue, fontWeight: FontWeight.w700),
          ),
          content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
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
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              child: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    AuthState.instance.clear();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}

// STATUS MODEL

class _StatusData {
  final String label;
  final Color color;
  final Color background;

  const _StatusData({
    required this.label,
    required this.color,
    required this.background,
  });
}
