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
  bool _isLoading = true;

  String? _errorMessage;

  List<dynamic> _employees = [];

  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

  static const Color primaryColor = Color(0xFF244397);
  static const Color backgroundColor = Color(0xFFF0F3FF);
  static const Color textColor = Color(0xFF202A3D);
  static const Color secondaryTextColor = Color(0xFF737D92);

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

      return fullName.contains(query) || username.contains(query);
    }).toList();
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: RefreshIndicator(
                color: primaryColor,
                onRefresh: _loadEmployees,
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: _buildAddEmployeeButton(),

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // HEADER

  Widget _buildHeader() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),

      decoration: const BoxDecoration(
        color: Colors.white,

        border: Border(bottom: BorderSide(color: Color(0xFFE2E6F2), width: 1)),
      ),

      child: Column(
        children: [
          Row(
            children: [
              // BACK BUTTON
              InkWell(
                borderRadius: BorderRadius.circular(30),

                onTap: () {
                  Navigator.pop(context);
                },

                child: const Padding(
                  padding: EdgeInsets.all(8),

                  child: Icon(Icons.arrow_back, color: primaryColor, size: 28),
                ),
              ),

              const SizedBox(width: 8),

              // LOGO
              Expanded(child: _buildLogoHeader()),

              // REFRESH
              IconButton(
                tooltip: 'Làm mới',

                onPressed: _isLoading ? null : _loadEmployees,

                icon: const Icon(Icons.refresh, color: primaryColor, size: 27),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // TITLE + COUNT
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Danh sách nhân viên',

                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                    letterSpacing: -0.4,
                  ),
                ),
              ),

              _buildEmployeeCountBadge(),
            ],
          ),

          const SizedBox(height: 12),

          // SEARCH
          _buildSearchField(),
        ],
      ),
    );
  }

  // LOGO

  Widget _buildLogoHeader() {
    return SizedBox(
      width: 105,
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
                color: primaryColor,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          );
        },
      ),
    );
  }

  // EMPLOYEE COUNT

  Widget _buildEmployeeCountBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),

      decoration: BoxDecoration(
        color: const Color(0xFFE4EBFF),

        borderRadius: BorderRadius.circular(20),
      ),

      child: Text(
        '${_filteredEmployees.length} nhân viên',

        style: const TextStyle(
          color: primaryColor,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // SEARCH

  Widget _buildSearchField() {
    return Container(
      height: 52,

      decoration: BoxDecoration(
        color: const Color(0xFFF3F5FC),

        borderRadius: BorderRadius.circular(15),

        border: Border.all(color: const Color(0xFFDDE3F3)),
      ),

      child: TextField(
        controller: _searchController,

        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },

        style: const TextStyle(fontSize: 15, color: textColor),

        decoration: InputDecoration(
          hintText: 'Tìm kiếm theo tên hoặc username...',

          hintStyle: const TextStyle(color: Color(0xFF929AAF), fontSize: 14),

          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF6F7B94),
            size: 23,
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
                    size: 20,
                    color: Color(0xFF6F7B94),
                  ),
                )
              : null,

          border: InputBorder.none,

          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  // BODY

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    // ERROR
    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),

        padding: const EdgeInsets.all(20),

        children: [
          const SizedBox(height: 60),

          Center(
            child: Container(
              width: 72,
              height: 72,

              decoration: BoxDecoration(
                color: const Color(0xFFFFEEEE),

                borderRadius: BorderRadius.circular(22),
              ),

              child: const Icon(
                Icons.error_outline,
                color: Color(0xFFE53935),
                size: 38,
              ),
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'Không thể tải danh sách nhân viên',

            textAlign: TextAlign.center,

            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF263A62),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            _errorMessage!,

            textAlign: TextAlign.center,

            style: const TextStyle(fontSize: 14, color: secondaryTextColor),
          ),

          const SizedBox(height: 20),

          Center(
            child: OutlinedButton.icon(
              onPressed: _loadEmployees,

              icon: const Icon(Icons.refresh, color: primaryColor),

              label: const Text(
                'Thử lại',

                style: TextStyle(color: primaryColor),
              ),

              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: primaryColor),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // EMPTY
    if (_employees.isEmpty) {
      return _buildEmptyState(
        message:
            'Chưa có nhân viên nào.\n'
            'Bấm "Thêm nhân viên" để tạo tài khoản đầu tiên.',
      );
    }

    final employees = _filteredEmployees;

    // SEARCH EMPTY
    if (employees.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off,

        message: 'Không tìm thấy nhân viên phù hợp.',
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),

      children: [
        _buildEmployeeSummary(employees.length),

        const SizedBox(height: 12),

        ...employees.map(
          (employee) => Padding(
            padding: const EdgeInsets.only(bottom: 10),

            child: _buildEmployeeCard(employee as Map<String, dynamic>),
          ),
        ),
      ],
    );
  }

  // SUMMARY

  Widget _buildEmployeeSummary(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: const Color(0xFFDDE2EE)),

        boxShadow: [
          BoxShadow(
            color: const Color(0xFF53689E).withValues(alpha: 0.06),

            blurRadius: 12,

            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,

            decoration: BoxDecoration(
              color: const Color(0xFFE8EDFF),

              borderRadius: BorderRadius.circular(14),
            ),

            child: const Icon(
              Icons.groups_outlined,
              color: primaryColor,
              size: 24,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Text(
              'Danh sách nhân viên',

              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF263A62),
              ),
            ),
          ),

          Text(
            '$count',

            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // EMPLOYEE CARD

  Widget _buildEmployeeCard(Map<String, dynamic> e) {
    final status = e['status'] as String? ?? 'Active';

    final isActive = status == 'Active';

    final fullName = (e['fullName'] ?? '').toString();

    final username = (e['username'] ?? '').toString();

    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';

    return Material(
      color: Colors.transparent,

      child: InkWell(
        borderRadius: BorderRadius.circular(20),

        onTap: () async {
          final changed = await Navigator.push<bool>(
            context,

            MaterialPageRoute(
              builder: (_) =>
                  EmployeeDetailScreen(employeeId: e['id'] as String),
            ),
          );

          if (changed == true) {
            _loadEmployees();
          }
        },

        child: Container(
          width: double.infinity,

          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

          decoration: BoxDecoration(
            color: Colors.white,

            borderRadius: BorderRadius.circular(20),

            border: Border.all(color: const Color(0xFFDDE2EE)),

            boxShadow: [
              BoxShadow(
                color: const Color(0xFF53689E).withValues(alpha: 0.06),

                blurRadius: 12,

                offset: const Offset(0, 5),
              ),
            ],
          ),

          child: Row(
            children: [
              // AVATAR
              Container(
                width: 58,
                height: 58,

                decoration: const BoxDecoration(
                  shape: BoxShape.circle,

                  color: Color(0xFFEAF0FF),
                ),

                child: Center(
                  child: Text(
                    initial,

                    style: const TextStyle(
                      color: primaryColor,

                      fontSize: 23,

                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // INFORMATION
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      fullName,

                      maxLines: 1,

                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        fontSize: 17,

                        fontWeight: FontWeight.w700,

                        color: textColor,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      '@$username',

                      maxLines: 1,

                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        fontSize: 14,

                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // STATUS
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),

                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFDDF8E8)
                      : const Color(0xFFFFE4E4),

                  borderRadius: BorderRadius.circular(20),
                ),

                child: Text(
                  isActive ? 'Active' : 'Inactive',

                  style: TextStyle(
                    fontSize: 12,

                    fontWeight: FontWeight.w700,

                    color: isActive
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFE53935),
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // ARROW
              const Icon(
                Icons.chevron_right,

                color: Color(0xFF9AA3B5),

                size: 25,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // EMPTY STATE

  Widget _buildEmptyState({
    IconData icon = Icons.groups_outlined,

    required String message,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.all(24),

      children: [
        const SizedBox(height: 70),

        Center(
          child: Container(
            width: 82,
            height: 82,

            decoration: BoxDecoration(
              color: const Color(0xFFE8EDFF),

              borderRadius: BorderRadius.circular(26),
            ),

            child: Icon(icon, color: primaryColor, size: 43),
          ),
        ),

        const SizedBox(height: 20),

        Text(
          message,

          textAlign: TextAlign.center,

          style: const TextStyle(
            fontSize: 15,

            height: 1.5,

            color: secondaryTextColor,
          ),
        ),
      ],
    );
  }

  // ADD EMPLOYEE BUTTON

  Widget _buildAddEmployeeButton() {
    return Material(
      elevation: 8,

      shadowColor: primaryColor.withValues(alpha: 0.30),

      borderRadius: BorderRadius.circular(18),

      child: InkWell(
        borderRadius: BorderRadius.circular(18),

        onTap: () async {
          await Navigator.push(
            context,

            MaterialPageRoute(builder: (_) => const CreateEmployeeScreen()),
          );

          _loadEmployees();
        },

        child: Container(
          height: 58,

          padding: const EdgeInsets.symmetric(horizontal: 20),

          decoration: BoxDecoration(
            color: primaryColor,

            borderRadius: BorderRadius.circular(18),
          ),

          child: const Row(
            mainAxisSize: MainAxisSize.min,

            children: [
              Icon(Icons.person_add_alt_1, color: Colors.white, size: 24),

              SizedBox(width: 10),

              Text(
                'Thêm nhân viên',

                style: TextStyle(
                  color: Colors.white,

                  fontSize: 16,

                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
