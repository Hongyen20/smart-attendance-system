import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/auth_state.dart';
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
    return '${_weekdays[now.weekday % 7]}, ${now.day} Thg ${now.month}';
  }

  @override
  void initState() {
    super.initState();
    _loadTodayStatus();
  }

  Future<void> _loadTodayStatus() async {
    final result = await ApiService.get(
      '/api/attendance/today',
      bearerToken: AuthState.instance.token,
    );

    if (!mounted) return;

    if (!result.success) {
      setState(() => _checkState = _CheckState.notCheckedIn);
      return;
    }

    final data = result.data!;
    final checkedIn = data['checkedIn'] == true;
    final checkedOut = data['checkedOut'] == true;

    setState(() {
      if (!checkedIn) {
        _checkState = _CheckState.notCheckedIn;
      } else if (checkedIn && !checkedOut) {
        _checkState = _CheckState.checkedIn;
        _checkInTimeLabel = _formatTimeFromIso(data['checkInTime'] as String?);
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
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Future<Position?> _getCurrentPosition() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _showSnack('Cần cấp quyền vị trí để check-in/check-out.');
      return null;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnack('Vui lòng bật định vị (GPS) trên thiết bị.');
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      _showSnack('Không lấy được vị trí: $e');
      return null;
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleCheckButtonTap() async {
    if (_checkState == _CheckState.checkedOut || _isProcessing) return;

    setState(() => _isProcessing = true);

    final position = await _getCurrentPosition();
    if (position == null) {
      setState(() => _isProcessing = false);
      return;
    }

    final path = _checkState == _CheckState.notCheckedIn
        ? '/api/attendance/check-in'
        : '/api/attendance/check-out';

    final result = await ApiService.post(path, {
      'lat': position.latitude,
      'lng': position.longitude,
    }, bearerToken: AuthState.instance.token);

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (result.success) {
      _showSnack(
        _checkState == _CheckState.notCheckedIn
            ? 'Check-in thành công!'
            : 'Check-out thành công!',
      );
      _loadTodayStatus();
    } else {
      _showSnack(result.errorMessage ?? 'Có lỗi xảy ra.');
    }
  }

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
                onRefresh: _loadTodayStatus,
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

  Widget _buildCheckInButton() {
    late final String title;
    late final String subtitle;
    late final Color color;
    late final IconData icon;

    switch (_checkState) {
      case _CheckState.loading:
        title = '...';
        subtitle = 'Đang tải';
        color = AppColors.textSecondary;
        icon = Icons.hourglass_empty;
        break;
      case _CheckState.notCheckedIn:
        title = 'CHẤM CÔNG';
        subtitle = 'Chạm để bắt đầu';
        color = AppColors.primaryBlue;
        icon = Icons.fingerprint;
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

    return GestureDetector(
      onTap:
          (_checkState == _CheckState.checkedOut ||
              _checkState == _CheckState.loading ||
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

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedNavIndex,
      onTap: (index) {
        if (index == _selectedNavIndex) return;
        switch (index) {
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
