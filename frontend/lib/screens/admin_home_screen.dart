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
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeSection(),

                      const SizedBox(height: 14),

                      _buildOverviewCard(),

                      const SizedBox(height: 22),

                      // QUẢN LÝ NHÂN SỰ
                      _buildSectionCard(
                        title: 'Quản lý nhân sự',
                        icon: Icons.person_outline_rounded,
                        children: [
                          _buildIconGrid([
                            _FunctionTileData(
                              icon: Icons.groups_rounded,
                              title: 'Nhân viên',
                              color: const Color(0xFF3182F6),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const EmployeeListScreen(),
                                  ),
                                ).then((_) {
                                  _loadStats();
                                });
                              },
                            ),

                            _FunctionTileData(
                              icon: Icons.face_retouching_natural_rounded,
                              title: 'Khuôn mặt',
                              color: const Color(0xFF7C4DFF),
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
                                    builder: (_) =>
                                        FaceManagementScreen(token: token),
                                  ),
                                );
                              },
                            ),

                            _FunctionTileData(
                              icon: Icons.router_rounded,
                              title: 'Cấu hình IP',
                              color: const Color(0xFF20C997),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const IpConfigScreen(),
                                  ),
                                );
                              },
                            ),
                          ]),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // CHẤM CÔNG & CA LÀM VIỆC
                      _buildSectionCard(
                        title: 'Chấm công & ca làm việc',
                        icon: Icons.access_time_rounded,
                        children: [
                          _buildIconGrid([
                            _FunctionTileData(
                              icon: Icons.swap_horiz_rounded,
                              title: 'Đổi ca',
                              color: const Color(0xFFFF922B),
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

                            _FunctionTileData(
                              icon: Icons.calendar_month_rounded,
                              title: 'Nghỉ phép',
                              color: const Color(0xFFF5487F),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LeaveApprovalScreen(),
                                  ),
                                );
                              },
                            ),

                            _FunctionTileData(
                              icon: Icons.business_center_rounded,
                              title: 'Công tác',
                              color: const Color(0xFF4A90E2),
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
                        ],
                      ),

                      const SizedBox(height: 16),

                      // TÀI KHOẢN
                      _buildSectionCard(
                        title: 'Tài khoản',
                        icon: Icons.security_rounded,
                        children: [
                          _buildIconGrid([
                            _FunctionTileData(
                              icon: Icons.lock_rounded,
                              title: 'Đổi mật khẩu',
                              color: const Color(0xFF7950F2),
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
                        ],
                      ),

                      const SizedBox(height: 22),

                      _buildActivitySection(),
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

  // HEADER

  Widget _buildTopBar() {
    final fullName = AuthState.instance.fullName;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      color: AppColors.cardBackground,
      child: Row(
        children: [
          // Logo AttendGo
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFF315CF6), Color(0xFF7048E8)],
              ),
            ),
            child: const Icon(
              Icons.wifi_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'AttendGo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF122B6B),
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Quản trị viên',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Avatar
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEAF2FF),
              border: Border.all(color: const Color(0xFFD7E5FF), width: 1.5),
            ),
            child: Center(
              child: Text(
                (fullName?.isNotEmpty == true)
                    ? fullName![0].toUpperCase()
                    : 'A',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // WELCOME

  Widget _buildWelcomeSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFE4EEFF), Color(0xFFD2E3FF)],
              ),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              size: 34,
              color: Color(0xFF2F6FED),
            ),
          ),

          const SizedBox(width: 13),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chào Quản Trị Viên',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF102A67),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Đây là tổng quan hoạt động của bạn hôm nay.',
                  style: TextStyle(
                    fontSize: 12.5,
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

  // OVERVIEW

  Widget _buildOverviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF3FF), Color(0xFFF5F8FF)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDCE9FF)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildOverviewItem(
              icon: Icons.groups_rounded,
              iconColor: const Color(0xFF3182F6),
              label: 'Tổng nhân viên',
              value: _isLoadingStats ? '...' : '$_totalEmployees',
            ),
          ),

          _buildVerticalDivider(),

          Expanded(
            child: _buildOverviewItem(
              icon: Icons.access_time_filled_rounded,
              iconColor: const Color(0xFF20B878),
              label: 'Đang làm việc',
              value: '$_currentlyWorking',
            ),
          ),

          _buildVerticalDivider(),

          Expanded(
            child: _buildOverviewItem(
              icon: Icons.event_available_rounded,
              iconColor: const Color(0xFFFF922B),
              label: 'Chờ duyệt',
              value: '$_pendingLeaveRequests',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: iconColor.withOpacity(0.13),
          ),
          child: Icon(icon, color: iconColor, size: 23),
        ),

        const SizedBox(height: 7),

        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10.5,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 1),

        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: iconColor,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 65,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      color: const Color(0xFFD9E3F4),
    );
  }

  // SECTION

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      child: Column(
        children: [
          // Section header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F6FF),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(21),
                topRight: Radius.circular(21),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE0ECFF),
                  ),
                  child: Icon(icon, size: 18, color: Color(0xFF2F6FED)),
                ),

                const SizedBox(width: 9),

                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF143375),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 17),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  // ICON GRID - 3 CỘT

  Widget _buildIconGrid(List<_FunctionTileData> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 4.0;

        final itemWidth = (constraints.maxWidth - spacing * 2) / 3;

        return Wrap(
          spacing: spacing,
          runSpacing: 20,
          alignment: WrapAlignment.start,
          children: items.map((item) {
            return SizedBox(
              width: items.length == 1 ? constraints.maxWidth : itemWidth,
              child: _buildFunctionTile(item),
            );
          }).toList(),
        );
      },
    );
  }

  // ICON TILE

  Widget _buildFunctionTile(_FunctionTileData item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ICON TRÒN LỚN
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [item.color.withOpacity(0.82), item.color],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: item.color.withOpacity(0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(item.icon, color: Colors.white, size: 37),
              ),

              const SizedBox(height: 8),

              Text(
                item.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF152B5F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ACTIVITY

  Widget _buildActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 3),
          child: Text(
            'Hoạt động gần đây',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF102A67),
            ),
          ),
        ),

        const SizedBox(height: 11),

        _buildActivityItem(
          icon: Icons.login_rounded,
          iconColor: AppColors.successGreen,
          iconBg: AppColors.successGreenBg,
          richTitle: 'Minh Quân vừa chấm công vào',
          boldName: 'Minh Quân',
          subtitle: '08:45 AM • Trụ sở chính',
        ),

        const SizedBox(height: 10),

        _buildActivityItem(
          icon: Icons.description_outlined,
          iconColor: AppColors.amber,
          iconBg: AppColors.amberBg,
          richTitle: 'Thu Hà đã gửi đơn nghỉ phép',
          boldName: 'Thu Hà',
          subtitle: '09:12 AM • Nghỉ ốm',
          statusLabel: 'Đang chờ',
        ),

        const SizedBox(height: 10),

        _buildActivityItem(
          icon: Icons.access_time_rounded,
          iconColor: AppColors.accentBlue,
          iconBg: AppColors.pendingBlueBg,
          richTitle: 'Anh Tuấn đã cập nhật ca làm việc',
          boldName: 'Anh Tuấn',
          subtitle: '10:05 AM • Hậu cần',
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAF7)),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 21),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    children: [
                      TextSpan(
                        text: boldName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: restOfTitle),
                    ],
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          if (statusLabel != null) ...[
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.amberBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusLabel,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.amber,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // BOTTOM NAVIGATION

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedNavIndex,

        onTap: (index) {
          setState(() {
            _selectedNavIndex = index;
          });

          // Trang chủ
          if (index == 0) {
            return;
          }

          // Nhân viên
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EmployeeListScreen()),
            ).then((_) {
              if (!mounted) return;

              setState(() {
                _selectedNavIndex = 0;
              });

              _loadStats();
            });
          }
          // Chấm công
          else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const IpConfigScreen()),
            ).then((_) {
              if (!mounted) return;

              setState(() {
                _selectedNavIndex = 0;
              });
            });
          }
          // Yêu cầu
          else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LeaveApprovalScreen()),
            ).then((_) {
              if (!mounted) return;

              setState(() {
                _selectedNavIndex = 0;
              });
            });
          }
          // Cài đặt
          else if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
            ).then((_) {
              if (!mounted) return;

              setState(() {
                _selectedNavIndex = 0;
              });
            });
          }
        },

        type: BottomNavigationBarType.fixed,

        backgroundColor: AppColors.cardBackground,

        selectedItemColor: const Color(0xFF7048E8),

        unselectedItemColor: AppColors.textSecondary,

        selectedFontSize: 11,
        unselectedFontSize: 10,

        showUnselectedLabels: true,

        elevation: 0,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Trang chủ',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.groups_outlined),
            activeIcon: Icon(Icons.groups_rounded),
            label: 'Nhân viên',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.access_time_outlined),
            activeIcon: Icon(Icons.access_time_filled),
            label: 'Chấm công',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            activeIcon: Icon(Icons.description_rounded),
            label: 'Yêu cầu',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings_rounded),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DATA MODEL
// ============================================================

class _FunctionTileData {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _FunctionTileData({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });
}
