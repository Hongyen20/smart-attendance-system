import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_config.dart';

class FaceManagementScreen extends StatefulWidget {
  final String token;

  const FaceManagementScreen({
    super.key,
    required this.token,
  });

  @override
  State<FaceManagementScreen> createState() =>
      _FaceManagementScreenState();
}

class _FaceManagementScreenState
    extends State<FaceManagementScreen> {
  bool _loading = true;
  bool _registering = false;

  List<Map<String, dynamic>> _employees = [];

  Map<String, dynamic>? _selectedEmployee;

  Uint8List? _imageBytes;
  String? _imageName;

  String? _message;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/employees',
        ),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Không thể tải danh sách nhân viên '
          '(${response.statusCode})',
        );
      }

      final decoded = jsonDecode(response.body);

      List<dynamic> data;

      if (decoded is List) {
        data = decoded;
      } else if (decoded is Map &&
          decoded['data'] is List) {
        data = decoded['data'];
      } else {
        throw Exception(
          'Dữ liệu nhân viên không hợp lệ.',
        );
      }

      final employees = data
          .whereType<Map>()
          .map(
            (item) => Map<String, dynamic>.from(item),
          )
          .toList();

      if (!mounted) return;

      setState(() {
        _employees = employees;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _message = 'Không thể tải nhân viên: $e';
        _success = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      // file_picker 13.x:
      // pickFile() dùng để chọn một file duy nhất.
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: [
          'jpg',
          'jpeg',
          'png',
        ],
      );

      if (file == null) {
        return;
      }

      // file_picker 13.x không còn withData.
      // Đọc dữ liệu bằng readAsBytes().
      final bytes = await file.readAsBytes();

      if (bytes.isEmpty) {
        _showMessage(
          'Ảnh không hợp lệ.',
          false,
        );
        return;
      }

      const maxFileSize = 5 * 1024 * 1024;

      if (bytes.length > maxFileSize) {
        _showMessage(
          'Ảnh không được vượt quá 5MB.',
          false,
        );
        return;
      }

      if (!mounted) return;

      setState(() {
        _imageBytes = bytes;
        _imageName = file.name;
        _message = null;
        _success = false;
      });
    } catch (e) {
      _showMessage(
        'Không thể chọn ảnh: $e',
        false,
      );
    }
  }

  Future<void> _registerFace() async {
    if (_selectedEmployee == null) {
      _showMessage(
        'Vui lòng chọn nhân viên.',
        false,
      );
      return;
    }

    if (_imageBytes == null) {
      _showMessage(
        'Vui lòng chọn ảnh khuôn mặt.',
        false,
      );
      return;
    }

    final userId =
        _selectedEmployee!['id']?.toString();

    if (userId == null || userId.isEmpty) {
      _showMessage(
        'Không tìm thấy ID nhân viên.',
        false,
      );
      return;
    }

    if (_hasFace(_selectedEmployee!)) {
      _showMessage(
        'Nhân viên này đã đăng ký khuôn mặt.',
        false,
      );
      return;
    }

    if (!mounted) return;

    setState(() {
      _registering = true;
      _message = null;
      _success = false;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
          '${ApiConfig.baseUrl}'
          '/api/face/register/$userId',
        ),
      );

      request.headers['Authorization'] =
          'Bearer ${widget.token}';

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          _imageBytes!,
          filename: _imageName ?? 'face.jpg',
        ),
      );

      final streamedResponse =
          await request.send();

      final response =
          await http.Response.fromStream(
        streamedResponse,
      );

      dynamic body;

      try {
        if (response.body.isNotEmpty) {
          body = jsonDecode(response.body);
        }
      } catch (_) {
        body = null;
      }

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        if (!mounted) return;

        setState(() {
          _registering = false;
          _message =
              body is Map
                  ? body['message']?.toString() ??
                      'Đăng ký khuôn mặt thành công.'
                  : 'Đăng ký khuôn mặt thành công.';
          _success = true;
        });

        final selectedId = userId;

        await _loadEmployees();

        if (!mounted) return;

        final updatedEmployees =
            _employees.where(
          (employee) =>
              employee['id']?.toString() ==
              selectedId,
        );

        if (updatedEmployees.isNotEmpty) {
          setState(() {
            _selectedEmployee =
                updatedEmployees.first;
            _imageBytes = null;
            _imageName = null;
          });
        }

        return;
      }

      String errorMessage;

      if (body is Map &&
          body['message'] != null) {
        errorMessage =
            body['message'].toString();
      } else {
        errorMessage =
            'Đăng ký thất bại '
            '(${response.statusCode}).';
      }

      if (!mounted) return;

      setState(() {
        _registering = false;
        _message = errorMessage;
        _success = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _registering = false;
        _message =
            'Không thể kết nối đến server: $e';
        _success = false;
      });
    }
  }

  void _showMessage(
    String message,
    bool success,
  ) {
    if (!mounted) return;

    setState(() {
      _message = message;
      _success = success;
    });
  }

  bool _hasFace(
    Map<String, dynamic> employee,
  ) {
    final faceId =
        employee['faceId']?.toString();

    return faceId != null &&
        faceId.isNotEmpty;
  }

  String _getName(
    Map<String, dynamic> employee,
  ) {
    final fullName =
        employee['fullName']?.toString();

    if (fullName != null &&
        fullName.isNotEmpty) {
      return fullName;
    }

    final username =
        employee['username']?.toString();

    if (username != null &&
        username.isNotEmpty) {
      return username;
    }

    return 'Nhân viên';
  }

  String _getUsername(
    Map<String, dynamic> employee,
  ) {
    return employee['username']?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor:
            const Color(0xFF172033),
        elevation: 0,
        title: const Text(
          'Quản lý khuôn mặt',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 850,
                ),
                child:
                    SingleChildScrollView(
                  padding:
                      const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildMainCard(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color:
                const Color(0xFFEFF3FF),
            borderRadius:
                BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.face_retouching_natural,
            color:
                Color(0xFF3157D5),
            size: 27,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Đăng ký khuôn mặt',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Thiết lập khuôn mặt để sử dụng xác thực khi chấm công.',
                style: TextStyle(
                  color:
                      Color(0xFF737D91),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainCard() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color:
              const Color(0xFFE4E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            '1. Chọn nhân viên',
            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _buildEmployeeDropdown(),

          const SizedBox(height: 28),

          const Text(
            '2. Chọn ảnh khuôn mặt',
            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),

          _buildImageArea(),

          const SizedBox(height: 22),

          _buildMessage(),

          const SizedBox(height: 16),

          _buildRegisterButton(),
        ],
      ),
    );
  }

  Widget _buildEmployeeDropdown() {
    return DropdownButtonFormField<
        Map<String, dynamic>>(
      initialValue: _selectedEmployee,
      isExpanded: true,
      decoration:
          const InputDecoration(
        prefixIcon:
            Icon(Icons.person_outline),
        hintText:
            'Chọn nhân viên',
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.all(
            Radius.circular(12),
          ),
        ),
      ),
      items: _employees.map(
        (employee) {
          final registered =
              _hasFace(employee);

          return DropdownMenuItem<
              Map<String, dynamic>>(
            value: employee,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_getName(employee)}'
                    ' (${_getUsername(employee)})',
                    overflow:
                        TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  registered
                      ? 'Đã đăng ký'
                      : 'Chưa đăng ký',
                  style: TextStyle(
                    fontSize: 11,
                    color: registered
                        ? const Color(
                            0xFF198754,
                          )
                        : const Color(
                            0xFFB66A00,
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ).toList(),
      onChanged: _registering
          ? null
          : (employee) {
              setState(() {
                _selectedEmployee =
                    employee;
                _imageBytes = null;
                _imageName = null;
                _message = null;
                _success = false;
              });
            },
    );
  }

  Widget _buildImageArea() {
    if (_imageBytes == null) {
      return InkWell(
        onTap:
            _registering ? null : _pickImage,
        borderRadius:
            BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          height: 280,
          decoration: BoxDecoration(
            color:
                const Color(0xFFF8F9FC),
            borderRadius:
                BorderRadius.circular(16),
            border: Border.all(
              color:
                  const Color(0xFFDDE2EC),
              width: 1.5,
            ),
          ),
          child: const Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                Icons
                    .add_a_photo_outlined,
                size: 52,
                color:
                    Color(0xFF7B8496),
              ),
              SizedBox(height: 14),
              Text(
                'Chọn ảnh khuôn mặt',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'JPG, JPEG hoặc PNG • tối đa 5MB',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      Color(0xFF8B94A5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius:
              BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            height: 280,
            color:
                const Color(0xFFF0F2F6),
            child: Image.memory(
              _imageBytes!,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              Icons.image_outlined,
              size: 18,
              color:
                  Color(0xFF7B8496),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _imageName ?? '',
                overflow:
                    TextOverflow.ellipsis,
                style:
                    const TextStyle(
                  fontSize: 12,
                  color:
                      Color(0xFF737D91),
                ),
              ),
            ),
            TextButton(
              onPressed:
                  _registering
                      ? null
                      : _pickImage,
              child:
                  const Text('Đổi ảnh'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMessage() {
    if (_message == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _success
            ? const Color(0xFFEAF8EF)
            : const Color(0xFFFFF0F0),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            _success
                ? Icons.check_circle_outline
                : Icons.error_outline,
            color: _success
                ? const Color(0xFF198754)
                : const Color(0xFFC62828),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              _message!,
              style: TextStyle(
                color: _success
                    ? const Color(
                        0xFF198754,
                      )
                    : const Color(
                        0xFFC62828,
                      ),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    final registered =
        _selectedEmployee != null &&
            _hasFace(
              _selectedEmployee!,
            );

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed:
            (_registering || registered)
                ? null
                : _registerFace,
        icon: _registering
            ? const SizedBox(
                width: 18,
                height: 18,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.face),
        label: Text(
          _registering
              ? 'Đang đăng ký...'
              : registered
                  ? 'Nhân viên đã đăng ký'
                  : 'Đăng ký khuôn mặt',
        ),
        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              const Color(0xFF3157D5),
          foregroundColor:
              Colors.white,
          disabledBackgroundColor:
              const Color(0xFFDDE1E8),
          disabledForegroundColor:
              const Color(0xFF747C8D),
          elevation: 0,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
