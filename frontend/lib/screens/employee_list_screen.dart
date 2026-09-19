import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_state.dart';

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

  static const Color textDark = Color(0xFF102A72);
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

      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),

      children: [
        _buildTopHeader(),

        const SizedBox(height: 14),

        _buildSearchBox(),

        const SizedBox(height: 20),

        _buildHeroCard(),

        const SizedBox(height: 20),

        _buildStatistics(),

        const SizedBox(height: 28),

        _buildEmployeeSectionHeader(),

        const SizedBox(height: 14),

        _buildEmployeeContent(),
      ],
    );
  }

  // TOP HEADER

  Widget _buildTopHeader() {
    return SizedBox(
      height: 62,

      child: Row(
        children: [
          // LOGO
          Expanded(child: _buildLogoHeader()),

          const SizedBox(width: 12),

          // PROFILE
          _buildProfileButton(),
        ],
      ),
    );
  }

  // LOGO

  Widget _buildLogoHeader() {
    return SizedBox(
      width: 180,
      height: 52,

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

                fontSize: 26,

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
      width: 58,
      height: 58,

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

            fontSize: 28,

            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // SEARCH BOX

  Widget _buildSearchBox() {
    return Container(
      height: 62,

      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: const Color(0xFFE0ECFC)),
      ),

      child: TextField(
        controller: _searchController,

        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },

        style: const TextStyle(color: textBlue, fontSize: 17),

        decoration: InputDecoration(
          border: InputBorder.none,

          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF42679F),
            size: 34,
          ),

          hintText: 'Tìm kiếm nhân viên...',

          hintStyle: const TextStyle(
            color: Color(0xFF5573A5),

            fontSize: 17,

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

                  icon: const Icon(Icons.close, color: Color(0xFF5573A5)),
                )
              : null,

          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  // HERO CARD

  Widget _buildHeroCard() {
    return Container(
      height: 156,

      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,

          end: Alignment.centerRight,

          colors: [Color(0xFFDDEEFF), Color(0xFFD8EDFF)],
        ),

        borderRadius: BorderRadius.circular(22),
      ),

      child: Row(
        children: [
          Container(
            width: 92,
            height: 92,

            decoration: const BoxDecoration(
              color: Color(0xFFBFD9FF),

              shape: BoxShape.circle,
            ),

            child: const Icon(Icons.groups, color: brightBlue, size: 55),
          ),

          const SizedBox(width: 24),

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

                    fontSize: 24,

                    fontWeight: FontWeight.w800,
                  ),
                ),

                SizedBox(height: 7),

                Text(
                  'Quản lý và theo dõi thông tin nhân viên',

                  maxLines: 2,

                  overflow: TextOverflow.ellipsis,

                  style: TextStyle(color: textBlue, fontSize: 16, height: 1.25),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // STATISTICS

  Widget _buildStatistics() {
    return Container(
      height: 132,

      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(22),

        boxShadow: [
          BoxShadow(
            color: const Color(0xFF47679C).withValues(alpha: 0.10),

            blurRadius: 18,

            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Row(
        children: [
          Expanded(
            child: _buildStatisticItem(
              icon: Icons.groups,

              iconBackground: const Color(0xFFD9E9FF),

              iconColor: brightBlue,

              title: 'Tổng nhân viên',

              value: _totalEmployees.toString(),

              valueColor: brightBlue,
            ),
          ),

          _buildStatisticDivider(),

          Expanded(
            child: _buildStatisticItem(
              icon: Icons.person,

              iconBackground: const Color(0xFFD9F9E6),

              iconColor: green,

              title: 'Đang làm việc',

              value: _workingEmployees.toString(),

              valueColor: green,
            ),
          ),

          _buildStatisticDivider(),

          Expanded(
            child: _buildStatisticItem(
              icon: Icons.pending_actions,

              iconBackground: const Color(0xFFFFEADB),

              iconColor: orange,

              title: 'Chờ duyệt',

              value: _pendingEmployees.toString(),

              valueColor: orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticDivider() {
    return Container(width: 1, height: 72, color: const Color(0xFFD5E0F1));
  }

  Widget _buildStatisticItem({
    required IconData icon,

    required Color iconBackground,

    required Color iconColor,

    required String title,

    required String value,

    required Color valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),

      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,

            decoration: BoxDecoration(
              color: iconBackground,

              shape: BoxShape.circle,
            ),

            child: Icon(icon, color: iconColor, size: 30),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,

                  maxLines: 2,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: textBlue,

                    fontSize: 14,

                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  value,

                  style: TextStyle(
                    color: valueColor,

                    fontSize: 30,

                    fontWeight: FontWeight.w800,

                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // EMPLOYEE SECTION HEADER

  Widget _buildEmployeeSectionHeader() {
    return Row(
      children: [
        const Icon(Icons.groups, color: brightBlue, size: 31),

        const SizedBox(width: 12),

        const Expanded(
          child: Text(
            'Danh sách nhân viên',

            style: TextStyle(
              color: primaryBlue,

              fontSize: 22,

              fontWeight: FontWeight.w800,
            ),
          ),
        ),

        _buildFilterDropdown(),
      ],
    );
  }

  // FILTER DROPDOWN

  Widget _buildFilterDropdown() {
    return Container(
      height: 52,

      padding: const EdgeInsets.symmetric(horizontal: 16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(28),

        border: Border.all(color: const Color(0xFFB9D0F2), width: 1.3),
      ),

      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFilter,

          icon: const Icon(
            Icons.keyboard_arrow_down,

            color: primaryBlue,

            size: 25,
          ),

          borderRadius: BorderRadius.circular(14),

          items: const [
            DropdownMenuItem(value: 'Tất cả', child: Text('Tất cả')),

            DropdownMenuItem(
              value: 'Đang làm việc',

              child: Text('Đang làm việc'),
            ),

            DropdownMenuItem(value: 'Nghỉ phép', child: Text('Nghỉ phép')),

            DropdownMenuItem(value: 'Chờ duyệt', child: Text('Chờ duyệt')),
          ],

          onChanged: (value) {
            if (value == null) return;

            setState(() {
              _selectedFilter = value;
            });
          },

          style: const TextStyle(
            color: primaryBlue,

            fontSize: 15,

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
          padding: const EdgeInsets.only(bottom: 12),

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
        borderRadius: BorderRadius.circular(20),

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

          constraints: const BoxConstraints(minHeight: 120),

          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),

          decoration: BoxDecoration(
            color: Colors.white,

            borderRadius: BorderRadius.circular(20),

            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5674A6).withValues(alpha: 0.08),

                blurRadius: 15,

                offset: const Offset(0, 5),
              ),
            ],
          ),

          child: Row(
            children: [
              // AVATAR
              _buildEmployeeAvatar(
                fullName: fullName,

                avatarUrl: avatarUrl,

                background: avatarBackground,
              ),

              const SizedBox(width: 18),

              // NAME + DEPARTMENT
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

                        fontSize: 18,

                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      department,

                      maxLines: 1,

                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        color: textBlue,

                        fontSize: 15,

                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    if (username.isNotEmpty) ...[
                      const SizedBox(height: 3),

                      Text(
                        '@$username',

                        maxLines: 1,

                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(color: textGrey, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // STATUS
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),

                decoration: BoxDecoration(
                  color: statusBackground,

                  borderRadius: BorderRadius.circular(22),
                ),

                child: Row(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    Container(
                      width: 10,
                      height: 10,

                      decoration: BoxDecoration(
                        color: statusColor,

                        shape: BoxShape.circle,
                      ),
                    ),

                    const SizedBox(width: 8),

                    Text(
                      statusText,

                      style: TextStyle(
                        color: statusColor,

                        fontSize: 13,

                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // ARROW
              const Icon(
                Icons.chevron_right,

                color: Color(0xFF315589),

                size: 30,
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
      width: 74,
      height: 74,

      decoration: BoxDecoration(color: background, shape: BoxShape.circle),

      child: avatarUrl.isNotEmpty
          ? ClipOval(
              child: Image.network(
                avatarUrl,

                width: 74,
                height: 74,

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

          fontSize: 28,

          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ERROR STATE

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(28),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),
      ),

      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,

            decoration: BoxDecoration(
              color: const Color(0xFFFFEEEE),

              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.error_outline,

              color: Color(0xFFE53935),

              size: 38,
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'Không thể tải danh sách nhân viên',

            textAlign: TextAlign.center,

            style: TextStyle(
              color: primaryBlue,

              fontSize: 17,

              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            _errorMessage ?? 'Đã xảy ra lỗi.',

            textAlign: TextAlign.center,

            style: const TextStyle(color: textGrey, fontSize: 14),
          ),

          const SizedBox(height: 18),

          ElevatedButton.icon(
            onPressed: _loadEmployees,

            icon: const Icon(Icons.refresh),

            label: const Text('Thử lại'),

            style: ElevatedButton.styleFrom(
              backgroundColor: brightBlue,

              foregroundColor: Colors.white,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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

      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),
      ),

      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,

            decoration: const BoxDecoration(
              color: Color(0xFFE6F0FF),

              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.groups_outlined,

              color: brightBlue,

              size: 42,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            _searchQuery.isNotEmpty
                ? 'Không tìm thấy nhân viên phù hợp.'
                : 'Chưa có nhân viên nào.',

            textAlign: TextAlign.center,

            style: const TextStyle(color: textGrey, fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
  }

  // FLOATING ACTION BUTTON

  Widget _buildFloatingButton() {
    return Container(
      width: 62,
      height: 62,

      decoration: BoxDecoration(
        shape: BoxShape.circle,

        gradient: const LinearGradient(
          begin: Alignment.topLeft,

          end: Alignment.bottomRight,

          colors: [Color(0xFF7228FF), Color(0xFF5012D8)],
        ),

        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5C18E8).withValues(alpha: 0.35),

            blurRadius: 15,

            offset: const Offset(0, 7),
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
            child: Icon(Icons.add, color: Colors.white, size: 39),
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
      height: 92,

      decoration: const BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(38),

          topRight: Radius.circular(38),
        ),

        boxShadow: [
          BoxShadow(
            color: Color(0x18000000),

            blurRadius: 18,

            offset: Offset(0, -3),
          ),
        ],
      ),

      child: SafeArea(
        top: false,

        child: Row(
          children: [
            _buildNavItem(
              index: 0,

              icon: Icons.home_outlined,

              activeIcon: Icons.home,

              label: 'Trang chủ',
            ),

            _buildNavItem(
              index: 1,

              icon: Icons.people_outline,

              activeIcon: Icons.people,

              label: 'Nhân viên',
            ),

            _buildNavItem(
              index: 2,

              icon: Icons.access_time_outlined,

              activeIcon: Icons.access_time,

              label: 'Chấm công',
            ),

            _buildNavItem(
              index: 3,

              icon: Icons.description_outlined,

              activeIcon: Icons.description,

              label: 'Yêu cầu',
            ),

            _buildNavItem(
              index: 4,

              icon: Icons.settings_outlined,

              activeIcon: Icons.settings,

              label: 'Cài đặt',
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
  }) {
    final isSelected = _currentBottomIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentBottomIndex = index;
          });

          // Màn nhân viên đang là màn hiện tại.
          //
          // Khi bạn có các màn:
          // Trang chủ / Chấm công / Yêu cầu /
          // Cài đặt, có thể Navigator.push()
          // tương ứng ở đây.
        },

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(
              isSelected ? activeIcon : icon,

              color: isSelected ? purple : const Color(0xFF526B9B),

              size: 30,
            ),

            const SizedBox(height: 5),

            Text(
              label,

              style: TextStyle(
                color: isSelected ? purple : const Color(0xFF526B9B),

                fontSize: 13,

                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),

            const SizedBox(height: 4),

            AnimatedContainer(
              duration: const Duration(milliseconds: 200),

              width: isSelected ? 42 : 0,

              height: 3,

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
