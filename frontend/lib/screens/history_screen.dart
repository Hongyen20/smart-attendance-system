import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/auth_state.dart';
import 'leave_request_screen.dart';
import 'employee_home_screen.dart';
import 'statistics_screen.dart';
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
        _items = result.data!['items'] as List<dynamic>;
        _totalHours = (result.data!['totalHours'] as num).toDouble();
        _daysWorked = result.data!['daysWorked'] as int;
        _totalWorkdaysInMonth = result.data!['totalWorkdaysInMonth'] as int;
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

  String _weekdayAbbr(DateTime date) => _weekdays[date.weekday % 7];

  String _formatTime(String? isoString) {
    if (isoString == null) return '--:--';
    final dt = DateTime.parse(isoString).toLocal();
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lịch Sử Chấm Công',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Xem chi tiết dữ liệu điểm danh của bạn.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildMonthSelector(),
                      const SizedBox(height: 16),
                      _buildFilterChips(),
                      const SizedBox(height: 16),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppColors.dangerRed),
                          ),
                        )
                      else if (_filteredItems.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text(
                              'Chưa có dữ liệu chấm công trong tháng này.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        )
                      else
                        ..._filteredItems.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildHistoryCard(
                              item as Map<String, dynamic>,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      _buildSummaryRow(),
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
            'FlexTime',
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

  Widget _buildMonthSelector() {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: _openMonthYearPicker,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tháng $_selectedMonth, $_selectedYear',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMonthYearPicker() async {
    int tempMonth = _selectedMonth;
    int tempYear = _selectedYear;
    final currentYear = DateTime.now().year;
    final years = List.generate(6, (i) => currentYear - 4 + i);

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chọn tháng và năm',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdownField<int>(
                          label: 'Tháng',
                          value: tempMonth,
                          items: List.generate(12, (i) => i + 1),
                          itemLabel: (m) => 'Tháng $m',
                          onChanged: (value) =>
                              setSheetState(() => tempMonth = value!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdownField<int>(
                          label: 'Năm',
                          value: tempYear,
                          items: years,
                          itemLabel: (y) => '$y',
                          onChanged: (value) =>
                              setSheetState(() => tempYear = value!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedMonth = tempMonth;
                          _selectedYear = tempYear;
                        });
                        Navigator.pop(context);
                        _loadHistory();
                      },
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
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final (filter, label) = filters[index];
          final isSelected = _selectedFilter == filter;
          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) => setState(() => _selectedFilter = filter),
            backgroundColor: AppColors.chipUnselectedBg,
            selectedColor: AppColors.chipSelectedBg,
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

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final workDate = DateTime.parse(item['workDate'] as String);
    final status = item['status'] as String;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.dateBadgeBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _weekdayAbbr(workDate),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${workDate.day}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.login,
                      size: 16,
                      color: status == 'Late'
                          ? AppColors.dangerRed
                          : AppColors.accentBlue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(item['checkInTime'] as String?),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '—',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.logout,
                      size: 16,
                      color: AppColors.successGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(item['checkOutTime'] as String?),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Tháng $_selectedMonth, $_selectedYear',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
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

  Widget _buildStatusPill(String status) {
    late final String label;
    late final Color bg;
    late final Color fg;

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
        label = 'Thiếu check-out';
        bg = AppColors.amberBg;
        fg = AppColors.amber;
        break;
      default:
        label = status;
        bg = AppColors.chipUnselectedBg;
        fg = AppColors.chipUnselectedText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.timer_outlined, color: Colors.white, size: 22),
                const SizedBox(height: 10),
                Text(
                  '${_totalHours}h',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Tổng giờ làm tháng',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.successGreen,
                  size: 22,
                ),
                const SizedBox(height: 10),
                Text(
                  '$_daysWorked/$_totalWorkdaysInMonth',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Ngày công đạt được',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedNavIndex,
      onTap: (index) {
        if (index == _selectedNavIndex) return;
        switch (index) {
          case 0:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const EmployeeHomeScreen()),
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
