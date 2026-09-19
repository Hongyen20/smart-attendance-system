import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_config.dart';
import '../theme/app_colors.dart';

class FaceManagementScreen extends StatefulWidget {
  final String token;

  const FaceManagementScreen({super.key, required this.token});

  @override
  State<FaceManagementScreen> createState() => _FaceManagementScreenState();
}

class _FaceManagementScreenState extends State<FaceManagementScreen> {
  List<Map<String, dynamic>> _employees = [];

  Map<String, dynamic>? _selectedEmployee;

  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  bool _isLoading = true;
  bool _isRegistering = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  // LOAD EMPLOYEES
  Future<void> _loadEmployees() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/employees'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = _decodeEmployeeList(response.body);

        setState(() {
          _employees = data;

          if (_selectedEmployee != null) {
            final selectedId = _getEmployeeId(_selectedEmployee!);

            for (final employee in _employees) {
              if (_getEmployeeId(employee) == selectedId) {
                _selectedEmployee = employee;
                break;
              }
            }
          }

          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Không thể tải danh sách nhân viên.';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể kết nối đến máy chủ.';
      });
    }
  }

  List<Map<String, dynamic>> _decodeEmployeeList(String body) {
    try {
      final dynamic decoded = _jsonDecode(body);

      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      if (decoded is Map) {
        final possibleLists = [
          decoded['data'],
          decoded['items'],
          decoded['employees'],
        ];

        for (final value in possibleLists) {
          if (value is List) {
            return value
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
          }
        }
      }
    } catch (_) {}

    return [];
  }

  dynamic _jsonDecode(String value) {
    return const JsonDecoder().convert(value);
  }

  // SELECT EMPLOYEE

  void _selectEmployee(Map<String, dynamic> employee) {
    setState(() {
      _selectedEmployee = employee;
      _selectedImageBytes = null;
      _selectedImageName = null;
    });
  }

  // PICK IMAGE

  Future<void> _pickImage() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
    );

    if (file == null) return;

    final bytes = await file.readAsBytes();

    const maxSize = 5 * 1024 * 1024;

    if (bytes.length > maxSize) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ảnh không được vượt quá 5MB.')),
      );

      return;
    }

    if (!mounted) return;

    setState(() {
      _selectedImageBytes = bytes;
      _selectedImageName = file.name;
    });
  }

  // REGISTER FACE

  Future<void> _registerFace() async {
    if (_selectedEmployee == null) {
      _showMessage('Vui lòng chọn nhân viên.');
      return;
    }

    if (_selectedImageBytes == null) {
      _showMessage('Vui lòng chọn ảnh khuôn mặt.');
      return;
    }

    final userId = _getEmployeeId(_selectedEmployee!);

    if (userId.isEmpty) {
      _showMessage('Không xác định được mã nhân viên.');
      return;
    }

    setState(() {
      _isRegistering = true;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/api/face/register/$userId'),
      );

      request.headers['Authorization'] = 'Bearer ${widget.token}';

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          _selectedImageBytes!,
          filename: _selectedImageName ?? 'face.jpg',
        ),
      );

      final streamedResponse = await request.send();

      final response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng ký khuôn mặt thành công.')),
        );

        setState(() {
          _selectedImageBytes = null;
          _selectedImageName = null;
        });

        // Quan trọng:
        // Tải lại danh sách để cập nhật FaceId
        // và đổi trạng thái thành "Đã đăng ký".
        await _loadEmployees();
      } else {
        String message = 'Đăng ký khuôn mặt thất bại.';

        try {
          final decoded = const JsonDecoder().convert(response.body);

          if (decoded is Map) {
            final serverMessage = decoded['message'];

            if (serverMessage is String && serverMessage.isNotEmpty) {
              message = serverMessage;
            }
          }
        } catch (_) {}

        _showMessage(message);
      }
    } catch (_) {
      if (!mounted) return;

      _showMessage('Không thể kết nối đến máy chủ.');
    } finally {
      if (!mounted) return;

      setState(() {
        _isRegistering = false;
      });
    }
  }

  // HELPERS
  String _getEmployeeId(Map<String, dynamic> employee) {
    final value = employee['id'] ?? employee['_id'] ?? employee['userId'];

    return value?.toString() ?? '';
  }

  String _getEmployeeName(Map<String, dynamic> employee) {
    final value =
        employee['fullName'] ?? employee['name'] ?? employee['username'];
    return value?.toString() ?? 'Nhân viên';
  }

  String _getUsername(Map<String, dynamic> employee) {
    return employee['username']?.toString() ?? '';
  }

  String _getEmail(Map<String, dynamic> employee) {
    return employee['email']?.toString() ?? '';
  }

  bool _hasFace(Map<String, dynamic> employee) {
    final faceId = employee['faceId'];

    return faceId != null && faceId.toString().trim().isNotEmpty;
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Quản lý khuôn mặt',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _isLoading ? null : _loadEmployees,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEmployees,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildSummaryCard(),
                    const SizedBox(height: 20),
                    _buildEmployeeSection(),
                    const SizedBox(height: 20),
                    if (_selectedEmployee != null) _buildRegistrationSection(),
                  ],
                ),
              ),
            ),
    );
  }

  // HEADER

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Đăng ký khuôn mặt',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Quản lý khuôn mặt dùng để xác thực nhân viên khi chấm công.',
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // SUMMARY

  Widget _buildSummaryCard() {
    final registeredCount = _employees.where(_hasFace).length;

    final unregisteredCount = _employees.length - registeredCount;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              icon: Icons.people_alt_outlined,
              title: 'Tổng nhân viên',
              value: _employees.length.toString(),
            ),
          ),
          Container(width: 1, height: 45, color: AppColors.borderColor),
          Expanded(
            child: _buildSummaryItem(
              icon: Icons.face_retouching_natural,
              title: 'Đã đăng ký',
              value: registeredCount.toString(),
            ),
          ),
          Container(width: 1, height: 45, color: AppColors.borderColor),
          Expanded(
            child: _buildSummaryItem(
              icon: Icons.face_outlined,
              title: 'Chưa đăng ký',
              value: unregisteredCount.toString(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryBlue, size: 25),
        const SizedBox(height: 7),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // EMPLOYEE LIST

  Widget _buildEmployeeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Danh sách nhân viên',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '${_employees.length} nhân viên',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_errorMessage != null)
          _buildErrorCard()
        else if (_employees.isEmpty)
          _buildEmptyCard()
        else
          ..._employees.map((employee) => _buildEmployeeCard(employee)),
      ],
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> employee) {
    final isSelected =
        _selectedEmployee != null &&
        _getEmployeeId(_selectedEmployee!) == _getEmployeeId(employee);

    final registered = _hasFace(employee);

    final name = _getEmployeeName(employee);
    final username = _getUsername(employee);
    final email = _getEmail(employee);

    return GestureDetector(
      onTap: () => _selectEmployee(employee),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.infoBoxBackground,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'N',
                style: const TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (username.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      '@$username',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ] else if (email.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildStatusBadge(registered),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool registered) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: registered ? AppColors.successGreenBg : AppColors.amberBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            registered ? Icons.check_circle_outline : Icons.pending_outlined,
            size: 14,
            color: registered ? AppColors.successGreen : AppColors.amber,
          ),
          const SizedBox(width: 4),
          Text(
            registered ? 'Đã đăng ký' : 'Chưa đăng ký',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: registered ? AppColors.successGreen : AppColors.amber,
            ),
          ),
        ],
      ),
    );
  }

  // REGISTRATION SECTION

  Widget _buildRegistrationSection() {
    final employee = _selectedEmployee!;
    final registered = _hasFace(employee);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.face_retouching_natural,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Đăng ký khuôn mặt',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _buildStatusBadge(registered),
            ],
          ),
          const SizedBox(height: 18),
          _buildSelectedEmployeeInfo(employee),
          const SizedBox(height: 18),
          _buildImagePicker(),
          const SizedBox(height: 16),
          _buildRegisterButton(registered),
        ],
      ),
    );
  }

  Widget _buildSelectedEmployeeInfo(Map<String, dynamic> employee) {
    final name = _getEmployeeName(employee);
    final username = _getUsername(employee);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.infoBoxBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: AppColors.cardBackground,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'N',
              style: const TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (username.isNotEmpty)
                  Text(
                    '@$username',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    if (_selectedImageBytes == null) {
      return InkWell(
        onTap: _isRegistering ? null : _pickImage,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          height: 190,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.infoBoxBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.add_a_photo_outlined,
                  size: 28,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Chọn ảnh khuôn mặt',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'JPG, JPEG hoặc PNG • tối đa 5MB',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            height: 240,
            color: AppColors.background,
            child: Image.memory(_selectedImageBytes!, fit: BoxFit.contain),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(
              Icons.image_outlined,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                _selectedImageName ?? 'Ảnh khuôn mặt',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: _isRegistering ? null : _pickImage,
              child: const Text('Đổi ảnh'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRegisterButton(bool alreadyRegistered) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isRegistering ? null : _registerFace,
        icon: _isRegistering
            ? const SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(
                alreadyRegistered
                    ? Icons.refresh
                    : Icons.face_retouching_natural,
              ),
        label: Text(
          _isRegistering
              ? 'Đang xử lý...'
              : alreadyRegistered
              ? 'Đăng ký lại khuôn mặt'
              : 'Đăng ký khuôn mặt',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primaryBlue.withValues(alpha: 0.6),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // EMPTY / ERROR

  Widget _buildEmptyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: const Column(
        children: [
          Icon(Icons.people_outline, size: 45, color: AppColors.textSecondary),
          SizedBox(height: 12),
          Text(
            'Chưa có nhân viên',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 40, color: AppColors.amber),
          const SizedBox(height: 10),
          Text(
            _errorMessage ?? 'Có lỗi xảy ra.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _loadEmployees,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}
