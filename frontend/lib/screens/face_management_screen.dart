import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_config.dart';
import '../theme/app_colors.dart';

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

  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${widget.token ?? ''}',
  };

  bool _hasFace(Map<String, dynamic> employee) {
    return employee['hasFace'] == true;
  }

  Future<void> _loadEmployees() async {
    if (!mounted) {
      return;
    }

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

        if (!mounted) {
          return;
        }

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
    if (_isUploading) {
      return;
    }

    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
    );

    if (file == null) {
      return;
    }

    final bytes = await file.readAsBytes();

    const maxFileSize = 5 * 1024 * 1024;

    if (bytes.length > maxFileSize) {
      _showError('Kích thước ảnh không được vượt quá 5MB.');
      return;
    }

    if (!mounted) {
      return;
    }

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

    if (!mounted) {
      return;
    }

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
        } catch (_) {
          // Giữ message mặc định.
        }

        if (!mounted) {
          return;
        }

        setState(() {
          _selectedEmployee = null;
          _selectedImageBytes = null;
          _selectedImageName = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
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
      } catch (_) {
        // Giữ message mặc định.
      }

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
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  int get _registeredCount {
    return _employees.where(_hasFace).length;
  }

  int get _unregisteredCount {
    return _employees.length - _registeredCount;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: Colors.black87,
        title: const Text(
          'Quản lý khuôn mặt',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadEmployees,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildStatistics(),
                    const SizedBox(height: 24),
                    _buildEmployeeSection(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.accentBlue],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.face_retouching_natural,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Xác thực khuôn mặt',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Quản lý khuôn mặt dùng cho chấm công',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.88),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    return Row(
      children: [
        Expanded(
          child: _buildStatisticCard(
            title: 'Đã đăng ký',
            value: _registeredCount.toString(),
            icon: Icons.check_circle_outline,
            iconColor: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatisticCard(
            title: 'Chưa đăng ký',
            value: _unregisteredCount.toString(),
            icon: Icons.remove_circle_outline,
            iconColor: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatisticCard(
            title: 'Tổng số',
            value: _employees.length.toString(),
            icon: Icons.people_outline,
            iconColor: AppColors.primaryBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 25),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Danh sách nhân viên',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Chọn ảnh khuôn mặt rõ và chỉ có một người.',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        const SizedBox(height: 16),
        if (_employees.isEmpty)
          _buildEmptyState()
        else
          ..._employees.map(_buildEmployeeCard),
      ],
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> employee) {
    final hasFace = _hasFace(employee);

    final fullName = employee['fullName']?.toString().trim().isNotEmpty == true
        ? employee['fullName'].toString()
        : 'Chưa có tên';

    final username = employee['username']?.toString() ?? '';

    final email = employee['email']?.toString() ?? '';

    final status = employee['status']?.toString() ?? 'Active';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasFace
              ? Colors.green.withOpacity(0.18)
              : Colors.grey.withOpacity(0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: hasFace
                      ? Colors.green.withOpacity(0.10)
                      : AppColors.primaryBlue.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_outline,
                  color: hasFace ? Colors.green : AppColors.primaryBlue,
                  size: 26,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      username,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _buildStatusBadge(hasFace),
            ],
          ),
          const SizedBox(height: 15),
          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      hasFace
                          ? Icons.verified_user_outlined
                          : Icons.person_off_outlined,
                      size: 19,
                      color: hasFace ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hasFace
                            ? 'Đã đăng ký khuôn mặt'
                            : 'Chưa đăng ký khuôn mặt',
                        style: TextStyle(
                          color: hasFace ? Colors.green : Colors.orange,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : () => _pickImage(employee),
              icon: Icon(
                hasFace
                    ? Icons.photo_camera_back_outlined
                    : Icons.add_a_photo_outlined,
                size: 19,
              ),
              label: Text(hasFace ? 'Đổi ảnh khuôn mặt' : 'Đăng ký khuôn mặt'),
              style: ElevatedButton.styleFrom(
                backgroundColor: hasFace ? Colors.green : AppColors.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (status.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Trạng thái tài khoản: $status',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool hasFace) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: hasFace
            ? Colors.green.withOpacity(0.10)
            : Colors.orange.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: hasFace ? Colors.green : Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            hasFace ? 'Đã đăng ký' : 'Chưa đăng ký',
            style: TextStyle(
              color: hasFace ? Colors.green : Colors.orange,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'Chưa có nhân viên',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(
            'Danh sách nhân viên của công ty sẽ hiển thị tại đây.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
