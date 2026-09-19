import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/api_config.dart';
import '../services/auth_state.dart';

import 'profile_screen.dart';
import 'history_screen.dart';
import 'statistics_screen.dart';
import 'leave_request_screen.dart';

enum _CheckState {
  loading,
  notCheckedIn,
  checkedIn,
  checkedOut,
}

class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  State<EmployeeHomeScreen> createState() =>
      _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState
    extends State<EmployeeHomeScreen> {
  int _selectedNavIndex = 0;

  _CheckState _checkState = _CheckState.loading;

  String? _checkInTimeLabel;
  String? _workingHoursLabel;

  bool _isProcessing = false;

  final ImagePicker _imagePicker = ImagePicker();

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
    _loadTodayStatus();
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

        _checkInTimeLabel = _formatTimeFromIso(
          data['checkInTime'] as String?,
        );

        _workingHoursLabel = null;
      } else {
        _checkState = _CheckState.checkedOut;

        _checkInTimeLabel = _formatTimeFromIso(
          data['checkInTime'] as String?,
        );

        final hours =
            (data['workingHours'] as num?)?.toDouble() ?? 0;

        _workingHoursLabel =
            '${hours.toStringAsFixed(1)}h';
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
          .get(
            Uri.parse(
              'https://api.ipify.org?format=json',
            ),
          )
          .timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode != 200) {
        _showSnack(
          'Không thể lấy địa chỉ IP công cộng.',
        );

        return null;
      }

      final data = jsonDecode(response.body);

      if (data is! Map<String, dynamic>) {
        _showSnack(
          'Dữ liệu IP không hợp lệ.',
        );

        return null;
      }

      final ip = data['ip']?.toString().trim();

      if (ip == null || ip.isEmpty) {
        _showSnack(
          'Không nhận được địa chỉ IP công cộng.',
        );

        return null;
      }

      if (!_isValidIPv4(ip)) {
        _showSnack(
          'Địa chỉ IPv4 nhận được không hợp lệ.',
        );

        return null;
      }

      return ip;
    } catch (e) {
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

      if (value == null ||
          value < 0 ||
          value > 255) {
        return false;
      }
    }

    return true;
  }

  // LẤY GPS HIỆN TẠI

  Future<Position?> _getCurrentPosition() async {
    var permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      _showSnack(
        'Cần cấp quyền vị trí để check-in/check-out.',
      );

      return null;
    }

    if (permission ==
        LocationPermission.deniedForever) {
      _showSnack(
        'Quyền vị trí đã bị từ chối vĩnh viễn. '
        'Vui lòng cấp quyền vị trí trong cài đặt.',
      );

      return null;
    }

    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      _showSnack(
        'Vui lòng bật định vị (GPS) trên thiết bị.',
      );

      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      _showSnack(
        'Không lấy được vị trí hiện tại. '
        'Vui lòng thử lại.',
      );

      return null;
    }
  }

  // CHỤP KHUÔN MẶT - TỐI ĐA 45 GIÂY

  Future<XFile?> _captureFaceImage() async {
    if (!mounted) {
      return null;
    }

    _showSnack(
      'Camera đã mở. Vui lòng chụp rõ khuôn mặt trong 45 giây.',
    );

    try {
      final image = await _imagePicker
          .pickImage(
            source: ImageSource.camera,
            imageQuality: 85,
            maxWidth: 1280,
            maxHeight: 1280,
          )
          .timeout(
            const Duration(seconds: 45),
          );

      if (image == null) {
        _showSnack(
          'Chưa nhận thấy khuôn mặt. '
          'Vui lòng thử lại.',
        );

        return null;
      }

      return image;
    } on TimeoutException {
      _showSnack(
        'Chưa nhận thấy khuôn mặt trong 45 giây. '
        'Vui lòng thử lại.',
      );

      return null;
    } catch (e) {
      debugPrint(
        'Face camera error: $e',
      );

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

    return Uri.parse(
      '${ApiConfig.baseUrl}$path',
    );
  }

  // CHECK-IN
  // IP -> GPS -> FACE -> REKOGNITION -> ATTENDANCE

  Future<void> _performCheckIn({
    required String publicIp,
    required Position position,
  }) async {
    // BƯỚC 3: CHỤP KHUÔN MẶT

    final faceImage =
        await _captureFaceImage();

    if (!mounted) return;

    if (faceImage == null) {
      return;
    }

    // ĐỌC FILE ẢNH

    final imageBytes =
        await faceImage.readAsBytes();

    if (imageBytes.isEmpty) {
      _showSnack(
        'Không đọc được ảnh khuôn mặt.',
      );

      return;
    }

    _showSnack(
      'Đang xác thực khuôn mặt...',
    );

    try {
      // TẠO MULTIPART REQUEST

      final request = http.MultipartRequest(
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

      // FORM FIELDS

      request.fields['lat'] =
          position.latitude.toString();

      request.fields['lng'] =
          position.longitude.toString();

      request.fields['publicIp'] =
          publicIp;

      request.fields['deviceId'] =
          '';

      // FACE IMAGE

      request.files.add(
        http.MultipartFile.fromBytes(
          'faceImage',
          imageBytes,
          filename: 'face.jpg',
        ),
      );

      // SEND REQUEST

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

      if (!mounted) return;

      // SUCCESS

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        _showSnack(
          data?['message']?.toString() ??
              'Check-in thành công!',
        );

        await _loadTodayStatus();

        return;
      }

      // ERROR

      final errorMessage =
          data?['message']?.toString() ??
              'Xác thực khuôn mặt thất bại.';

      _showSnack(
        errorMessage,
      );
    } catch (e) {
      debugPrint(
        'Check-in multipart error: $e',
      );

      if (!mounted) return;

      _showSnack(
        'Không thể kết nối đến máy chủ.',
      );
    }
  }

  // CHECK-OUT
  //
  // IP -> GPS -> ATTENDANCE

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
        _showSnack(
          'Check-out thành công!',
        );

        await _loadTodayStatus();
      } else {
        _showSnack(
          result.errorMessage ??
              'Xác thực check-out thất bại.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      debugPrint(
        'Check-out error: $e',
      );

      _showSnack(
        'Có lỗi xảy ra khi thực hiện check-out.',
      );
    }
  }

  // CHECK-IN / CHECK-OUT

  Future<void> _handleCheckButtonTap() async {
    if (_checkState == _CheckState.checkedOut ||
        _checkState == _CheckState.loading ||
        _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // ========================================================
      // BƯỚC 1: PUBLIC IPV4
      // ========================================================

      _showSnack(
        'Bước 1/3: Đang kiểm tra địa chỉ IP...',
      );

      final publicIp =
          await _getPublicIp();

      if (!mounted) return;

      if (publicIp == null) {
        return;
      }

      // ========================================================
      // BƯỚC 2: GPS
      // ========================================================

      _showSnack(
        'Bước 2/3: Đang xác định vị trí...',
      );

      final position =
          await _getCurrentPosition();

      if (!mounted) return;

      if (position == null) {
        return;
      }

      // ========================================================
      // XÁC ĐỊNH CHECK-IN / CHECK-OUT
      // ========================================================

      final isCheckIn =
          _checkState ==
              _CheckState.notCheckedIn;

      // ========================================================
      // CHECK-IN
      // ========================================================

      if (isCheckIn) {
        await _performCheckIn(
          publicIp: publicIp,
          position: position,
        );

        return;
      }

      // ========================================================
      // CHECK-OUT
      // ========================================================

      await _performCheckOut(
        publicIp: publicIp,
        position: position,
      );
    } catch (e) {
      debugPrint(
        'Attendance error: $e',
      );

      if (!mounted) return;

      _showSnack(
        'Có lỗi xảy ra khi thực hiện chấm công.',
      );
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
        SnackBar(
          content: Text(message),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.background,

      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),

            Expanded(
              child: RefreshIndicator(
                onRefresh:
                    _loadTodayStatus,

                child:
                    SingleChildScrollView(
                  physics:
                      const AlwaysScrollableScrollPhysics(),

                  padding:
                      const EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    32,
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      _buildGreetingRow(),

                      const SizedBox(
                        height: 32,
                      ),

                      Center(
                        child:
                            _buildCheckInButton(),
                      ),

                      const SizedBox(
                        height: 32,
                      ),

                      _buildStatsRow(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar:
          _buildBottomNav(),
    );
  }

  // TOP BAR

  Widget _buildTopBar() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 14,
      ),

      decoration:
          const BoxDecoration(
        color:
            AppColors.cardBackground,

        border: Border(
          bottom: BorderSide(
            color:
                AppColors.borderColor,
          ),
        ),
      ),

      child: Row(
        children: [
          const Icon(
            Icons.wifi,
            color:
                AppColors.primaryBlue,
            size: 24,
          ),

          const SizedBox(width: 8),

          const Text(
            'AttendGo',
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
              color:
                  AppColors.primaryBlue,
            ),
          ),

          const Spacer(),

          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none,
              color:
                  AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // GREETING

  Widget _buildGreetingRow() {
    final userName =
        AuthState.instance.fullName ?? '';

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,

      children: [
        Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            const Text(
              'XIN CHÀO,',
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.w600,
                color:
                    AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),

            Text(
              '$userName!',
              style: const TextStyle(
                fontSize: 28,
                fontWeight:
                    FontWeight.bold,
                color:
                    AppColors.textPrimary,
              ),
            ),
          ],
        ),

        Column(
          crossAxisAlignment:
              CrossAxisAlignment.end,

          children: [
            Text(
              _formattedNow,
              style: const TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
                color:
                    AppColors.primaryBlue,
              ),
            ),

            const SizedBox(height: 2),

            Text(
              _formattedDate,
              style: const TextStyle(
                fontSize: 13,
                color:
                    AppColors.textSecondary,
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

    switch (_checkState) {
      case _CheckState.loading:
        title = '...';
        subtitle = 'Đang tải';
        color =
            AppColors.textSecondary;
        icon =
            Icons.hourglass_empty;
        break;

      case _CheckState.notCheckedIn:
        title = 'CHẤM CÔNG';
        subtitle =
            'Chạm để bắt đầu';
        color =
            AppColors.primaryBlue;
        icon = Icons.fingerprint;
        break;

      case _CheckState.checkedIn:
        title = 'CHẤM CÔNG RA';
        subtitle =
            'Chạm để kết thúc';
        color = AppColors.amber;
        icon = Icons.logout;
        break;

      case _CheckState.checkedOut:
        title = 'ĐÃ HOÀN THÀNH';
        subtitle =
            'Hẹn gặp lại ngày mai';
        color =
            AppColors.successGreen;
        icon =
            Icons.check_circle_outline;
        break;
    }

    return GestureDetector(
      onTap:
          (_checkState ==
                      _CheckState.checkedOut ||
                  _checkState ==
                      _CheckState.loading ||
                  _isProcessing)
              ? null
              : _handleCheckButtonTap,

      child: Container(
        width: 220,
        height: 220,

        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,

          boxShadow: [
            BoxShadow(
              color:
                  color.withValues(
                alpha: 0.35,
              ),
              blurRadius: 40,
              spreadRadius: 6,
            ),
          ],
        ),

        child: Center(
          child: _isProcessing
              ? const CircularProgressIndicator(
                  color: Colors.white,
                )
              : Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,

                  children: [
                    Icon(
                      icon,
                      color: Colors.white,
                      size: 52,
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    Text(
                      title,
                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      subtitle,
                      style:
                          const TextStyle(
                        color:
                            Colors.white70,
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
            icon:
                Icons.access_time,
            iconColor:
                AppColors.accentBlue,
            label:
                'Giờ bắt đầu',
            value:
                _checkInTimeLabel ??
                    '--:--',
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _buildStatCard(
            icon:
                Icons.timer_outlined,
            iconColor:
                AppColors.amber,
            label:
                'Tổng giờ làm',
            value:
                _workingHoursLabel ??
                    '0h',
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
      padding:
          const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color:
            AppColors.cardBackground,

        borderRadius:
            BorderRadius.circular(16),

        border: Border.all(
          color:
              AppColors.borderColor,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: iconColor,
              ),

              const SizedBox(
                width: 6,
              ),

              Text(
                label,
                style:
                    const TextStyle(
                  fontSize: 13,
                  color:
                      AppColors.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            value,
            style:
                const TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
              color:
                  AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // BOTTOM NAVIGATION

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex:
          _selectedNavIndex,

      onTap: (index) {
        if (index ==
            _selectedNavIndex) {
          return;
        }

        switch (index) {
          case 0:
            break;

          case 1:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const HistoryScreen(),
              ),
            );
            break;

          case 2:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const LeaveRequestScreen(),
              ),
            );
            break;

          case 3:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const StatisticsScreen(),
              ),
            );
            break;

          case 4:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const ProfileScreen(),
              ),
            );
            break;
        }
      },

      type:
          BottomNavigationBarType.fixed,

      selectedItemColor:
          AppColors.primaryBlue,

      unselectedItemColor:
          AppColors.textSecondary,

      showUnselectedLabels:
          true,

      items: const [
        BottomNavigationBarItem(
          icon:
              Icon(Icons.home_outlined),
          label: 'Trang chủ',
        ),

        BottomNavigationBarItem(
          icon:
              Icon(Icons.history),
          label: 'Lịch sử',
        ),

        BottomNavigationBarItem(
          icon: Icon(
            Icons.event_busy_outlined,
          ),
          label: 'Nghỉ phép',
        ),

        BottomNavigationBarItem(
          icon: Icon(
            Icons.bar_chart_outlined,
          ),
          label: 'Thống kê',
        ),

        BottomNavigationBarItem(
          icon: Icon(
            Icons.person_outline,
          ),
          label: 'Profile',
        ),
      ],
    );
  }
}
