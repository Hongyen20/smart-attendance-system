import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_config.dart';
import '../services/auth_state.dart';

import 'admin_home_screen.dart';
import 'employee_list_screen.dart';
import 'ip_config_screen.dart';
import 'attendance_report_screen.dart';
import 'leave_approval_screen.dart';
import 'shift_change_approval_screen.dart';
import 'business_trip_approval_screen.dart';
import 'change_password_screen.dart';
import 'login_screen.dart';

const Color _blue = Color(0xFF2864E8);
const Color _navy = Color(0xFF0D2858);
const Color _background = Color(0xFFF5F9FF);
const Color _textBlue = Color(0xFF244397);
const Color _textGrey = Color(0xFF7185A8);
const Color _border = Color(0xFFE1E8F5);
const Color _green = Color(0xFF16A34A);
const Color _orange = Color(0xFFF59E0B);
const Color _brightBlue = Color(0xFF2864E8);

// Chiều rộng cố định của sidebar (bắt buộc, vì sidebar nằm trong Row).
const double _sidebarWidth = 270;

class FaceManagementScreen extends StatefulWidget {
  final String? token;

  const FaceManagementScreen({super.key, this.token});

  @override
  State<FaceManagementScreen> createState() => _FaceManagementScreenState();
}

class _FaceManagementScreenState extends State<FaceManagementScreen> {
  List<Map<String, dynamic>> _employees = [];

  bool _isLoading = true;
  bool _isUploading = false;

  Map<String, dynamic>? _selectedEmployee;

  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  String get _baseUrl => ApiConfig.baseUrl;

  // Ưu tiên token được truyền vào, nếu không có thì lấy từ AuthState
  // (sidebar gọi const FaceManagementScreen() không truyền token).
  String? get _token {
    final passed = widget.token;
    if (passed != null && passed.isNotEmpty) return passed;
    return AuthState.instance.token;
  }

  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${_token ?? ''}',
  };

  bool _hasFace(Map<String, dynamic> employee) {
    return employee['hasFace'] == true;
  }

  Future<void> _loadEmployees() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/employees'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as List<dynamic>;

        final employees = decoded
            .map((item) => Map<String, dynamic>.from(item as Map))
            .where((employee) => employee['role'] == 'Employee')
            .toList();

        if (!mounted) return;

        setState(() {
          _employees = employees;
        });
      } else {
        _showError('Không thể tải danh sách nhân viên.');
      }
    } catch (e) {
      _showError('Không thể kết nối đến máy chủ.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage(Map<String, dynamic> employee) async {
    if (_isUploading) return;

    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
    );

    if (file == null) return;

    final bytes = await file.readAsBytes();

    const maxFileSize = 5 * 1024 * 1024;

    if (bytes.length > maxFileSize) {
      _showError('Kích thước ảnh không được vượt quá 5MB.');
      return;
    }

    if (!mounted) return;

    setState(() {
      _selectedEmployee = employee;
      _selectedImageBytes = bytes;
      _selectedImageName = file.name;
    });

    await _uploadFace();
  }

  Future<void> _uploadFace() async {
    final employee = _selectedEmployee;
    final imageBytes = _selectedImageBytes;
    final imageName = _selectedImageName;

    if (employee == null || imageBytes == null || imageName == null) {
      return;
    }

    final employeeId = employee['id']?.toString();

    if (employeeId == null || employeeId.isEmpty) {
      _showError('Không xác định được nhân viên.');
      return;
    }

    final hasFace = _hasFace(employee);

    if (!mounted) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final uri = Uri.parse('$_baseUrl/api/face/register/$employeeId');

      final request = http.MultipartRequest('POST', uri);

      request.headers.addAll(_headers);

      request.files.add(
        http.MultipartFile.fromBytes('image', imageBytes, filename: imageName),
      );

      final streamedResponse = await request.send();

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        String message = hasFace
            ? 'Đổi ảnh khuôn mặt thành công.'
            : 'Đăng ký khuôn mặt thành công.';

        try {
          final responseData =
              jsonDecode(response.body) as Map<String, dynamic>;

          if (responseData['message'] != null) {
            message = responseData['message'].toString();
          }
        } catch (_) {}

        if (!mounted) return;

        setState(() {
          _selectedEmployee = null;
          _selectedImageBytes = null;
          _selectedImageName = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: _green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        await _loadEmployees();

        return;
      }

      String errorMessage = hasFace
          ? 'Không thể đổi ảnh khuôn mặt.'
          : 'Không thể đăng ký khuôn mặt.';

      try {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        if (responseData['message'] != null) {
          errorMessage = responseData['message'].toString();
        }
      } catch (_) {}

      _showError(errorMessage);
    } catch (e) {
      _showError('Không thể kết nối đến máy chủ.');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  int get _registeredCount {
    return _employees.where(_hasFace).length;
  }

  int get _unregisteredCount {
    return _employees.length - _registeredCount;
  }

  // NAVIGATION

  void _push(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _confirmLogout() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Đăng xuất',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF202A3D),
            ),
          ),
          content: const Text(
            'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản Admin?',
            style: TextStyle(color: Color(0xFF687389), height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Hủy',
                style: TextStyle(
                  color: Color(0xFF687389),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                AuthState.instance.clear();

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Đăng xuất',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  // SIDEBAR

  Widget _buildSidebar() {
    return Container(
      width: _sidebarWidth,
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
                  initiallyExpanded: true,
                  children: [
                    _navSubItem(
                      title: 'Danh sách nhân viên',
                      onTap: () => _push(const EmployeeListScreen()),
                    ),

                    _navSubItem(
                      title: 'Thêm khuôn mặt chấm công',
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

                // CHẤM CÔNG
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
                  style: const TextStyle(
                    color: Color(0xFFD0DDF1),
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

  // MAIN CONTENT

  Widget _buildMainContent() {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _blue))
                : RefreshIndicator(
                    onRefresh: _loadEmployees,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(28, 24, 32, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPageHeader(),

                          const SizedBox(height: 24),

                          _buildStatistics(),

                          const SizedBox(height: 30),

                          _buildEmployeeSection(),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }


  // PAGE HEADER

  Widget _buildPageHeader() {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1000;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(26, 24, 28, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFE3F0FF), Color(0xFFD5E9FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD2E4FF)),
      ),
      child: Row(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: const BoxDecoration(
              color: Color(0xFFBCD8FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.face_retouching_natural,
              color: _blue,
              size: 34,
            ),
          ),
          const SizedBox(width: 18),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thêm khuôn mặt chấm công',
                  style: TextStyle(
                    color: _textBlue,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Đăng ký hoặc cập nhật khuôn mặt dùng để xác thực chấm công cho nhân viên.',
                  style: TextStyle(color: _textGrey, fontSize: 14, height: 1.4),
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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF53689E).withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatisticItem(
              value: _employees.length.toString(),
              title: 'Tổng nhân viên',
              valueColor: _blue,
            ),
          ),
          Container(width: 1, height: 55, color: _border),
          Expanded(
            child: _buildStatisticItem(
              value: _registeredCount.toString(),
              title: 'Đã đăng ký khuôn mặt',
              valueColor: _green,
            ),
          ),
          Container(width: 1, height: 55, color: _border),
          Expanded(
            child: _buildStatisticItem(
              value: _unregisteredCount.toString(),
              title: 'Chưa đăng ký',
              valueColor: _orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticItem({
    required String value,
    required String title,
    required Color valueColor,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 27,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _textBlue,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // EMPLOYEE SECTION

  Widget _buildEmployeeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Danh sách nhân viên',
              style: TextStyle(
                color: _textBlue,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF0FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_employees.length}',
                style: const TextStyle(
                  color: _blue,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Chọn ảnh khuôn mặt rõ, chính diện và chỉ có một người.',
          style: TextStyle(color: _textGrey, fontSize: 13),
        ),
        const SizedBox(height: 18),
        if (_employees.isEmpty) _buildEmptyState() else _buildEmployeeTable(),
      ],
    );
  }

  Widget _buildEmployeeTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF53689E).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFE),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 320,
                  child: Text(
                    'NHÂN VIÊN',
                    style: TextStyle(
                      color: _textGrey,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'TRẠNG THÁI KHUÔN MẶT',
                    style: TextStyle(
                      color: _textGrey,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(
                  width: 190,
                  child: Text(
                    'THAO TÁC',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: _textGrey,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ..._employees.asMap().entries.map((entry) {
            final index = entry.key;
            final employee = entry.value;

            return _buildEmployeeRow(
              employee,
              isLast: index == _employees.length - 1,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmployeeRow(
    Map<String, dynamic> employee, {
    bool isLast = false,
  }) {
    final hasFace = _hasFace(employee);

    final fullName = employee['fullName']?.toString().trim().isNotEmpty == true
        ? employee['fullName'].toString()
        : 'Chưa có tên';

    final username = employee['username']?.toString() ?? '';

    final email = employee['email']?.toString() ?? '';

    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 320,
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEAF0FF),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: _textBlue,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF20345E),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@$username',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _textGrey, fontSize: 12),
                      ),
                      if (email.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF9AA8BD),
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildFaceStatus(hasFace),
            ),
          ),

          SizedBox(
            width: 190,
            child: Align(
              alignment: Alignment.centerRight,
              child: _buildFaceButton(employee, hasFace),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaceStatus(bool hasFace) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: hasFace ? const Color(0xFFEAF9F2) : const Color(0xFFFFF6E5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasFace ? Icons.check_circle_outline : Icons.warning_amber_rounded,
            color: hasFace ? _green : _orange,
            size: 17,
          ),
          const SizedBox(width: 7),
          Text(
            hasFace ? 'Đã đăng ký' : 'Chưa đăng ký',
            style: TextStyle(
              color: hasFace ? _green : _orange,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaceButton(Map<String, dynamic> employee, bool hasFace) {
    return SizedBox(
      height: 40,
      child: ElevatedButton.icon(
        onPressed: _isUploading ? null : () => _pickImage(employee),
        icon: Icon(
          hasFace
              ? Icons.photo_camera_back_outlined
              : Icons.add_a_photo_outlined,
          size: 18,
        ),
        label: Text(hasFace ? 'Đổi ảnh' : 'Đăng ký'),
        style: ElevatedButton.styleFrom(
          backgroundColor: hasFace ? const Color(0xFFEAF9F2) : _blue,
          foregroundColor: hasFace ? _green : Colors.white,
          disabledBackgroundColor: const Color(0xFFE7ECF5),
          disabledForegroundColor: _textGrey,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  // EMPTY STATE

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 55, horizontal: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0FF),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.people_outline, color: _blue, size: 38),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có nhân viên',
            style: TextStyle(
              color: _textBlue,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Danh sách nhân viên của công ty sẽ hiển thị tại đây.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textGrey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
