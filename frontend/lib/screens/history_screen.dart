import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/auth_state.dart';
import 'leave_request_screen.dart';
import 'employee_home_screen.dart';
import 'profile_screen.dart';

enum HistoryFilter { all, onTime, late, other }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedNavIndex = 1;
  HistoryFilter _selectedFilter = HistoryFilter.all;

  late int _selectedMonth;
  late int _selectedYear;

  bool _isLoading = true;
  String? _errorMessage;

  List<dynamic> _items = [];

  double _totalHours = 0;
  int _daysWorked = 0;
  int _totalWorkdaysInMonth = 0;

  static const List<String> _weekdays = [
    'CN',
    'T2',
    'T3',
    'T4',
    'T5',
    'T6',
    'T7',
  ];

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _selectedMonth = now.month;
    _selectedYear = now.year;

    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService.get(
      '/api/attendance/history?year=$_selectedYear&month=$_selectedMonth',
      bearerToken: AuthState.instance.token,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;

      if (result.success) {
        final data = result.data!;

        _items = data['items'] as List<dynamic>;

        _totalHours = (data['totalHours'] as num).toDouble();

        _daysWorked = data['daysWorked'] as int;

        _totalWorkdaysInMonth = data['totalWorkdaysInMonth'] as int;
      } else {
        _errorMessage = result.errorMessage;
      }
    });
  }

  List<dynamic> get _filteredItems {
    switch (_selectedFilter) {
      case HistoryFilter.all:
        return _items;

      case HistoryFilter.onTime:
        return _items.where((e) => e['status'] == 'OnTime').toList();

      case HistoryFilter.late:
        return _items.where((e) => e['status'] == 'Late').toList();

      case HistoryFilter.other:
        return _items
            .where((e) => e['status'] != 'OnTime' && e['status'] != 'Late')
            .toList();
    }
  }

  String _weekdayAbbr(DateTime date) {
    return _weekdays[date.weekday % 7];
  }

  String _formatTime(String? isoString) {
    if (isoString == null) {
      return '--:--';
    }

    final dt = DateTime.parse(isoString).toLocal();

    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatHours(double hours) {
    if (hours == hours.roundToDouble()) {
      return '${hours.toInt()}h';
    }

    return '${hours.toStringAsFixed(1)}h';
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
                onRefresh: _loadHistory,
                color: AppColors.primaryBlue,

                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),

                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPageHeader(),

                      const SizedBox(height: 20),

                      _buildSummaryCards(),

                      const SizedBox(height: 20),

                      _buildMonthSelector(),

                      const SizedBox(height: 16),

                      _buildFilterChips(),

                      const SizedBox(height: 18),

                      _buildHistoryContent(),
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

  // TOP BAR

  Widget _buildTopBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(bottom: BorderSide(color: AppColors.borderColor)),
      ),

      child: Row(
        children: [
          SizedBox(
            width: 150,
            height: 60,

            child: Image.asset(
              'assets/images/logo.png',

              fit: BoxFit.contain,

              alignment: Alignment.centerLeft,
            ),
          ),

          const Spacer(),

          Container(
            width: 42,
            height: 42,

            decoration: BoxDecoration(
              color: AppColors.infoBoxBackground,
              shape: BoxShape.circle,
            ),

            child: IconButton(
              padding: EdgeInsets.zero,

              onPressed: () {},

              icon: const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.primaryBlue,
                size: 23,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // PAGE HEADER

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        const Text(
          'Lịch sử chấm công',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Theo dõi thời gian làm việc của bạn.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // SUMMARY

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.access_time_rounded,
            iconColor: AppColors.primaryBlue,
            iconBackground: AppColors.infoBoxBackground,
            value: _formatHours(_totalHours),
            label: 'Tổng giờ làm',
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _buildSummaryCard(
            icon: Icons.check_circle_outline_rounded,
            iconColor: AppColors.successGreen,
            iconBackground: AppColors.successGreenBg,
            value: '$_daysWorked/$_totalWorkdaysInMonth',
            label: 'Ngày công',
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: AppColors.cardBackground,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: AppColors.borderColor),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Container(
            width: 42,
            height: 42,

            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),

            child: Icon(icon, color: iconColor, size: 22),
          ),

          const SizedBox(height: 12),

          Text(
            value,

            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            label,

            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // MONTH SELECTOR

  Widget _buildMonthSelector() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),

      onTap: _openMonthYearPicker,

      child: Container(
        width: double.infinity,

        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),

        decoration: BoxDecoration(
          color: AppColors.cardBackground,

          borderRadius: BorderRadius.circular(16),

          border: Border.all(color: AppColors.borderColor),
        ),

        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,

              decoration: BoxDecoration(
                color: AppColors.infoBoxBackground,
                borderRadius: BorderRadius.circular(12),
              ),

              child: const Icon(
                Icons.calendar_month_outlined,
                color: AppColors.primaryBlue,
                size: 21,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const Text(
                    'Thời gian xem',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    'Tháng $_selectedMonth, $_selectedYear',

                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  // MONTH / YEAR PICKER

  Future<void> _openMonthYearPicker() async {
    int tempMonth = _selectedMonth;
    int tempYear = _selectedYear;

    final currentYear = DateTime.now().year;

    final years = List.generate(6, (i) => currentYear - 4 + i);

    await showModalBottomSheet(
      context: context,

      backgroundColor: AppColors.cardBackground,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),

      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),

              child: Column(
                mainAxisSize: MainAxisSize.min,

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,

                        decoration: BoxDecoration(
                          color: AppColors.infoBoxBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),

                        child: const Icon(
                          Icons.calendar_month,
                          color: AppColors.primaryBlue,
                        ),
                      ),

                      const SizedBox(width: 12),

                      const Text(
                        'Chọn thời gian',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdownField<int>(
                          label: 'Tháng',
                          value: tempMonth,
                          items: List.generate(12, (i) => i + 1),
                          itemLabel: (m) => 'Tháng $m',
                          onChanged: (value) {
                            setSheetState(() => tempMonth = value!);
                          },
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _buildDropdownField<int>(
                          label: 'Năm',
                          value: tempYear,
                          items: years,
                          itemLabel: (y) => '$y',
                          onChanged: (value) {
                            setSheetState(() => tempYear = value!);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,

                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedMonth = tempMonth;
                          _selectedYear = tempYear;
                        });

                        Navigator.pop(context);

                        _loadHistory();
                      },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,

                        elevation: 0,

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),

                      child: const Text(
                        'Áp dụng',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // DROPDOWN

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          label,

          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),

        const SizedBox(height: 6),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),

          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderColor),

            borderRadius: BorderRadius.circular(12),
          ),

          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,

              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.textSecondary,
              ),

              items: items
                  .map(
                    (item) => DropdownMenuItem<T>(
                      value: item,
                      child: Text(itemLabel(item)),
                    ),
                  )
                  .toList(),

              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  // FILTER

  Widget _buildFilterChips() {
    final filters = [
      (HistoryFilter.all, 'Tất cả'),
      (HistoryFilter.onTime, 'Đúng giờ'),
      (HistoryFilter.late, 'Đi muộn'),
      (HistoryFilter.other, 'Khác'),
    ];

    return SizedBox(
      height: 40,

      child: ListView.separated(
        scrollDirection: Axis.horizontal,

        itemCount: filters.length,

        separatorBuilder: (_, __) => const SizedBox(width: 8),

        itemBuilder: (context, index) {
          final (filter, label) = filters[index];

          final isSelected = _selectedFilter == filter;

          return ChoiceChip(
            label: Text(label),

            selected: isSelected,

            onSelected: (_) {
              setState(() => _selectedFilter = filter);
            },

            backgroundColor: AppColors.chipUnselectedBg,

            selectedColor: AppColors.primaryBlue,

            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppColors.chipUnselectedText,

              fontWeight: FontWeight.w600,

              fontSize: 13,
            ),

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),

              side: BorderSide.none,
            ),

            showCheckmark: false,
          );
        },
      ),
    );
  }

  // HISTORY CONTENT

  Widget _buildHistoryContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 50),

        child: Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        width: double.infinity,

        padding: const EdgeInsets.all(18),

        decoration: BoxDecoration(
          color: AppColors.dangerRedBg,

          borderRadius: BorderRadius.circular(16),
        ),

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Icon(Icons.error_outline, color: AppColors.dangerRed),

            const SizedBox(width: 10),

            Expanded(
              child: Text(
                _errorMessage!,

                style: const TextStyle(
                  color: AppColors.dangerRed,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_filteredItems.isEmpty) {
      return Container(
        width: double.infinity,

        padding: const EdgeInsets.symmetric(vertical: 45, horizontal: 20),

        decoration: BoxDecoration(
          color: AppColors.cardBackground,

          borderRadius: BorderRadius.circular(18),

          border: Border.all(color: AppColors.borderColor),
        ),

        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,

              decoration: BoxDecoration(
                color: AppColors.infoBoxBackground,
                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.history_rounded,
                color: AppColors.primaryBlue,
                size: 28,
              ),
            ),

            const SizedBox(height: 14),

            const Text(
              'Chưa có dữ liệu',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'Chưa có dữ liệu chấm công trong tháng này.',
              textAlign: TextAlign.center,

              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Row(
          children: [
            const Text(
              'Chi tiết chấm công',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const Spacer(),

            Text(
              '${_filteredItems.length} ngày',

              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        ..._filteredItems.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),

            child: _buildHistoryCard(item as Map<String, dynamic>),
          ),
        ),
      ],
    );
  }

  // HISTORY CARD

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final workDate = DateTime.parse(item['workDate'] as String);

    final status = item['status'] as String;

    final isLate = status == 'Late';

    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: AppColors.cardBackground,

        borderRadius: BorderRadius.circular(17),

        border: Border.all(color: AppColors.borderColor),
      ),

      child: Row(
        children: [
          _buildDateBadge(workDate),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  '${workDate.day.toString().padLeft(2, '0')}/'
                  '${workDate.month.toString().padLeft(2, '0')}/'
                  '${workDate.year}',

                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 7),

                Row(
                  children: [
                    _buildTimeItem(
                      icon: Icons.login_rounded,
                      time: _formatTime(item['checkInTime'] as String?),
                      color: isLate
                          ? AppColors.dangerRed
                          : AppColors.accentBlue,
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 7),
                      child: Text(
                        '→',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),

                    _buildTimeItem(
                      icon: Icons.logout_rounded,
                      time: _formatTime(item['checkOutTime'] as String?),
                      color: AppColors.successGreen,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          _buildStatusPill(status),
        ],
      ),
    );
  }

  Widget _buildDateBadge(DateTime date) {
    return Container(
      width: 52,
      height: 56,

      decoration: BoxDecoration(
        color: AppColors.infoBoxBackground,

        borderRadius: BorderRadius.circular(14),
      ),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Text(
            _weekdayAbbr(date),

            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryBlue,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            '${date.day}',

            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeItem({
    required IconData icon,
    required String time,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,

      children: [
        Icon(icon, size: 14, color: color),

        const SizedBox(width: 4),

        Text(
          time,

          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // STATUS

  Widget _buildStatusPill(String status) {
    late String label;
    late Color bg;
    late Color fg;

    switch (status) {
      case 'OnTime':
        label = 'Đúng giờ';
        bg = AppColors.successGreenBg;
        fg = AppColors.successGreen;
        break;

      case 'Late':
        label = 'Đi muộn';
        bg = AppColors.dangerRedBg;
        fg = AppColors.dangerRed;
        break;

      case 'MissingCheckout':
        label = 'Thiếu checkout';
        bg = AppColors.amberBg;
        fg = AppColors.amber;
        break;

      default:
        label = status;
        bg = AppColors.chipUnselectedBg;
        fg = AppColors.chipUnselectedText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),

      decoration: BoxDecoration(
        color: bg,

        borderRadius: BorderRadius.circular(20),
      ),

      child: Text(
        label,

        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
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
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const EmployeeHomeScreen()),
            );
            break;

          case 1:
            // Đang ở History
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
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
            break;
        }
      },

      type: BottomNavigationBarType.fixed,

      backgroundColor: AppColors.cardBackground,

      selectedItemColor: AppColors.primaryBlue,

      unselectedItemColor: AppColors.textSecondary,

      selectedFontSize: 12,

      unselectedFontSize: 12,

      showUnselectedLabels: true,

      elevation: 8,

      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),

          activeIcon: Icon(Icons.home_rounded),

          label: 'Trang chủ',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.history_outlined),

          activeIcon: Icon(Icons.history_rounded),

          label: 'Lịch sử',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.event_busy_outlined),

          activeIcon: Icon(Icons.event_busy_rounded),

          label: 'Nghỉ phép',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline_rounded),

          activeIcon: Icon(Icons.person_rounded),

          label: 'Profile',
        ),
      ],
    );
  }
}
