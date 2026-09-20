import 'dart:async';
import 'dart:convert';

import 'package:camera/camera.dart' show XFile;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;

import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/api_config.dart';
import '../services/auth_state.dart';

import 'face_capture_screen.dart';
import 'profile_screen.dart';
import 'history_screen.dart';
import 'leave_request_screen.dart';
import 'change_password_screen.dart';
import 'shift_change_request_screen.dart';
import 'business_trip_request_screen.dart';

enum _CheckState { loading, notCheckedIn, checkedIn, checkedOut }

class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  int _selectedNavIndex = 0;

  _CheckState _checkState = _CheckState.loading;

  String? _checkInTimeLabel;
  String? _workingHoursLabel;

  bool _isProcessing = false;

  // null  = chưa lấy được trạng thái
  // false = chưa đăng ký khuôn mặt
  // true  = đã đăng ký khuôn mặt
  bool? _hasFace;

  bool _isLoadingFaceStatus = true;

  Timer? _clockTimer;

  static const List<String> _weekdays = [
    'Chủ Nhật',
    'Thứ Hai',
    'Thứ Ba',
    'Thứ Tư',
    'Thứ Năm',
    'Thứ Sáu',
    'Thứ Bảy',
  ];

  // TIME

  String get _formattedNow {
    final now = DateTime.now();

    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');

    return '$hh:$mm';
  }

  String get _formattedDate {
    final now = DateTime.now();

    return '${_weekdays[now.weekday % 7]}, '
        '${now.day} Thg ${now.month}';
  }

  // LIFECYCLE

  @override
  void initState() {
    super.initState();

    _initializeScreen();

    // Cập nhật giờ trên giao diện mỗi phút.
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    await Future.wait([_loadTodayStatus(), _loadFaceStatus()]);
  }

  // LOAD FACE STATUS

  Future<void> _loadFaceStatus() async {
    if (!mounted) return;

    setState(() {
      _isLoadingFaceStatus = true;
    });

    try {
      final result = await ApiService.get(
        '/api/employee-self/face-status',
        bearerToken: AuthState.instance.token,
      );

      if (!mounted) return;

      if (!result.success || result.data == null) {
        setState(() {
          _hasFace = null;
        });

        debugPrint('Load face status failed: ${result.errorMessage}');

        return;
      }

      final data = result.data;

      if (data is! Map<String, dynamic>) {
        setState(() {
          _hasFace = null;
        });

        debugPrint('Invalid face status response: $data');

        return;
      }

      setState(() {
        _hasFace = data['hasFace'] == true;
      });
    } catch (e) {
      debugPrint('Load face status error: $e');

      if (!mounted) return;

      setState(() {
        _hasFace = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFaceStatus = false;
        });
      }
    }
  }

  // LOAD ATTENDANCE TODAY

  Future<void> _loadTodayStatus() async {
    try {
      final result = await ApiService.get(
        '/api/attendance/today',
        bearerToken: AuthState.instance.token,
      );

      if (!mounted) return;

      if (!result.success) {
        setState(() {
          _checkState = _CheckState.notCheckedIn;
          _checkInTimeLabel = null;
          _workingHoursLabel = null;
        });

        return;
      }

      final data = result.data;

      if (data == null) {
        setState(() {
          _checkState = _CheckState.notCheckedIn;
          _checkInTimeLabel = null;
          _workingHoursLabel = null;
        });

        return;
      }

      final checkedIn = data['checkedIn'] == true;
      final checkedOut = data['checkedOut'] == true;

      setState(() {
        if (!checkedIn) {
          _checkState = _CheckState.notCheckedIn;

          _checkInTimeLabel = null;
          _workingHoursLabel = null;
        } else if (checkedIn && !checkedOut) {
          _checkState = _CheckState.checkedIn;

          _checkInTimeLabel = _formatTimeFromIso(
            data['checkInTime'] as String?,
          );

          // Khi chưa check-out, backend có thể chưa trả workingHours.
          _workingHoursLabel = _formatCurrentWorkingTime(
            data['checkInTime'] as String?,
          );
        } else {
          _checkState = _CheckState.checkedOut;

          _checkInTimeLabel = _formatTimeFromIso(
            data['checkInTime'] as String?,
          );

          final hours = (data['workingHours'] as num?)?.toDouble() ?? 0;

          _workingHoursLabel = _formatWorkingHours(hours);
        }
      });
    } catch (e) {
      debugPrint('Load today attendance error: $e');

      if (!mounted) return;

      setState(() {
        _checkState = _CheckState.notCheckedIn;
        _checkInTimeLabel = null;
        _workingHoursLabel = null;
      });
    }
  }

  String? _formatTimeFromIso(String? iso) {
    if (iso == null) return null;

    final dt = DateTime.tryParse(iso);

    if (dt == null) return null;

    final local = dt.toLocal();

    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  String _formatWorkingHours(double hours) {
    final totalMinutes = (hours * 60).round();

    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;

    if (h == 0) {
      return '$m phút';
    }

    if (m == 0) {
      return '$h giờ';
    }

    return '$h giờ $m phút';
  }

  String? _formatCurrentWorkingTime(String? iso) {
    if (iso == null) return null;

    final checkIn = DateTime.tryParse(iso);

    if (checkIn == null) return null;

    final now = DateTime.now();

    final localCheckIn = checkIn.toLocal();

    final difference = now.difference(localCheckIn);

    if (difference.isNegative) {
      return 'Đang làm';
    }

    final totalMinutes = difference.inMinutes;

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours == 0) {
      return '$minutes phút';
    }

    if (minutes == 0) {
      return '$hours giờ';
    }

    return '$hours giờ $minutes phút';
  }

  // PUBLIC IP

  Future<String?> _getPublicIp() async {
    try {
      final response = await http
          .get(Uri.parse('https://api.ipify.org?format=json'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        _showSnack('Không thể lấy địa chỉ IP công cộng.');

        return null;
      }

      final data = jsonDecode(response.body);

      if (data is! Map<String, dynamic>) {
        _showSnack('Dữ liệu IP không hợp lệ.');

        return null;
      }

      final ip = data['ip']?.toString().trim();

      if (ip == null || ip.isEmpty) {
        _showSnack('Không nhận được địa chỉ IP công cộng.');

        return null;
      }

      if (!_isValidIPv4(ip)) {
        _showSnack('Địa chỉ IPv4 nhận được không hợp lệ.');

        return null;
      }

      return ip;
    } catch (e) {
      debugPrint('Get public IP error: $e');

      _showSnack(
        'Không thể lấy IP công cộng. '
        'Vui lòng kiểm tra kết nối Internet.',
      );

      return null;
    }
  }

  bool _isValidIPv4(String ip) {
    final parts = ip.split('.');

    if (parts.length != 4) {
      return false;
    }

    for (final part in parts) {
      final value = int.tryParse(part);

      if (value == null || value < 0 || value > 255) {
        return false;
      }
    }

    return true;
  }

  // GPS

  Future<Position?> _getCurrentPosition() async {
    try {
      // Native app: kiểm tra Location Service.
      if (!kIsWeb) {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();

        if (!serviceEnabled) {
          _showSnack(
            'GPS đang tắt. '
            'Vui lòng bật định vị trên điện thoại.',
          );

          return null;
        }
      }

      // Kiểm tra quyền.
      var permission = await Geolocator.checkPermission().timeout(
        const Duration(seconds: 10),
      );

      if (permission == LocationPermission.denied) {
        _showSnack('Đang yêu cầu quyền truy cập vị trí...');

        permission = await Geolocator.requestPermission().timeout(
          const Duration(seconds: 30),
        );
      }

      if (permission == LocationPermission.denied) {
        _showSnack('Bạn chưa cấp quyền vị trí cho trình duyệt.');

        return null;
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnack(
          'Quyền vị trí đã bị từ chối vĩnh viễn. '
          'Hãy vào cài đặt trình duyệt và cho phép Location.',
        );

        return null;
      }

      _showSnack('Đang lấy vị trí GPS...');

      Position? position;

      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 10),
          ),
        ).timeout(const Duration(seconds: 15));
      } on TimeoutException {
        debugPrint('GPS: low accuracy timeout, retry high accuracy...');

        _showSnack('Đang thử lại với độ chính xác cao...');

        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 20),
          ),
        ).timeout(const Duration(seconds: 25));
      }

      if (position.latitude == 0 && position.longitude == 0) {
        _showSnack('Không nhận được tọa độ GPS hợp lệ.');

        return null;
      }

      _showSnack('Đã lấy vị trí GPS thành công.');

      return position;
    } on TimeoutException {
      debugPrint('GPS: timeout');

      _showSnack(
        'Không lấy được vị trí GPS. '
        'Hãy mở trang bằng Chrome/Safari '
        '(không dùng trình duyệt trong Zalo/Messenger), '
        'cấp quyền Vị trí cho trình duyệt rồi thử lại.',
      );

      return null;
    } catch (e) {
      debugPrint('GPS error: $e');

      _showSnack('Lỗi GPS: $e');

      return null;
    }
  }

  // FACE CAMERA

  Future<XFile?> _captureFaceImage() async {
    if (!mounted) {
      return null;
    }

    try {
      final image = await Navigator.of(context).push<XFile>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const FaceCaptureScreen(),
        ),
      );

      if (image == null) {
        _showSnack('Bạn chưa chụp ảnh khuôn mặt.');

        return null;
      }

      return image;
    } catch (e) {
      debugPrint('Face camera error: $e');

      _showSnack(
        'Không thể mở camera. '
        'Vui lòng kiểm tra quyền camera của trình duyệt.',
      );

      return null;
    }
  }

  // API URI

  Uri _buildApiUri(String path) {
    if (ApiConfig.baseUrl.isEmpty) {
      return Uri.base.resolve(path);
    }

    return Uri.parse('${ApiConfig.baseUrl}$path');
  }

  // CHECK-IN

  Future<void> _performCheckIn({
    required String publicIp,
    required Position position,
  }) async {
    // Mở camera.
    final faceImage = await _captureFaceImage();

    if (!mounted) return;

    if (faceImage == null) {
      return;
    }

    // Đọc ảnh.
    final imageBytes = await faceImage.readAsBytes();

    if (imageBytes.isEmpty) {
      _showSnack('Không đọc được ảnh khuôn mặt.');

      return;
    }

    _showSnack('Đang xác thực khuôn mặt...');

    try {
      final request = http.MultipartRequest(
        'POST',
        _buildApiUri('/api/attendance/check-in'),
      );

      // JWT.
      final token = AuthState.instance.token;

      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Form fields.
      request.fields['lat'] = position.latitude.toString();

      request.fields['lng'] = position.longitude.toString();

      request.fields['publicIp'] = publicIp;

      request.fields['deviceId'] = 'web';

      // Face image.
      request.files.add(
        http.MultipartFile.fromBytes(
          'faceImage',
          imageBytes,
          filename: 'face.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      final response = await request.send();

      final responseBody = await response.stream.bytesToString();

      debugPrint('Check-in status: ${response.statusCode}');

      debugPrint('Check-in body: $responseBody');

      Map<String, dynamic>? data;

      try {
        final decoded = jsonDecode(responseBody);

        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } catch (_) {
        data = null;
      }

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _showSnack(data?['message']?.toString() ?? 'Check-in thành công!');

        await _loadTodayStatus();

        return;
      }

      final errorMessage =
          data?['message']?.toString() ??
          data?['title']?.toString() ??
          'Xác thực khuôn mặt thất bại.';

      _showSnack(errorMessage);
    } catch (e) {
      debugPrint('Check-in multipart error: $e');

      if (!mounted) return;

      _showSnack('Không thể kết nối đến máy chủ.');
    }
  }

  // CHECK-OUT

  Future<void> _performCheckOut({
    required String publicIp,
    required Position position,
  }) async {
    try {
      final body = {
        'lat': position.latitude,
        'lng': position.longitude,
        'publicIp': publicIp,
        'deviceId': '',
      };

      final result = await ApiService.post(
        '/api/attendance/check-out',
        body,
        bearerToken: AuthState.instance.token,
      );

      if (!mounted) return;

      if (result.success) {
        _showSnack('Check-out thành công!');

        await _loadTodayStatus();
      } else {
        _showSnack(result.errorMessage ?? 'Xác thực check-out thất bại.');
      }
    } catch (e) {
      debugPrint('Check-out error: $e');

      if (!mounted) return;

      _showSnack('Có lỗi xảy ra khi thực hiện check-out.');
    }
  }

  // CHECK-IN / CHECK-OUT HANDLER

  Future<void> _handleCheckButtonTap() async {
    if (_checkState == _CheckState.checkedOut ||
        _checkState == _CheckState.loading ||
        _isProcessing ||
        _isLoadingFaceStatus) {
      return;
    }

    final isCheckIn = _checkState == _CheckState.notCheckedIn;

    // Check-in bắt buộc có khuôn mặt.
    if (isCheckIn) {
      if (_hasFace == null) {
        _showSnack(
          'Không thể kiểm tra trạng thái '
          'khuôn mặt. Vui lòng thử lại.',
        );

        return;
      }

      if (_hasFace == false) {
        _showSnack(
          'Bạn chưa đăng ký khuôn mặt. '
          'Vui lòng đăng ký khuôn mặt '
          'trước khi check-in.',
        );

        return;
      }
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // STEP 1: PUBLIC IP
      _showSnack(
        isCheckIn
            ? 'Bước 1/3: Đang kiểm tra địa chỉ IP...'
            : 'Bước 1/2: Đang kiểm tra địa chỉ IP...',
      );

      final publicIp = await _getPublicIp();

      if (!mounted) return;

      if (publicIp == null) {
        return;
      }

      // STEP 2: GPS
      _showSnack(
        isCheckIn
            ? 'Bước 2/3: Đang xác định vị trí...'
            : 'Bước 2/2: Đang xác định vị trí...',
      );

      final position = await _getCurrentPosition();

      if (!mounted) return;

      if (position == null) {
        return;
      }

      // CHECK-IN
      if (isCheckIn) {
        _showSnack('Bước 3/3: Đang mở camera...');

        await _performCheckIn(publicIp: publicIp, position: position);

        return;
      }

      // CHECK-OUT
      await _performCheckOut(publicIp: publicIp, position: position);
    } catch (e) {
      debugPrint('Attendance error: $e');

      if (!mounted) return;

      _showSnack('Có lỗi xảy ra khi thực hiện chấm công.');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // SNACKBAR

  void _showSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([_loadTodayStatus(), _loadFaceStatus()]);
                },

                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),

                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      _buildGreetingHeader(),

                      const SizedBox(height: 24),

                      _buildAttendanceCard(),

                      const SizedBox(height: 26),

                      _buildUtilitiesSection(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // LOGO HEADER

  Widget _buildLogoHeader() {
    return SizedBox(
      width: 150,
      height: 60,

      child: Image.asset(
        'assets/images/logo.png',

        fit: BoxFit.contain,

        alignment: Alignment.centerLeft,
      ),
    );
  }

  // GREETING HEADER

  Widget _buildGreetingHeader() {
    final userName = AuthState.instance.fullName ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,

      children: [
        _buildLogoHeader(),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                'Chào ${userName.isEmpty ? 'bạn' : userName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,

                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                'Chúc bạn một ngày làm việc hiệu quả.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,

                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        Column(
          crossAxisAlignment: CrossAxisAlignment.end,

          children: [
            Text(
              _formattedNow,

              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),

            const SizedBox(height: 2),

            Text(
              _formattedDate,

              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ATTENDANCE CARD

  Widget _buildAttendanceCard() {
    final isLoading = _checkState == _CheckState.loading;

    final isCheckedIn = _checkState == _CheckState.checkedIn;

    final isCheckedOut = _checkState == _CheckState.checkedOut;

    String statusText;
    Color statusColor;
    Color statusBackground;
    IconData statusIcon;

    if (isLoading || _isLoadingFaceStatus) {
      statusText = 'Đang tải trạng thái...';
      statusColor = AppColors.textSecondary;
      statusBackground = AppColors.background;
      statusIcon = Icons.hourglass_empty;
    } else if (isCheckedOut) {
      statusText = 'Đã hoàn thành hôm nay';
      statusColor = AppColors.successGreen;
      statusBackground = AppColors.successGreen.withValues(alpha: 0.10);
      statusIcon = Icons.check_circle_outline;
    } else if (isCheckedIn) {
      statusText = 'Đang làm việc';
      statusColor = AppColors.successGreen;
      statusBackground = AppColors.successGreen.withValues(alpha: 0.10);
      statusIcon = Icons.access_time;
    } else {
      statusText = 'Chưa chấm công';
      statusColor = AppColors.dangerRed;
      statusBackground = AppColors.dangerRedBg;
      statusIcon = Icons.radio_button_unchecked;
    }

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: AppColors.cardBackground,

        borderRadius: BorderRadius.circular(24),

        border: Border.all(color: AppColors.borderColor),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,

                decoration: BoxDecoration(
                  color: AppColors.infoBoxBackground,

                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.fingerprint_rounded,
                  size: 32,
                  color: AppColors.primaryBlue,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    const Text(
                      'Chấm công',

                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),

                      decoration: BoxDecoration(
                        color: statusBackground,

                        borderRadius: BorderRadius.circular(20),
                      ),

                      child: Row(
                        mainAxisSize: MainAxisSize.min,

                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),

                          const SizedBox(width: 5),

                          Text(
                            statusText,

                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          if (!_isLoadingFaceStatus && _hasFace == false) _buildFaceWarning(),

          if (!_isLoadingFaceStatus && _hasFace == null)
            _buildFaceStatusError(),

          if ((!_isLoadingFaceStatus && _hasFace != false) ||
              _checkState == _CheckState.checkedIn ||
              _checkState == _CheckState.checkedOut)
            _buildAttendanceDescription(),

          const SizedBox(height: 16),

          _buildAttendanceButton(),

          const SizedBox(height: 16),

          _buildStatsRow(),
        ],
      ),
    );
  }

  // ATTENDANCE DESCRIPTION

  Widget _buildAttendanceDescription() {
    String text;

    switch (_checkState) {
      case _CheckState.loading:
        text = 'Đang tải thông tin chấm công của bạn.';
        break;

      case _CheckState.notCheckedIn:
        text = 'Vui lòng chấm công để bắt đầu ngày làm việc của bạn.';
        break;

      case _CheckState.checkedIn:
        text = 'Bạn đang làm việc. Hãy chấm công ra khi kết thúc ngày.';
        break;

      case _CheckState.checkedOut:
        text = 'Bạn đã hoàn thành ngày làm việc hôm nay.';
        break;
    }

    return Text(
      text,

      style: const TextStyle(
        fontSize: 13,
        height: 1.45,
        color: AppColors.textSecondary,
      ),
    );
  }

  // ATTENDANCE BUTTON

  Widget _buildAttendanceButton() {
    final canCheckIn =
        _checkState == _CheckState.notCheckedIn && _hasFace == true;

    final canCheckOut = _checkState == _CheckState.checkedIn;

    final canTap =
        !_isLoadingFaceStatus && !_isProcessing && (canCheckIn || canCheckOut);

    String label;
    IconData icon;
    Color backgroundColor;

    if (_isProcessing) {
      label = 'Đang xử lý...';
      icon = Icons.sync;
      backgroundColor = AppColors.primaryBlue;
    } else if (_checkState == _CheckState.checkedIn) {
      label = 'Chấm công ra';
      icon = Icons.logout_rounded;
      backgroundColor = AppColors.amber;
    } else if (_checkState == _CheckState.checkedOut) {
      label = 'Đã hoàn thành';
      icon = Icons.check_circle_outline;
      backgroundColor = AppColors.successGreen;
    } else if (_isLoadingFaceStatus) {
      label = 'Đang kiểm tra...';
      icon = Icons.hourglass_empty;
      backgroundColor = AppColors.textSecondary;
    } else {
      label = 'Chấm công vào';
      icon = Icons.access_time_rounded;
      backgroundColor = AppColors.primaryBlue;
    }

    return SizedBox(
      width: double.infinity,
      height: 54,

      child: ElevatedButton.icon(
        onPressed: canTap ? _handleCheckButtonTap : null,

        icon: _isProcessing
            ? const SizedBox(
                width: 19,
                height: 19,

                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.2,
                ),
              )
            : Icon(icon, color: Colors.white, size: 22),

        label: Text(
          label,

          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,

          disabledBackgroundColor: backgroundColor.withValues(alpha: 0.55),

          elevation: 0,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  // STATISTICS

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.access_time,
            iconColor: AppColors.primaryBlue,
            label: 'Giờ bắt đầu',
            value: _checkInTimeLabel ?? '--:--',
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _buildStatCard(
            icon: Icons.timer_outlined,
            iconColor: AppColors.amber,
            label: 'Tổng giờ làm',
            value: _workingHoursLabel ?? '0 giờ',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: AppColors.background,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: AppColors.borderColor),
      ),

      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,

            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),

              shape: BoxShape.circle,
            ),

            child: Icon(icon, size: 21, color: iconColor),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  label,

                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,

                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // UTILITIES

  Widget _buildUtilitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        const Text(
          'Tiện ích',

          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: _buildUtilityTile(
                icon: Icons.lock_outline,
                title: 'Đổi mật khẩu',
                color: AppColors.primaryBlue,
                backgroundColor: const Color(0xFFEAF2FF),
                onTap: _openChangePassword,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _buildUtilityTile(
                icon: Icons.swap_horiz_rounded,
                title: 'Yêu cầu đổi ca',
                color: const Color(0xFF7047D8),
                backgroundColor: const Color(0xFFF1ECFF),
                onTap: _openShiftChangeRequest,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildUtilityTile(
                icon: Icons.flight_takeoff_rounded,
                title: 'Đi công tác',
                color: const Color(0xFF16B88A),
                backgroundColor: const Color(0xFFE9F9F4),
                onTap: _openBusinessTripRequest,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _buildUtilityTile(
                icon: Icons.event_busy_outlined,
                title: 'Xin nghỉ phép',
                color: const Color(0xFFF28B30),
                backgroundColor: const Color(0xFFFFF3E8),
                onTap: _openLeaveRequest,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUtilityTile({
    required IconData icon,
    required String title,
    required Color color,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(18),

        child: Ink(
          height: 138,

          decoration: BoxDecoration(
            color: backgroundColor,

            borderRadius: BorderRadius.circular(18),

            border: Border.all(color: color.withValues(alpha: 0.10)),
          ),

          child: Padding(
            padding: const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                Container(
                  width: 48,
                  height: 48,

                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),

                  child: Icon(icon, color: Colors.white, size: 24),
                ),

                const SizedBox(height: 14),

                Text(
                  title,

                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // FACE WARNING

  Widget _buildFaceWarning() {
    return Container(
      width: double.infinity,

      margin: const EdgeInsets.only(bottom: 12),

      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: AppColors.cardBackground,

        borderRadius: BorderRadius.circular(14),

        border: Border.all(color: AppColors.amber),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Icon(
            Icons.face_retouching_natural,
            color: AppColors.amber,
            size: 21,
          ),

          const SizedBox(width: 9),

          const Expanded(
            child: Text(
              'Bạn chưa đăng ký khuôn mặt. '
              'Vui lòng đăng ký khuôn mặt trước '
              'khi thực hiện check-in.',

              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // FACE ERROR

  Widget _buildFaceStatusError() {
    return Container(
      width: double.infinity,

      margin: const EdgeInsets.only(bottom: 12),

      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: AppColors.cardBackground,

        borderRadius: BorderRadius.circular(14),

        border: Border.all(color: AppColors.borderColor),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.textSecondary,
            size: 21,
          ),

          const SizedBox(width: 9),

          const Expanded(
            child: Text(
              'Không thể kiểm tra trạng thái '
              'khuôn mặt. Vui lòng tải lại '
              'hoặc thử lại sau.',

              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // CHANGE PASSWORD

  void _openChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
    );
  }

  // SHIFT CHANGE

  void _openShiftChangeRequest() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ShiftChangeRequestScreen()),
    );
  }

  // BUSINESS TRIP

  void _openBusinessTripRequest() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BusinessTripRequestScreen()),
    );
  }

  // LEAVE REQUEST

  void _openLeaveRequest() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LeaveRequestScreen()),
    );
  }

  // BOTTOM NAVIGATION

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedNavIndex,

      onTap: (index) {
        if (index == _selectedNavIndex) {
          return;
        }

        setState(() {
          _selectedNavIndex = index;
        });

        switch (index) {
          // Trang chủ
          case 0:
            break;

          // Lịch sử
          case 1:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            );
            break;

          // Yêu cầu
          case 2:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LeaveRequestScreen()),
            );
            break;

          // Cá nhân
          case 3:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
            break;
        }
      },

      type: BottomNavigationBarType.fixed,

      selectedItemColor: AppColors.primaryBlue,

      unselectedItemColor: AppColors.textSecondary,

      showUnselectedLabels: true,

      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home_rounded),
          label: 'Trang chủ',
        ),

        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Lịch sử'),

        BottomNavigationBarItem(
          icon: Icon(Icons.description_outlined),
          activeIcon: Icon(Icons.description),
          label: 'Yêu cầu',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Cá nhân',
        ),
      ],
    );
  }
}