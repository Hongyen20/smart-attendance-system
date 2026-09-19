import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/api_config.dart';
import '../services/auth_state.dart';


import 'history_screen.dart';
import 'statistics_screen.dart';
import 'leave_request_screen.dart';
import 'profile_screen.dart';


class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  State<EmployeeHomeScreen> createState() =>
      _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState
    extends State<EmployeeHomeScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  bool _isProcessing = false;

  bool _checkedIn = false;
  bool _checkedOut = false;

  String? _checkInTime;
  double? _workingHours;

  @override
  void initState() {
    super.initState();
    _loadTodayStatus();
  }

  // BUILD API URL

  Uri _buildApiUri(String path) {
    if (ApiConfig.baseUrl.isEmpty) {
      return Uri.base.resolve(path);
    }

    return Uri.parse(
      '${ApiConfig.baseUrl}$path',
    );
  }

  // LOAD TODAY STATUS

  Future<void> _loadTodayStatus() async {
    try {
      final result = await ApiService.get(
        '/api/attendance/today',
      );

      if (!mounted || !result.success) {
        return;
      }

      final data = result.data;

      if (data == null) {
        return;
      }

      if (data is Map<String, dynamic>) {
        setState(() {
          _checkedIn =
              data['checkedIn'] == true;

          _checkedOut =
              data['checkedOut'] == true;

          _checkInTime =
              data['checkInTime']?.toString();

          final hours =
              data['workingHours'];

          if (hours is num) {
            _workingHours =
                hours.toDouble();
          } else {
            _workingHours = null;
          }
        });
      }
    } catch (e) {
      debugPrint(
        'Load attendance status error: $e',
      );
    }
  }

  // GET PUBLIC IP

  Future<String?> _getPublicIp() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.ipify.org?format=json',
        ),
      );

      if (response.statusCode != 200) {
        return null;
      }

      final decoded =
          jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded['ip']?.toString();
      }

      return null;
    } catch (e) {
      debugPrint(
        'Get public IP error: $e',
      );

      return null;
    }
  }

  // GET GPS

  Future<Position?> _getCurrentPosition() async {
    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _showMessage(
          'Vui lòng bật dịch vụ vị trí.',
          isError: true,
        );

        return null;
      }

      var permission =
          await Geolocator.checkPermission();

      if (permission ==
          LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission ==
              LocationPermission.denied ||
          permission ==
              LocationPermission.deniedForever) {
        _showMessage(
          'Quyền vị trí chưa được cấp. '
          'Vui lòng cho phép trình duyệt sử dụng vị trí.',
          isError: true,
        );

        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      debugPrint(
        'Get GPS error: $e',
      );

      _showMessage(
        'Không thể lấy vị trí hiện tại.',
        isError: true,
      );

      return null;
    }
  }

  // OPEN CAMERA

  Future<XFile?> _captureFace() async {
    try {
      return await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1280,
        maxHeight: 1280,
      );
    } catch (e) {
      debugPrint(
        'Camera error: $e',
      );

      _showMessage(
        'Không thể mở camera. '
        'Vui lòng kiểm tra quyền camera của trình duyệt.',
        isError: true,
      );

      return null;
    }
  }

  // CHECK-IN
  // IP -> GPS -> FACE -> ATTENDANCE

  Future<void> _performCheckIn(
    String publicIp,
    Position position,
  ) async {
    _showMessage(
      'Bước 3/3: Vui lòng chụp khuôn mặt...',
    );

    final faceImage =
        await _captureFace();

    if (faceImage == null) {
      return;
    }

    final bytes =
        await faceImage.readAsBytes();

    if (bytes.isEmpty) {
      _showMessage(
        'Không đọc được ảnh khuôn mặt.',
        isError: true,
      );

      return;
    }

    _showMessage(
      'Đang xác thực khuôn mặt...',
    );

    try {
      final request =
          http.MultipartRequest(
        'POST',
        _buildApiUri(
          '/api/attendance/check-in',
        ),
      );

      // JWT

      final token =
          AuthState.instance.token;

      if (token != null &&
          token.isNotEmpty) {
        request.headers['Authorization'] =
            'Bearer $token';
      }

      // FORM DATA

      request.fields['publicIp'] =
          publicIp;

      request.fields['lat'] =
          position.latitude.toString();

      request.fields['lng'] =
          position.longitude.toString();

      request.fields['deviceId'] = '';

      // FACE IMAGE

      request.files.add(
        http.MultipartFile.fromBytes(
          'faceImage',
          bytes,
          filename: 'face.jpg',
        ),
      );

      // SEND

      final response =
          await request.send();

      final responseBody =
          await response.stream.bytesToString();

      Map<String, dynamic>? data;

      try {
        final decoded =
            jsonDecode(responseBody);

        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } catch (_) {
        data = null;
      }

      final message =
          data?['message']?.toString() ??
              'Check-in thất bại.';

      if (!mounted) {
        return;
      }

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        setState(() {
          _checkedIn = true;
          _checkedOut = false;

          _checkInTime =
              data?['checkInTime']
                  ?.toString();

          _workingHours = null;
        });

        _showMessage(
          message,
          isError: false,
        );

        await _loadTodayStatus();
      } else {
        _showMessage(
          message,
          isError: true,
        );
      }
    } catch (e) {
      debugPrint(
        'Check-in error: $e',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Không thể kết nối đến máy chủ.',
        isError: true,
      );
    }
  }

  // CHECK-OUT
  // IP -> GPS -> ATTENDANCE

  Future<void> _performCheckOut(
    String publicIp,
    Position position,
  ) async {
    try {
      final result =
          await ApiService.post(
        '/api/attendance/check-out',
        {
          'publicIp': publicIp,
          'lat': position.latitude,
          'lng': position.longitude,
          'deviceId': '',
        },
      );

      if (!mounted) {
        return;
      }

      if (!result.success) {
        _showMessage(
          result.errorMessage ??
              'Check-out thất bại.',
          isError: true,
        );

        return;
      }

      final data = result.data;

      String message =
          'Check-out thành công.';

      double? hours;

      if (data is Map<String, dynamic>) {
        message =
            data['message']?.toString() ??
                message;

        final value =
            data['workingHours'];

        if (value is num) {
          hours =
              value.toDouble();
        }
      }

      setState(() {
        _checkedOut = true;

        if (hours != null) {
          _workingHours = hours;
        }
      });

      _showMessage(
        message,
        isError: false,
      );

      await _loadTodayStatus();
    } catch (e) {
      debugPrint(
        'Check-out error: $e',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Không thể kết nối đến máy chủ.',
        isError: true,
      );
    }
  }

  // MAIN CHECK BUTTON

  Future<void> _handleCheckButtonTap() async {
    if (_isProcessing) {
      return;
    }

    if (_checkedOut) {
      _showMessage(
        'Bạn đã hoàn thành chấm công hôm nay.',
      );

      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // ========================================================
      // STEP 1: IP
      // ========================================================

      _showMessage(
        'Bước 1/3: Đang kiểm tra IP...',
      );

      final publicIp =
          await _getPublicIp();

      if (publicIp == null ||
          publicIp.trim().isEmpty) {
        _showMessage(
          'Không thể lấy địa chỉ IP công cộng.',
          isError: true,
        );

        return;
      }

      // ========================================================
      // STEP 2: GPS
      // ========================================================

      _showMessage(
        'Bước 2/3: Đang xác định vị trí...',
      );

      final position =
          await _getCurrentPosition();

      if (position == null) {
        return;
      }

      // ========================================================
      // CHECK-IN
      // ========================================================

      if (!_checkedIn) {
        await _performCheckIn(
          publicIp,
          position,
        );

        return;
      }

      // ========================================================
      // CHECK-OUT
      // ========================================================

      await _performCheckOut(
        publicIp,
        position,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // MESSAGE

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
              SnackBarBehavior.floating,
          duration:
              const Duration(seconds: 3),
        ),
      );
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.background,

      appBar: AppBar(
        backgroundColor:
            AppColors.background,
        elevation: 0,
        title: const Text(
          'Chấm công',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadTodayStatus,
          child: ListView(
            padding:
                const EdgeInsets.all(20),
            children: [
              _buildAttendanceCard(),
              const SizedBox(height: 20),
              _buildStatusCard(),
            ],
          ),
        ),
      ),
    );
  }

  // ATTENDANCE CARD

  Widget _buildAttendanceCard() {
    String status;

    if (_checkedOut) {
      status =
          'Bạn đã hoàn thành chấm công hôm nay.';
    } else if (_checkedIn) {
      status =
          'Bạn đã check-in. Hãy check-out khi kết thúc ca.';
    } else {
      status =
          'Bạn chưa check-in hôm nay.';
    }

    return Container(
      padding:
          const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            blurRadius: 15,
            offset:
                const Offset(0, 6),
            color:
                Colors.black.withOpacity(
              0.06,
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Chấm công hôm nay',
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            status,
            textAlign:
                TextAlign.center,
            style: TextStyle(
              color:
                  Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 28),

          SizedBox(
            width: 180,
            height: 180,
            child: ElevatedButton(
              onPressed:
                  _isProcessing ||
                          _checkedOut
                      ? null
                      : _handleCheckButtonTap,
              style:
                  ElevatedButton.styleFrom(
                shape:
                    const CircleBorder(),
                backgroundColor:
                    AppColors.primaryBlue,
                disabledBackgroundColor:
                    Colors.grey.shade300,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 36,
                      height: 36,
                      child:
                          CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    )
                  : Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          _checkedIn
                              ? Icons.logout
                              : Icons.login,
                          size: 42,
                          color:
                              Colors.white,
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Text(
                          _checkedIn
                              ? 'Check-out'
                              : 'Check-in',
                          style:
                              const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 24),

          if (!_checkedIn)
            const Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.security,
                  size: 18,
                  color: Colors.grey,
                ),
                SizedBox(width: 6),
                Text(
                  'IP • GPS • Khuôn mặt',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),

          if (_checkedIn &&
              !_checkedOut)
            const Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: Colors.grey,
                ),
                SizedBox(width: 6),
                Text(
                  'Check-out: IP • GPS',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // STATUS CARD

  Widget _buildStatusCard() {
    return Container(
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset:
                const Offset(0, 5),
            color:
                Colors.black.withOpacity(
              0.05,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Trạng thái hôm nay',
            style: TextStyle(
              fontSize: 17,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          _buildStatusRow(
            Icons.login,
            'Check-in',
            _checkedIn
                ? (_checkInTime == null
                    ? 'Đã check-in'
                    : _formatDateTime(
                        _checkInTime!,
                      ))
                : 'Chưa check-in',
            _checkedIn,
          ),

          const Divider(
            height: 24,
          ),

          _buildStatusRow(
            Icons.logout,
            'Check-out',
            _checkedOut
                ? 'Đã check-out'
                : 'Chưa check-out',
            _checkedOut,
          ),

          if (_workingHours != null) ...[
            const Divider(
              height: 24,
            ),
            _buildStatusRow(
              Icons.access_time,
              'Thời gian làm việc',
              '${_workingHours!.toStringAsFixed(2)} giờ',
              true,
            ),
          ],
        ],
      ),
    );
  }

  // STATUS ROW

  Widget _buildStatusRow(
    IconData icon,
    String title,
    String value,
    bool completed,
  ) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: completed
                ? AppColors.primaryBlue
                    .withOpacity(0.1)
                : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: completed
                ? AppColors.primaryBlue
                : Colors.grey,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color:
                      Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        Icon(
          completed
              ? Icons.check_circle
              : Icons
                  .radio_button_unchecked,
          color: completed
              ? AppColors.primaryBlue
              : Colors.grey.shade400,
          size: 22,
        ),
      ],
    );
  }

  // FORMAT DATETIME

  String _formatDateTime(
    String value,
  ) {
    try {
      final date =
          DateTime.parse(value)
              .toLocal();

      final hour =
          date.hour
              .toString()
              .padLeft(2, '0');

      final minute =
          date.minute
              .toString()
              .padLeft(2, '0');

      final second =
          date.second
              .toString()
              .padLeft(2, '0');

      return '$hour:$minute:$second';
    } catch (_) {
      return value;
    }
  }
}
