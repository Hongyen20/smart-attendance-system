import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/auth_state.dart';
import 'create_employee_screen.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _employees = [];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService.getList(
      '/api/employees',
      bearerToken: AuthState.instance.token,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result.success) {
        _employees = result.data!;
      } else {
        _errorMessage = result.errorMessage;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nhân viên'),
        backgroundColor: AppColors.cardBackground,
        foregroundColor: AppColors.primaryBlue,
        elevation: 0,
      ),
      body: RefreshIndicator(onRefresh: _loadEmployees, child: _buildBody()),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateEmployeeScreen()),
          );
          _loadEmployees();
        },
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          'Thêm nhân viên',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 40),
          Icon(Icons.error_outline, color: AppColors.dangerRed, size: 40),
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.dangerRed),
          ),
        ],
      );
    }

    if (_employees.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          SizedBox(height: 60),
          Icon(Icons.groups_outlined, color: AppColors.textSecondary, size: 48),
          SizedBox(height: 12),
          Text(
            'Chưa có nhân viên nào. Bấm "Thêm nhân viên" để tạo tài khoản đầu tiên.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
      itemCount: _employees.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final e = _employees[index] as Map<String, dynamic>;
        return _buildEmployeeCard(e);
      },
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> e) {
    final status = e['status'] as String? ?? 'Active';
    final isActive = status == 'Active';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.infoBoxBackground,
            child: Text(
              ((e['fullName'] as String?)?.isNotEmpty == true)
                  ? e['fullName'][0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e['fullName'] ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.successGreenBg
                  : AppColors.dangerRedBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isActive ? AppColors.successGreen : AppColors.dangerRed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
