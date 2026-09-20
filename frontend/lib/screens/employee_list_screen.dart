import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_state.dart';

import 'admin_home_screen.dart';
import 'ip_config_screen.dart';
import 'leave_approval_screen.dart';
import 'change_password_screen.dart';

import 'create_employee_screen.dart';
import 'employee_detail_screen.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  // COLORS
  static const Color primaryBlue = Color(0xFF12348F);

  static const Color brightBlue = Color(0xFF1464E8);

  static const Color background = Color(0xFFF5F9FF);

  static const Color textBlue = Color(0xFF31589D);

  static const Color textGrey = Color(0xFF7185A8);

  static const Color green = Color(0xFF00A94F);

  static const Color orange = Color(0xFFFF8500);

  static const Color purple = Color(0xFF5B16E8);

  // STATE

  bool _isLoading = true;

  String? _errorMessage;

  List<dynamic> _employees = [];

  String _searchQuery = '';

  String _selectedFilter = 'Tất cả';

  // Nhân viên = index 1
  int _currentBottomIndex = 1;

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
        _employees = result.data ?? [];
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

        final department = (e['department'] ?? e['departmentName'] ?? '')
            .toString()
            .toLowerCase();

        return fullName.contains(query) ||
            username.contains(query) ||
            department.contains(query);
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

  // BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      body: SafeArea(
        bottom: false,

        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                color: brightBlue,

                onRefresh: _loadEmployees,

                child: _buildMainContent(),
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: _buildFloatingButton(),

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // MAIN CONTENT

  Widget _buildMainContent() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),

      children: [
        _buildTopHeader(),

        const SizedBox(height: 12),

        _buildSearchBox(),

        const SizedBox(height: 16),

        _buildHeroCard(),

        const SizedBox(height: 16),

        _buildStatistics(),

        const SizedBox(height: 22),

        _buildEmployeeSectionHeader(),

        const SizedBox(height: 12),

        _buildEmployeeContent(),
      ],
    );
  }

  // TOP HEADER

  Widget _buildTopHeader() {
    return SizedBox(
      height: 55,

      child: Row(
        children: [
          Expanded(child: _buildLogoHeader()),

          const SizedBox(width: 10),

          _buildProfileButton(),
        ],
      ),
    );
  }

  // LOGO

  Widget _buildLogoHeader() {
    return SizedBox(
      width: 170,
      height: 48,

      child: Image.asset(
        'assets/images/logo.png',

        fit: BoxFit.contain,

        alignment: Alignment.centerLeft,

        errorBuilder: (context, error, stackTrace) {
          return const Align(
            alignment: Alignment.centerLeft,

            child: Text(
              'AttendGo',

              style: TextStyle(
                color: primaryBlue,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          );
        },
      ),
    );
  }

  // PROFILE

  Widget _buildProfileButton() {
    return Container(
      width: 46,
      height: 46,

      decoration: BoxDecoration(
        color: const Color(0xFFDCEBFF),

        shape: BoxShape.circle,

        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.08),

            blurRadius: 8,

            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: const Center(
        child: Text(
          'A',

          style: TextStyle(
            color: primaryBlue,

            fontSize: 21,

            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // SEARCH BOX

  Widget _buildSearchBox() {
    return Container(
      height: 50,

      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: const Color(0xFFE0ECFC)),
      ),

      child: TextField(
        controller: _searchController,

        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },

        style: const TextStyle(color: textBlue, fontSize: 14),

        decoration: InputDecoration(
          border: InputBorder.none,

          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF42679F),
            size: 25,
          ),

          hintText: 'Tìm kiếm nhân viên...',

          hintStyle: const TextStyle(
            color: Color(0xFF5573A5),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),

          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();

                    setState(() {
                      _searchQuery = '';
                    });
                  },

                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFF5573A5),
                    size: 20,
                  ),
                )
              : null,

          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // HERO CARD

  Widget _buildHeroCard() {
    return Container(
      height: 125,

      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,

          end: Alignment.centerRight,

          colors: [Color(0xFFDDEEFF), Color(0xFFD8EDFF)],
        ),

        borderRadius: BorderRadius.circular(20),
      ),

      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,

            decoration: const BoxDecoration(
              color: Color(0xFFBFD9FF),

              shape: BoxShape.circle,
            ),

            child: const Icon(Icons.groups, color: brightBlue, size: 42),
          ),

          const SizedBox(width: 18),

          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  'Danh sách nhân viên',

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: TextStyle(
                    color: primaryBlue,

                    fontSize: 19,

                    fontWeight: FontWeight.w800,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'Quản lý và theo dõi thông tin nhân viên',

                  maxLines: 2,

                  overflow: TextOverflow.ellipsis,

                  style: TextStyle(color: textBlue, fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // STATISTICS
  //
  // ĐÃ XÓA:
  // - ICON TRÒN TỔNG NHÂN VIÊN
  // - ICON TRÒN ĐANG LÀM VIỆC
  // - ICON TRÒN CHỜ DUYỆT

  Widget _buildStatistics() {
    return Container(
      height: 92,

      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: const Color(0xFFE2EAF7)),

        boxShadow: [
          BoxShadow(
            color: const Color(0xFF47679C).withValues(alpha: 0.07),

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

              valueColor: brightBlue,
            ),
          ),

          _buildStatisticDivider(),

          Expanded(
            child: _buildStatisticItem(
              title: 'Đang làm việc',

              value: _isLoading ? '...' : _workingEmployees.toString(),

              valueColor: green,
            ),
          ),

          _buildStatisticDivider(),

          Expanded(
            child: _buildStatisticItem(
              title: 'Chờ duyệt',

              value: _isLoading ? '...' : _pendingEmployees.toString(),

              valueColor: orange,
            ),
          ),
        ],
      ),
    );
  }

  // STATISTIC ITEM

  Widget _buildStatisticItem({
    required String title,

    required String value,

    required Color valueColor,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,

      children: [
        Text(
          value,

          style: TextStyle(
            color: valueColor,

            fontSize: 25,

            fontWeight: FontWeight.w800,

            height: 1,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          title,

          textAlign: TextAlign.center,

          maxLines: 2,

          overflow: TextOverflow.ellipsis,

          style: const TextStyle(
            color: textBlue,

            fontSize: 10.5,

            fontWeight: FontWeight.w500,

            height: 1.2,
          ),
        ),
      ],
    );
  }

  // STATISTIC DIVIDER

  Widget _buildStatisticDivider() {
    return Container(width: 1, height: 50, color: const Color(0xFFD5E0F1));
  }

  // EMPLOYEE SECTION HEADER

  Widget _buildEmployeeSectionHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Danh sách nhân viên',

            style: TextStyle(
              color: primaryBlue,

              fontSize: 17,

              fontWeight: FontWeight.w800,
            ),
          ),
        ),

        _buildFilterDropdown(),
      ],
    );
  }

  // FILTER

  Widget _buildFilterDropdown() {
    return Container(
      height: 42,

      padding: const EdgeInsets.symmetric(horizontal: 12),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(22),

        border: Border.all(color: const Color(0xFFB9D0F2), width: 1.1),
      ),

      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFilter,

          icon: const Icon(
            Icons.keyboard_arrow_down,

            color: primaryBlue,

            size: 20,
          ),

          borderRadius: BorderRadius.circular(14),

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
            if (value == null) {
              return;
            }

            setState(() {
              _selectedFilter = value;
            });
          },

          style: const TextStyle(
            color: primaryBlue,

            fontSize: 12,

            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // EMPLOYEE CONTENT

  Widget _buildEmployeeContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 50),

        child: Center(child: CircularProgressIndicator(color: brightBlue)),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    final employees = _filteredEmployees;

    if (employees.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: employees.map((employee) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),

          child: _buildEmployeeCard(employee as Map<String, dynamic>),
        );
      }).toList(),
    );
  }

  // EMPLOYEE CARD

  Widget _buildEmployeeCard(Map<String, dynamic> employee) {
    final fullName = (employee['fullName'] ?? employee['name'] ?? '')
        .toString();

    final username = (employee['username'] ?? '').toString();

    final department =
        (employee['department'] ??
                employee['departmentName'] ??
                employee['position'] ??
                'Nhân viên')
            .toString();

    final status = (employee['status'] ?? 'Active').toString();

    final avatarUrl =
        (employee['avatar'] ??
                employee['avatarUrl'] ??
                employee['photoUrl'] ??
                '')
            .toString();

    final isWorking =
        status == 'Active' || status == 'Working' || status == 'Present';

    final isLeave =
        status == 'Leave' || status == 'OnLeave' || status == 'On Leave';

    String statusText;

    Color statusColor;

    Color statusBackground;

    Color avatarBackground;

    if (isLeave) {
      statusText = 'Nghỉ phép';

      statusColor = const Color(0xFF1167D8);

      statusBackground = const Color(0xFFE4F0FF);

      avatarBackground = const Color(0xFFDDE8FF);
    } else if (isWorking) {
      statusText = 'Đang làm việc';

      statusColor = green;

      statusBackground = const Color(0xFFDDF8E8);

      avatarBackground = const Color(0xFFDDF3FF);
    } else if (status == 'Pending' || status == 'Waiting') {
      statusText = 'Chờ duyệt';

      statusColor = orange;

      statusBackground = const Color(0xFFFFE9D9);

      avatarBackground = const Color(0xFFFFE9D9);
    } else {
      statusText = 'Không hoạt động';

      statusColor = const Color(0xFF8A94A8);

      statusBackground = const Color(0xFFE9EDF4);

      avatarBackground = const Color(0xFFE9EDF4);
    }

    return Material(
      color: Colors.transparent,

      child: InkWell(
        borderRadius: BorderRadius.circular(18),

        onTap: () async {
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
        },

        child: Container(
          width: double.infinity,

          constraints: const BoxConstraints(minHeight: 104),

          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

          decoration: BoxDecoration(
            color: Colors.white,

            borderRadius: BorderRadius.circular(18),

            border: Border.all(color: const Color(0xFFE4EBF6)),

            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5674A6).withValues(alpha: 0.06),

                blurRadius: 10,

                offset: const Offset(0, 3),
              ),
            ],
          ),

          child: Row(
            children: [
              // --------------------------------------------------
              // AVATAR NHÂN VIÊN
              // --------------------------------------------------
              _buildEmployeeAvatar(
                fullName: fullName,

                avatarUrl: avatarUrl,

                background: avatarBackground,
              ),

              const SizedBox(width: 13),

              // --------------------------------------------------
              // NAME
              // --------------------------------------------------
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
                        color: primaryBlue,

                        fontSize: 15,

                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      department,

                      maxLines: 1,

                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        color: textBlue,

                        fontSize: 12,

                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    if (username.isNotEmpty) ...[
                      const SizedBox(height: 2),

                      Text(
                        '@$username',

                        maxLines: 1,

                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(color: textGrey, fontSize: 10),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 6),

              // --------------------------------------------------
              // STATUS
              // --------------------------------------------------
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),

                decoration: BoxDecoration(
                  color: statusBackground,

                  borderRadius: BorderRadius.circular(18),
                ),

                child: Row(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    Container(
                      width: 7,
                      height: 7,

                      decoration: BoxDecoration(
                        color: statusColor,

                        shape: BoxShape.circle,
                      ),
                    ),

                    const SizedBox(width: 5),

                    Text(
                      statusText,

                      style: TextStyle(
                        color: statusColor,

                        fontSize: 10,

                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 3),

              const Icon(
                Icons.chevron_right,

                color: Color(0xFF315589),

                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // EMPLOYEE AVATAR

  Widget _buildEmployeeAvatar({
    required String fullName,

    required String avatarUrl,

    required Color background,
  }) {
    final initial = fullName.trim().isNotEmpty
        ? fullName.trim().substring(0, 1).toUpperCase()
        : '?';

    return Container(
      width: 58,
      height: 58,

      decoration: BoxDecoration(color: background, shape: BoxShape.circle),

      child: avatarUrl.isNotEmpty
          ? ClipOval(
              child: Image.network(
                avatarUrl,

                width: 58,
                height: 58,

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
          color: primaryBlue,

          fontSize: 22,

          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ERROR STATE

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(24),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),
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
              color: primaryBlue,

              fontSize: 15,

              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            _errorMessage ?? 'Đã xảy ra lỗi.',

            textAlign: TextAlign.center,

            style: const TextStyle(color: textGrey, fontSize: 12),
          ),

          const SizedBox(height: 14),

          ElevatedButton.icon(
            onPressed: _loadEmployees,

            icon: const Icon(Icons.refresh, size: 18),

            label: const Text('Thử lại', style: TextStyle(fontSize: 12)),

            style: ElevatedButton.styleFrom(
              backgroundColor: brightBlue,

              foregroundColor: Colors.white,

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

      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),
      ),

      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,

            decoration: const BoxDecoration(
              color: Color(0xFFE6F0FF),

              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.groups_outlined,

              color: brightBlue,

              size: 36,
            ),
          ),

          const SizedBox(height: 14),

          Text(
            _searchQuery.isNotEmpty
                ? 'Không tìm thấy nhân viên phù hợp.'
                : 'Chưa có nhân viên nào.',

            textAlign: TextAlign.center,

            style: const TextStyle(color: textGrey, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  // FLOATING ACTION BUTTON

  Widget _buildFloatingButton() {
    return Container(
      width: 56,
      height: 56,

      decoration: BoxDecoration(
        shape: BoxShape.circle,

        gradient: const LinearGradient(
          begin: Alignment.topLeft,

          end: Alignment.bottomRight,

          colors: [Color(0xFF7228FF), Color(0xFF5012D8)],
        ),

        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5C18E8).withValues(alpha: 0.30),

            blurRadius: 12,

            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Material(
        color: Colors.transparent,

        shape: const CircleBorder(),

        child: InkWell(
          customBorder: const CircleBorder(),

          onTap: _addEmployee,

          child: const Center(
            child: Icon(Icons.add, color: Colors.white, size: 32),
          ),
        ),
      ),
    );
  }

  // ADD EMPLOYEE

  Future<void> _addEmployee() async {
    await Navigator.push(
      context,

      MaterialPageRoute(builder: (_) => const CreateEmployeeScreen()),
    );

    _loadEmployees();
  }

  // BOTTOM NAVIGATION

  Widget _buildBottomNavigation() {
    return Container(
      height: 82,

      decoration: const BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),

          topRight: Radius.circular(30),
        ),

        boxShadow: [
          BoxShadow(
            color: Color(0x18000000),

            blurRadius: 15,

            offset: Offset(0, -3),
          ),
        ],
      ),

      child: SafeArea(
        top: false,

        child: Row(
          children: [
            // TRANG CHỦ
            _buildNavItem(
              index: 0,

              icon: Icons.home_outlined,

              activeIcon: Icons.home,

              label: 'Trang chủ',

              onTap: () {
                Navigator.pushReplacement(
                  context,

                  MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
                );
              },
            ),

            // NHÂN VIÊN
            _buildNavItem(
              index: 1,

              icon: Icons.people_outline,

              activeIcon: Icons.people,

              label: 'Nhân viên',

              onTap: () {
                // Đang ở trang này.
              },
            ),

            // CHẤM CÔNG
            _buildNavItem(
              index: 2,

              icon: Icons.access_time_outlined,

              activeIcon: Icons.access_time,

              label: 'Chấm công',

              onTap: () {
                Navigator.push(
                  context,

                  MaterialPageRoute(builder: (_) => const IpConfigScreen()),
                );
              },
            ),

            // YÊU CẦU
            _buildNavItem(
              index: 3,

              icon: Icons.description_outlined,

              activeIcon: Icons.description,

              label: 'Yêu cầu',

              onTap: () {
                Navigator.push(
                  context,

                  MaterialPageRoute(
                    builder: (_) => const LeaveApprovalScreen(),
                  ),
                );
              },
            ),

            // CÀI ĐẶT
            _buildNavItem(
              index: 4,

              icon: Icons.settings_outlined,

              activeIcon: Icons.settings,

              label: 'Cài đặt',

              onTap: () {
                Navigator.push(
                  context,

                  MaterialPageRoute(
                    builder: (_) => const ChangePasswordScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // NAV ITEM

  Widget _buildNavItem({
    required int index,

    required IconData icon,

    required IconData activeIcon,

    required String label,

    required VoidCallback onTap,
  }) {
    final isSelected = _currentBottomIndex == index;

    return Expanded(
      child: InkWell(
        onTap: onTap,

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(
              isSelected ? activeIcon : icon,

              color: isSelected ? purple : const Color(0xFF526B9B),

              size: 26,
            ),

            const SizedBox(height: 3),

            Text(
              label,

              style: TextStyle(
                color: isSelected ? purple : const Color(0xFF526B9B),

                fontSize: 10.5,

                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),

            const SizedBox(height: 3),

            AnimatedContainer(
              duration: const Duration(milliseconds: 200),

              width: isSelected ? 34 : 0,

              height: 2.5,

              decoration: BoxDecoration(
                color: isSelected ? purple : Colors.transparent,

                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
