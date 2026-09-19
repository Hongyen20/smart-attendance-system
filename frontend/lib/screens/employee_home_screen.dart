import 'dart:async';
import 'dart:convert';

import 'package:camera/camera.dart' show XFile;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/api_config.dart';
import '../services/auth_state.dart';

import 'face_capture_screen.dart';
import 'profile_screen.dart';
import 'history_screen.dart';
import 'statistics_screen.dart';
import 'leave_request_screen.dart';

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

  static const List<String> _weekdays = [
    'Chủ Nhật',
    'Thứ Hai',
    'Thứ Ba',
    'Thứ Tư',
    'Thứ Năm',
    'Thứ Sáu',
    'Thứ Bảy',
  ];

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

  @override
  void initState() {
    super.initState();

    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await Future.wait([_loadTodayStatus(), _loadFaceStatus()]);
  }

  // LOAD TRẠNG THÁI KHUÔN MẶT

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

  // LOAD TRẠNG THÁI CHẤM CÔNG HÔM NAY

  Future<void> _loadTodayStatus() async {
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

        _checkInTimeLabel = _formatTimeFromIso(data['checkInTime'] as String?);

        _workingHoursLabel = null;
      } else {
        _checkState = _CheckState.checkedOut;

        _checkInTimeLabel = _formatTimeFromIso(data['checkInTime'] as String?);

        final hours = (data['workingHours'] as num?)?.toDouble() ?? 0;

        _workingHoursLabel = '${hours.toStringAsFixed(1)}h';
      }
    });
  }

  String? _formatTimeFromIso(String? iso) {
    if (iso == null) return null;

    final dt = DateTime.tryParse(iso);

    if (dt == null) return null;

    final local = dt.toLocal();

    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  // LẤY PUBLIC IPV4

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

  // KIỂM TRA IPV4

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

  // LẤY GPS HIỆN TẠI
  // Mọi bước đều có timeout để không bao giờ bị treo vô hạn.

  Future<Position?> _getCurrentPosition() async {
    try {
      // 1. KIỂM TRA GPS / LOCATION SERVICE (chỉ áp dụng cho app native)

      if (!kIsWeb) {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();

        if (!serviceEnabled) {
          _showSnack('GPS đang tắt. Vui lòng bật định vị trên điện thoại.');

          return null;
        }
      }

      // 2. KIỂM TRA QUYỀN LOCATION

      debugPrint('GPS: checkPermission...');

      var permission = await Geolocator.checkPermission().timeout(
        const Duration(seconds: 10),
      );

      if (permission == LocationPermission.denied) {
        _showSnack('Đang yêu cầu quyền truy cập vị trí...');

        debugPrint('GPS: requestPermission...');

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

      // 3. LẤY GPS
      // Lần 1: độ chính xác thấp (nhanh, dùng Wi-Fi/mạng)
      // Lần 2: độ chính xác cao (dùng GPS thật) nếu lần 1 timeout

      _showSnack('Đang lấy vị trí GPS...');

      Position? position;

      try {
        debugPrint('GPS: getCurrentPosition (low)...');

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

      // 4. KIỂM TRA KẾT QUẢ

      if (position.latitude == 0 && position.longitude == 0) {
        _showSnack('Không nhận được tọa độ GPS hợp lệ.');

        return null;
      }

      _showSnack('Đã lấy vị trí GPS thành công.');

      return position;
    } on TimeoutException {
      debugPrint('GPS: timeout');

      _showSnack(
        'Không lấy được vị trí GPS. Hãy mở trang bằng Chrome/Safari '
        '(không dùng trình duyệt trong Zalo/Messenger), cấp quyền Vị trí '
        'cho trình duyệt rồi thử lại.',
      );

      return null;
    } catch (e) {
      debugPrint('GPS error: $e');

      _showSnack('Lỗi GPS: $e');

      return null;
    }
  }

  // CHỤP KHUÔN MẶT
  // Mở camera trực tiếp (không cho chọn file từ máy)

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

  // TẠO API URI

  Uri _buildApiUri(String path) {
    if (ApiConfig.baseUrl.isEmpty) {
      return Uri.base.resolve(path);
    }

    return Uri.parse('${ApiConfig.baseUrl}$path');
  }

  // CHECK-IN
  // IP → GPS → CAMERA → REKOGNITION

  Future<void> _performCheckIn({
    required String publicIp,
    required Position position,
  }) async {
    // 1. MỞ CAMERA

    final faceImage = await _captureFaceImage();

    if (!mounted) return;

    if (faceImage == null) {
      return;
    }

    // 2. ĐỌC ẢNH

    final imageBytes = await faceImage.readAsBytes();

    if (imageBytes.isEmpty) {
      _showSnack('Không đọc được ảnh khuôn mặt.');

      return;
    }

    _showSnack('Đang xác thực khuôn mặt...');

    try {
      // 3. MULTIPART REQUEST

      final request = http.MultipartRequest(
        'POST',
        _buildApiUri('/api/attendance/check-in'),
      );

      // 4. JWT

      final token = AuthState.instance.token;

      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // 5. FORM FIELDS

      request.fields['lat'] = position.latitude.toString();

      request.fields['lng'] = position.longitude.toString();

      request.fields['publicIp'] = publicIp;

      request.fields['deviceId'] = '';

      // 6. FACE IMAGE

      request.files.add(
        http.MultipartFile.fromBytes(
          'faceImage',
          imageBytes,
          filename: 'face.jpg',
        ),
      );

      // 7. SEND

      final response = await request.send();

      final responseBody = await response.stream.bytesToString();

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

      // 8. SUCCESS

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _showSnack(data?['message']?.toString() ?? 'Check-in thành công!');

        await _loadTodayStatus();

        return;
      }

      // 9. ERROR

      final errorMessage =
          data?['message']?.toString() ?? 'Xác thực khuôn mặt thất bại.';

      _showSnack(errorMessage);
    } catch (e) {
      debugPrint('Check-in multipart error: $e');

      if (!mounted) return;

      _showSnack('Không thể kết nối đến máy chủ.');
    }
  }

  // CHECK-OUT
  // IP → GPS → ATTENDANCE

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

  // CHECK-IN / CHECK-OUT

  Future<void> _handleCheckButtonTap() async {
    if (_checkState == _CheckState.checkedOut ||
        _checkState == _CheckState.loading ||
        _isProcessing ||
        _isLoadingFaceStatus) {
      return;
    }

    final isCheckIn = _checkState == _CheckState.notCheckedIn;

    // CHECK-IN: PHẢI CÓ FACE STATUS TRƯỚC

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
      // BƯỚC 1: PUBLIC IPV4

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

      // BƯỚC 2: GPS

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
      // BƯỚC 3: CAMERA + FACE VERIFICATION

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
            _buildTopBar(),

            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([_loadTodayStatus(), _loadFaceStatus()]);
                },

                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),

                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      _buildGreetingRow(),

                      const SizedBox(height: 32),

                      Center(child: _buildCheckInButton()),

                      const SizedBox(height: 32),

                      _buildStatsRow(),

                      const SizedBox(height: 16),

                      if (!_isLoadingFaceStatus && _hasFace == false)
                        _buildFaceWarning(),

                      if (!_isLoadingFaceStatus && _hasFace == null)
                        _buildFaceStatusError(),
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

  // FACE WARNING

  Widget _buildFaceWarning() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: AppColors.cardBackground,

        borderRadius: BorderRadius.circular(14),

        border: Border.all(color: AppColors.amber),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Icon(Icons.face_retouching_natural, color: AppColors.amber),

          const SizedBox(width: 10),

          const Expanded(
            child: Text(
              'Bạn chưa đăng ký khuôn mặt. '
              'Vui lòng đăng ký khuôn mặt trước '
              'khi thực hiện check-in.',
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  // FACE STATUS ERROR

  Widget _buildFaceStatusError() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(14),

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
          ),

          const SizedBox(width: 10),

          const Expanded(
            child: Text(
              'Không thể kiểm tra trạng thái '
              'khuôn mặt. Vui lòng tải lại trang '
              'hoặc thử lại sau.',
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  // TOP BAR

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),

      decoration: const BoxDecoration(
        color: AppColors.cardBackground,

        border: Border(bottom: BorderSide(color: AppColors.borderColor)),
      ),

      child: Row(
        children: [
          const Icon(Icons.wifi, color: AppColors.primaryBlue, size: 24),

          const SizedBox(width: 8),

          const Text(
            'AttendGo',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),

          const Spacer(),

          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // GREETING

  Widget _buildGreetingRow() {
    final userName = AuthState.instance.fullName ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      mainAxisAlignment: MainAxisAlignment.spaceBetween,

      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'XIN CHÀO,',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),

            Text(
              '$userName!',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),

        Column(
          crossAxisAlignment: CrossAxisAlignment.end,

          children: [
            Text(
              _formattedNow,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),

            const SizedBox(height: 2),

            Text(
              _formattedDate,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // CHECK BUTTON

  Widget _buildCheckInButton() {
    late final String title;
    late final String subtitle;
    late final Color color;
    late final IconData icon;

    if (_isLoadingFaceStatus) {
      title = '...';
      subtitle = 'Đang kiểm tra';
      color = AppColors.textSecondary;
      icon = Icons.hourglass_empty;
    } else {
      switch (_checkState) {
        case _CheckState.loading:
          title = '...';
          subtitle = 'Đang tải';
          color = AppColors.textSecondary;
          icon = Icons.hourglass_empty;
          break;

        case _CheckState.notCheckedIn:
          if (_hasFace == null) {
            title = 'CHẤM CÔNG';
            subtitle = 'Không thể kiểm tra khuôn mặt';
            color = AppColors.textSecondary;
            icon = Icons.warning_amber_rounded;
          } else if (_hasFace == false) {
            title = 'CHẤM CÔNG';
            subtitle = 'Chưa đăng ký khuôn mặt';
            color = AppColors.textSecondary;
            icon = Icons.face_retouching_natural;
          } else {
            title = 'CHẤM CÔNG';
            subtitle = 'Chạm để bắt đầu';
            color = AppColors.primaryBlue;
            icon = Icons.fingerprint;
          }
          break;

        case _CheckState.checkedIn:
          title = 'CHẤM CÔNG RA';
          subtitle = 'Chạm để kết thúc';
          color = AppColors.amber;
          icon = Icons.logout;
          break;

        case _CheckState.checkedOut:
          title = 'ĐÃ HOÀN THÀNH';
          subtitle = 'Hẹn gặp lại ngày mai';
          color = AppColors.successGreen;
          icon = Icons.check_circle_outline;
          break;
      }
    }

    final canTap =
        !_isLoadingFaceStatus &&
        !_isProcessing &&
        _checkState != _CheckState.checkedOut &&
        _checkState != _CheckState.loading &&
        (_checkState != _CheckState.notCheckedIn || _hasFace == true);

    return GestureDetector(
      onTap: canTap ? _handleCheckButtonTap : null,

      child: Container(
        width: 220,
        height: 220,

        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,

          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 40,
              spreadRadius: 6,
            ),
          ],
        ),

        child: Center(
          child: _isProcessing
              ? const CircularProgressIndicator(color: Colors.white)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    Icon(icon, color: Colors.white, size: 52),

                    const SizedBox(height: 12),

                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
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
            iconColor: AppColors.accentBlue,
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
            value: _workingHoursLabel ?? '0h',
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
      padding: const EdgeInsets.all(16),

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
              Icon(icon, size: 16, color: iconColor),

              const SizedBox(width: 6),

              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
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

        switch (index) {
          case 0:
            break;

          case 1:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            );
            break;

          case 2:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LeaveRequestScreen()),
            );
            break;

          case 3:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const StatisticsScreen()),
            );
            break;

          case 4:
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
          label: 'Trang chủ',
        ),

        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Lịch sử'),

        BottomNavigationBarItem(
          icon: Icon(Icons.event_busy_outlined),
          label: 'Nghỉ phép',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_outlined),
          label: 'Thống kê',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }
}
