import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_state.dart';

import 'create_employee_screen.dart';
import 'employee_detail_screen.dart';
import 'ip_config_screen.dart';
import 'leave_approval_screen.dart';
import 'change_password_screen.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  bool _isLoading = true;

  String? _errorMessage;

  List<dynamic> _employees = [];

  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

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

  // FILTER

  List<dynamic> get _filteredEmployees {
    if (_searchQuery.trim().isEmpty) {
      return _employees;
    }

    final query = _searchQuery.trim().toLowerCase();

    return _employees.where((employee) {
      final e = employee as Map<String, dynamic>;

      final fullName = (e['fullName'] ?? '').toString().toLowerCase();

      final username = (e['username'] ?? '').toString().toLowerCase();

      final department = (e['department'] ?? e['departmentName'] ?? '')
          .toString()
          .toLowerCase();

      return fullName.contains(query) ||
          username.contains(query) ||
          department.contains(query);
    }).toList();
  }

  // STATISTICS

  int get _totalEmployees => _employees.length;

  int get _workingEmployees {
    return _employees.where((employee) {
      final e = employee as Map<String, dynamic>;
      final status = (e['status'] ?? '').toString().toLowerCase();

      return status == 'active' || status == 'working' || status == 'approved';
    }).length;
  }

  int get _pendingEmployees {
    return _employees.where((employee) {
      final e = employee as Map<String, dynamic>;
      final status = (e['status'] ?? '').toString().toLowerCase();

      return status == 'pending' || status == 'inactive' || status == 'waiting';
    }).length;
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),

      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF244397),
                onRefresh: _loadEmployees,
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: _buildAddEmployeeButton(),

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // HEADER

  Widget _buildHeader() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),

      decoration: const BoxDecoration(
        color: Colors.white,

        border: Border(bottom: BorderSide(color: Color(0xFFE4E8F0), width: 1)),
      ),

      child: Column(
        children: [
          Row(
            children: [
              // BACK BUTTON
              Material(
                color: Colors.transparent,

                child: InkWell(
                  borderRadius: BorderRadius.circular(24),

                  onTap: () {
                    Navigator.pop(context);
                  },

                  child: const Padding(
                    padding: EdgeInsets.all(7),

                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFF244397),
                      size: 21,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // LOGO
              SizedBox(
                width: 92,
                height: 42,

                child: Image.asset(
                  'assets/images/logo.png',

                  fit: BoxFit.contain,

                  alignment: Alignment.centerLeft,
                ),
              ),

              const SizedBox(width: 8),

              // TITLE
              const Expanded(
                child: Text(
                  'Nhân viên',

                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF244397),
                  ),
                ),
              ),

              // REFRESH
              IconButton(
                tooltip: 'Làm mới',

                padding: EdgeInsets.zero,

                constraints: const BoxConstraints(minWidth: 38, minHeight: 38),

                onPressed: _isLoading ? null : _loadEmployees,

                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Color(0xFF244397),
                  size: 23,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          _buildSearchField(),
        ],
      ),
    );
  }

  // SEARCH

  Widget _buildSearchField() {
    return Container(
      height: 45,

      decoration: BoxDecoration(
        color: const Color(0xFFF3F5FA),

        borderRadius: BorderRadius.circular(13),

        border: Border.all(color: const Color(0xFFE0E5EF)),
      ),

      child: TextField(
        controller: _searchController,

        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },

        style: const TextStyle(fontSize: 13.5, color: Color(0xFF202A3D)),

        decoration: InputDecoration(
          hintText: 'Tìm theo tên, username hoặc phòng ban',

          hintStyle: const TextStyle(color: Color(0xFF969EAF), fontSize: 12.5),

          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF77829A),
            size: 20,
          ),

          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  padding: EdgeInsets.zero,

                  onPressed: () {
                    _searchController.clear();

                    setState(() {
                      _searchQuery = '';
                    });
                  },

                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF77829A),
                    size: 18,
                  ),
                )
              : null,

          border: InputBorder.none,

          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // BODY

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF244397),
          strokeWidth: 2.5,
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_employees.isEmpty) {
      return _buildEmptyState(
        message:
            'Chưa có nhân viên nào.\n'
            'Bấm "Thêm nhân viên" để tạo tài khoản đầu tiên.',
      );
    }

    final employees = _filteredEmployees;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.fromLTRB(15, 14, 15, 110),

      children: [
        // STATISTICS
        _buildStatistics(),

        const SizedBox(height: 18),

        // TITLE
        Row(
          children: [
            const Text(
              'Danh sách nhân viên',

              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF263A62),
              ),
            ),

            const Spacer(),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),

              decoration: BoxDecoration(
                color: const Color(0xFFE7EDFF),
                borderRadius: BorderRadius.circular(20),
              ),

              child: Text(
                '${employees.length} nhân viên',

                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF244397),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        if (employees.isEmpty)
          _buildEmptyState(
            icon: Icons.search_off_rounded,
            message: 'Không tìm thấy nhân viên phù hợp.',
          )
        else
          ...employees.map((employee) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 9),

              child: _buildEmployeeCard(employee as Map<String, dynamic>),
            );
          }),
      ],
    );
  }

  // STATISTICS

  Widget _buildStatistics() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: const Color(0xFFE1E6F0)),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),

            blurRadius: 10,

            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Row(
        children: [
          Expanded(
            child: _buildStatisticItem(
              label: 'Tổng nhân viên',
              value: '$_totalEmployees',
              valueColor: const Color(0xFF244397),
            ),
          ),

          Container(width: 1, height: 42, color: const Color(0xFFE2E6EF)),

          Expanded(
            child: _buildStatisticItem(
              label: 'Đang làm việc',
              value: '$_workingEmployees',
              valueColor: const Color(0xFF159957),
            ),
          ),

          Container(width: 1, height: 42, color: const Color(0xFFE2E6EF)),

          Expanded(
            child: _buildStatisticItem(
              label: 'Chờ duyệt',
              value: '$_pendingEmployees',
              valueColor: const Color(0xFFEA8A17),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticItem({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      children: [
        Text(
          value,

          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          label,

          textAlign: TextAlign.center,

          maxLines: 2,

          overflow: TextOverflow.ellipsis,

          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: Color(0xFF7A8498),
          ),
        ),
      ],
    );
  }

  // EMPLOYEE CARD

  Widget _buildEmployeeCard(Map<String, dynamic> e) {
    final status = (e['status'] ?? 'Active').toString();

    final fullName = (e['fullName'] ?? '').toString();

    final username = (e['username'] ?? '').toString();

    final department = (e['department'] ?? e['departmentName'] ?? '')
        .toString();

    final isActive =
        status.toLowerCase() == 'active' || status.toLowerCase() == 'working';

    return Material(
      color: Colors.transparent,

      child: InkWell(
        borderRadius: BorderRadius.circular(16),

        onTap: () async {
          final employeeId = e['id']?.toString();

          if (employeeId == null || employeeId.isEmpty) {
            return;
          }

          final changed = await Navigator.push<bool>(
            context,

            MaterialPageRoute(
              builder: (_) => EmployeeDetailScreen(employeeId: employeeId),
            ),
          );

          if (changed == true) {
            _loadEmployees();
          }
        },

        child: Container(
          width: double.infinity,

          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),

          decoration: BoxDecoration(
            color: Colors.white,

            borderRadius: BorderRadius.circular(16),

            border: Border.all(color: const Color(0xFFE0E5EF)),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.025),

                blurRadius: 8,

                offset: const Offset(0, 3),
              ),
            ],
          ),

          child: Row(
            children: [
              // AVATAR 
              Container(
                width: 48,
                height: 48,

                decoration: const BoxDecoration(
                  shape: BoxShape.circle,

                  color: Color(0xFFEAF0FF),
                ),

                child: const Icon(
                  Icons.person_outline_rounded,

                  color: Color(0xFF5875A8),

                  size: 27,
                ),
              ),

              const SizedBox(width: 11),

              // INFORMATION
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      fullName.isEmpty ? 'Chưa có tên' : fullName,

                      maxLines: 1,

                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF202A3D),
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      username.isEmpty ? 'Chưa có username' : '@$username',

                      maxLines: 1,

                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF7B8598),
                      ),
                    ),

                    if (department.isNotEmpty) ...[
                      const SizedBox(height: 2),

                      Text(
                        department,

                        maxLines: 1,

                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF9AA3B4),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 7),

              // STATUS
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),

                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFE1F7E9)
                      : const Color(0xFFFFE7E7),

                  borderRadius: BorderRadius.circular(20),
                ),

                child: Text(
                  isActive ? 'Đang làm' : 'Chờ duyệt',

                  style: TextStyle(
                    fontSize: 9.5,

                    fontWeight: FontWeight.w700,

                    color: isActive
                        ? const Color(0xFF159957)
                        : const Color(0xFFE05252),
                  ),
                ),
              ),

              const SizedBox(width: 2),

              const Icon(
                Icons.chevron_right_rounded,

                color: Color(0xFFA3ABBA),

                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ERROR

  Widget _buildErrorState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.symmetric(horizontal: 24),

      children: [
        const SizedBox(height: 70),

        Center(
          child: Container(
            width: 70,
            height: 70,

            decoration: BoxDecoration(
              color: const Color(0xFFFFEEEE),

              borderRadius: BorderRadius.circular(22),
            ),

            child: const Icon(
              Icons.error_outline_rounded,

              color: Color(0xFFE53935),

              size: 36,
            ),
          ),
        ),

        const SizedBox(height: 16),

        const Text(
          'Không thể tải danh sách nhân viên',

          textAlign: TextAlign.center,

          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF263A62),
          ),
        ),

        const SizedBox(height: 7),

        Text(
          _errorMessage ?? 'Đã xảy ra lỗi.',

          textAlign: TextAlign.center,

          style: const TextStyle(fontSize: 12.5, color: Color(0xFF737D92)),
        ),

        const SizedBox(height: 18),

        Center(
          child: OutlinedButton.icon(
            onPressed: _loadEmployees,

            icon: const Icon(Icons.refresh_rounded, size: 18),

            label: const Text('Thử lại', style: TextStyle(fontSize: 13)),

            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF244397),

              side: const BorderSide(color: Color(0xFF244397)),

              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 10),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // EMPTY STATE

  Widget _buildEmptyState({
    IconData icon = Icons.groups_outlined,
    required String message,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.symmetric(horizontal: 24),

      children: [
        const SizedBox(height: 65),

        Center(
          child: Container(
            width: 76,
            height: 76,

            decoration: BoxDecoration(
              color: const Color(0xFFEAF0FF),

              borderRadius: BorderRadius.circular(23),
            ),

            child: Icon(icon, color: const Color(0xFF244397), size: 38),
          ),
        ),

        const SizedBox(height: 17),

        Text(
          message,

          textAlign: TextAlign.center,

          style: const TextStyle(
            fontSize: 13,
            height: 1.5,
            color: Color(0xFF737D92),
          ),
        ),
      ],
    );
  }

  // ADD EMPLOYEE BUTTON

  Widget _buildAddEmployeeButton() {
    return Material(
      elevation: 7,

      shadowColor: const Color(0xFF244397).withOpacity(0.25),

      borderRadius: BorderRadius.circular(16),

      child: InkWell(
        borderRadius: BorderRadius.circular(16),

        onTap: () async {
          await Navigator.push(
            context,

            MaterialPageRoute(builder: (_) => const CreateEmployeeScreen()),
          );

          _loadEmployees();
        },

        child: Container(
          height: 52,

          padding: const EdgeInsets.symmetric(horizontal: 17),

          decoration: BoxDecoration(
            color: const Color(0xFF244397),

            borderRadius: BorderRadius.circular(16),
          ),

          child: const Row(
            mainAxisSize: MainAxisSize.min,

            children: [
              Icon(
                Icons.person_add_alt_1_rounded,

                color: Colors.white,

                size: 21,
              ),

              SizedBox(width: 8),

              Text(
                'Thêm nhân viên',

                style: TextStyle(
                  color: Colors.white,

                  fontSize: 13.5,

                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // BOTTOM NAVIGATION

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),

            blurRadius: 12,

            offset: const Offset(0, -3),
          ),
        ],
      ),

      child: SafeArea(
        top: false,

        child: SizedBox(
          height: 62,

          child: Row(
            children: [
              Expanded(
                child: _buildNavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Trang chủ',

                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ),

              Expanded(
                child: _buildNavItem(
                  icon: Icons.access_time_outlined,
                  activeIcon: Icons.access_time_rounded,
                  label: 'Chấm công',

                  onTap: () {
                    Navigator.push(
                      context,

                      MaterialPageRoute(builder: (_) => const IpConfigScreen()),
                    );
                  },
                ),
              ),

              Expanded(
                child: _buildNavItem(
                  icon: Icons.assignment_outlined,
                  activeIcon: Icons.assignment_rounded,
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
              ),

              Expanded(
                child: _buildNavItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings_rounded,
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  // NAV ITEM

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Icon(icon, color: const Color(0xFF7C879B), size: 22),

          const SizedBox(height: 3),

          Text(
            label,

            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF7C879B),
            ),
          ),
        ],
      ),
    );
  }
}
