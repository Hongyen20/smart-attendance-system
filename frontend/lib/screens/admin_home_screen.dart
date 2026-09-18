import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/auth_state.dart';
import 'employee_list_screen.dart';
import 'ip_config_screen.dart';
import 'change_password_screen.dart';
import 'leave_approval_screen.dart';
import 'shift_change_approval_screen.dart';
import 'face_management_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedNavIndex = 0;

  bool _isLoadingStats = true;
  int _totalEmployees = 0;

  final int _currentlyWorking = 0;
  final int _pendingLeaveRequests = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final result = await ApiService.getList(
      '/api/employees',
      bearerToken: AuthState.instance.token,
    );

    if (!mounted) return;

    setState(() {
      _isLoadingStats = false;

      if (result.success) {
        _totalEmployees = result.data!.length;
      }
    });
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
                onRefresh: _loadStats,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chào Quản Trị Viên',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Đây là tổng quan hoạt động của bạn trong ngày hôm nay.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 20),

                      _buildTotalEmployeesCard(),

                      const SizedBox(height: 12),

                      _buildStatsRow(),

                      const SizedBox(height: 24),

                      _buildSectionTitle('Quản lý nhân sự'),

                      const SizedBox(height: 12),

                      _buildFunctionGrid([
                        _FunctionTileData(
                          icon: Icons.groups_outlined,
                          title: 'Nhân viên',
                          subtitle: 'Quản lý tài khoản',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const EmployeeListScreen(),
                              ),
                            ).then((_) {
                              _loadStats();
                            });
                          },
                        ),
                        _FunctionTileData(
                          icon: Icons.face_retouching_natural,
                          title: 'Khuôn mặt',
                          subtitle: 'Đăng ký & xác thực',
                          onTap: () {
                            final token = AuthState.instance.token;

                            if (token == null || token.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Phiên đăng nhập không hợp lệ.',
                                  ),
                                ),
                              );
                              return;
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FaceManagementScreen(
                                  token: token,
                                ),
                              ),
                            );
                          },
                        ),
                      ]),

                      const SizedBox(height: 24),

                      _buildSectionTitle('Chấm công & ca làm việc'),

                      const SizedBox(height: 12),

                      _buildFunctionGrid([
                        _FunctionTileData(
                          icon: Icons.router_outlined,
                          title: 'Cấu hình IP',
                          subtitle: 'Thiết lập mạng chấm công',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const IpConfigScreen(),
                              ),
                            );
                          },
                        ),
                        _FunctionTileData(
                          icon: Icons.schedule_outlined,
                          title: 'Đổi ca',
                          subtitle: 'Duyệt yêu cầu đổi ca',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const ShiftChangeApprovalScreen(),
                              ),
                            );
                          },
                        ),
                      ]),

                      const SizedBox(height: 24),

                      _buildSectionTitle('Duyệt yêu cầu'),

                      const SizedBox(height: 12),

                      _buildFunctionGrid([
                        _FunctionTileData(
                          icon: Icons.fact_check_outlined,
                          title: 'Nghỉ phép',
                          subtitle: 'Duyệt đơn nghỉ phép',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const LeaveApprovalScreen(),
                              ),
                            );
                          },
                        ),
                        _FunctionTileData(
                          icon: Icons.business_center_outlined,
                          title: 'Công tác',
                          subtitle: 'Quản lý yêu cầu công tác',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Chức năng đang được phát triển.',
                                ),
                              ),
                            );
                          },
                        ),
                      ]),

                      const SizedBox(height: 24),

                      _buildSectionTitle('Tài khoản'),

                      const SizedBox(height: 12),

                      _buildFunctionGrid([
                        _FunctionTileData(
                          icon: Icons.lock_outline,
                          title: 'Đổi mật khẩu',
                          subtitle: 'Bảo mật tài khoản',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const ChangePasswordScreen(),
                              ),
                            );
                          },
                        ),
                      ]),

                      const SizedBox(height: 28),

                      _buildActivitySectionHeader(),

                      const SizedBox(height: 12),

                      _buildActivityItem(
                        icon: Icons.login,
                        iconColor: AppColors.successGreen,
                        iconBg: AppColors.successGreenBg,
                        richTitle: 'Minh Quân vừa chấm công vào',
                        boldName: 'Minh Quân',
                        subtitle: '08:45 AM • Trụ sở chính',
                      ),

                      const SizedBox(height: 12),

                      _buildActivityItem(
                        icon: Icons.description_outlined,
                        iconColor: AppColors.amber,
                        iconBg: AppColors.amberBg,
                        richTitle: 'Thu Hà đã gửi đơn nghỉ phép',
                        boldName: 'Thu Hà',
                        subtitle: '09:12 AM • Nghỉ ốm',
                        statusLabel: 'Đang chờ',
                      ),

                      const SizedBox(height: 12),

                      _buildActivityItem(
                        icon: Icons.access_time,
                        iconColor: AppColors.accentBlue,
                        iconBg: AppColors.pendingBlueBg,
                        richTitle: 'Anh Tuấn đã cập nhật ca làm việc',
                        boldName: 'Anh Tuấn',
                        subtitle: '10:05 AM • Hậu cần',
                      ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 14,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderColor,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi,
            color: AppColors.primaryBlue,
            size: 24,
          ),
          const SizedBox(width: 8),
          const Text(
            'Quản Trị AttendGo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
          const Spacer(),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.infoBoxBackground,
            child: Text(
              (AuthState.instance.fullName?.isNotEmpty == true)
                  ? AuthState.instance.fullName![0].toUpperCase()
                  : 'A',
              style: const TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildFunctionGrid(
    List<_FunctionTileData> items,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: items.length == 1 ? 1 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: items.length == 1 ? 3.5 : 1.35,
      ),
      itemBuilder: (context, index) {
        final item = items[index];

        return _buildFunctionTile(item);
      },
    );
  }

  Widget _buildFunctionTile(
    _FunctionTileData item,
  ) {
    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: item.onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.borderColor,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.infoBoxBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.icon,
                  color: AppColors.primaryBlue,
                  size: 23,
                ),
              ),
              const Spacer(),
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalEmployeesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.infoBoxBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TỔNG NHÂN VIÊN',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                _isLoadingStats
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        '$_totalEmployees',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
              ],
            ),
          ),
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.cardBackground,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.groups_outlined,
              color: AppColors.primaryBlue,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildMiniStatCard(
            dotColor: AppColors.successGreen,
            label: 'Đang làm việc',
            value: _currentlyWorking,
            barColor: AppColors.successGreen,
            barFraction: _totalEmployees == 0
                ? 0
                : _currentlyWorking / _totalEmployees,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniStatCard(
            dotColor: AppColors.dangerRed,
            label: 'Đơn nghỉ phép chờ duyệt',
            value: _pendingLeaveRequests,
            barColor: AppColors.dangerRed,
            barFraction: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStatCard({
    required Color dotColor,
    required String label,
    required int value,
    required Color barColor,
    required double barFraction,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: barFraction.clamp(0, 1),
              minHeight: 5,
              backgroundColor: AppColors.borderColor,
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Hoạt động gần đây',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        TextButton(
          onPressed: () {
            // TODO: điều hướng sang màn hình nhật ký hoạt động đầy đủ.
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Xem tất cả',
            style: TextStyle(
              color: AppColors.accentBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String richTitle,
    required String boldName,
    required String subtitle,
    String? statusLabel,
  }) {
    final restOfTitle = richTitle.substring(boldName.length);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.borderColor,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    children: [
                      TextSpan(
                        text: boldName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: restOfTitle,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (statusLabel != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppColors.amberBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.amber,
                ),
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
        setState(() {
          _selectedNavIndex = index;
        });

        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const EmployeeListScreen(),
            ),
          ).then((_) {
            if (!mounted) return;

            setState(() {
              _selectedNavIndex = 0;
            });

            _loadStats();
          });
        } else if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const LeaveApprovalScreen(),
            ),
          ).then((_) {
            if (!mounted) return;

            setState(() {
              _selectedNavIndex = 0;
            });
          });
        }

        // TODO: index 3 "Báo cáo" cần Controller riêng.
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primaryBlue,
      unselectedItemColor: AppColors.textSecondary,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          label: 'Tổng quan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.groups_outlined),
          label: 'Nhân viên',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.fact_check_outlined),
          label: 'Duyệt đơn',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_outlined),
          label: 'Báo cáo',
        ),
      ],
    );
  }
}

class _FunctionTileData {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FunctionTileData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
