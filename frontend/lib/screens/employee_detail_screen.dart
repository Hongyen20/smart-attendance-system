import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/auth_state.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final String employeeId;

  const EmployeeDetailScreen({super.key, required this.employeeId});

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isResettingPassword = false;
  String? _errorMessage;
  Map<String, dynamic>? _employee;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadEmployee();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployee() async {
    setState(() => _isLoading = true);

    final result = await ApiService.get(
      '/api/employees/${widget.employeeId}',
      bearerToken: AuthState.instance.token,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result.success) {
        _employee = result.data;
        _fullNameController.text = _employee!['fullName'] ?? '';
        _usernameController.text = _employee!['username'] ?? '';
        _emailController.text = _employee!['email'] ?? '';
        _phoneController.text = _employee!['phone'] ?? '';
      } else {
        _errorMessage = result.errorMessage;
      }
    });
  }

  Future<void> _handleSave() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final result = await ApiService.put('/api/employees/${widget.employeeId}', {
      'fullName': _fullNameController.text.trim(),
      'username': _usernameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
    }, bearerToken: AuthState.instance.token);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result.success) {
      setState(() {
        _employee = result.data;
        _hasChanges = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu thông tin nhân viên.')),
      );
    } else {
      setState(() => _errorMessage = result.errorMessage);
    }
  }

  Future<void> _handleResetPassword() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cấp lại mật khẩu?'),
        content: Text(
          'Hệ thống sẽ sinh mật khẩu mới và gửi qua email (${_employee?['email']}). '
          'Mật khẩu cũ sẽ không còn dùng được nữa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Cấp lại',
              style: TextStyle(color: AppColors.primaryBlue),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isResettingPassword = true);

    final result = await ApiService.post(
      '/api/employees/${widget.employeeId}/reset-password',
      {},
      bearerToken: AuthState.instance.token,
    );

    if (!mounted) return;
    setState(() => _isResettingPassword = false);

    if (result.success) {
      final emailSent = result.data!['emailSent'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            emailSent
                ? 'Đã cấp lại mật khẩu và gửi email thành công.'
                : 'Đã cấp lại mật khẩu, nhưng gửi email thất bại — báo nhân viên liên hệ Admin.',
          ),
          backgroundColor: emailSent ? AppColors.successGreen : AppColors.amber,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Cấp lại mật khẩu thất bại.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {},
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Chi tiết nhân viên'),
          backgroundColor: AppColors.cardBackground,
          foregroundColor: AppColors.primaryBlue,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _hasChanges),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _employee == null
            ? Center(
                child: Text(
                  _errorMessage ?? 'Không tải được thông tin.',
                  style: const TextStyle(color: AppColors.dangerRed),
                ),
              )
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTextField(
                              controller: _fullNameController,
                              label: 'Họ tên',
                            ),
                            const SizedBox(height: 14),
                            _buildTextField(
                              controller: _usernameController,
                              label: 'Tên đăng nhập',
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Đổi tên đăng nhập sẽ khiến nhân viên phải dùng tên mới ở lần đăng nhập tiếp theo.',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildTextField(
                              controller: _emailController,
                              label: 'Email',
                            ),
                            const SizedBox(height: 14),
                            _buildTextField(
                              controller: _phoneController,
                              label: 'Số điện thoại',
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Mã nhân viên: ${_employee!['employeeCode'] ?? ''}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_errorMessage != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.dangerRedBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppColors.dangerRed,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.4,
                                  ),
                                )
                              : const Text(
                                  'Lưu thay đổi',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _isResettingPassword
                              ? null
                              : _handleResetPassword,
                          icon: _isResettingPassword
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.amber,
                                  ),
                                )
                              : const Icon(
                                  Icons.password,
                                  color: AppColors.amber,
                                ),
                          label: Text(
                            _isResettingPassword
                                ? 'Đang gửi...'
                                : 'Cấp lại mật khẩu (gửi qua email)',
                            style: const TextStyle(
                              color: AppColors.amber,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.amber),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.accentBlue,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
