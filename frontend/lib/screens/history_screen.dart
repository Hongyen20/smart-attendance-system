import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum AttendanceStatus { onTime, late, earlyLeave, leave }

enum HistoryFilter { all, onTime, late, earlyLeave }

class AttendanceHistoryItem {
  final String weekdayAbbr; // "T2", "T3"...
  final int day;
  final String monthYearLabel; // "Tháng 10, 2023"
  final AttendanceStatus status;
  final String? checkInTime;
  final String? checkOutTime;
  final String? leaveNote; // use when status == leave

  const AttendanceHistoryItem({
    required this.weekdayAbbr,
    required this.day,
    required this.monthYearLabel,
    required this.status,
    this.checkInTime,
    this.checkOutTime,
    this.leaveNote,
  });
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedNavIndex = 1;
  HistoryFilter _selectedFilter = HistoryFilter.all;

  int _selectedMonth = 10;
  int _selectedYear = 2023;

  // TODO: thay bằng dữ liệu thật từ GET /api/attendance/history khi có backend
  final List<AttendanceHistoryItem> _items = const [
    AttendanceHistoryItem(
      weekdayAbbr: 'T2',
      day: 23,
      monthYearLabel: 'Tháng 10, 2023',
      status: AttendanceStatus.onTime,
      checkInTime: '08:00',
      checkOutTime: '17:05',
    ),
    AttendanceHistoryItem(
      weekdayAbbr: 'T3',
      day: 24,
      monthYearLabel: 'Tháng 10, 2023',
      status: AttendanceStatus.late,
      checkInTime: '08:45',
      checkOutTime: '17:02',
    ),
    AttendanceHistoryItem(
      weekdayAbbr: 'T4',
      day: 25,
      monthYearLabel: 'Tháng 10, 2023',
      status: AttendanceStatus.earlyLeave,
      checkInTime: '07:55',
      checkOutTime: '16:30',
    ),
    AttendanceHistoryItem(
      weekdayAbbr: 'T5',
      day: 26,
      monthYearLabel: 'Tháng 10, 2023',
      status: AttendanceStatus.onTime,
      checkInTime: '08:02',
      checkOutTime: '17:15',
    ),
    AttendanceHistoryItem(
      weekdayAbbr: 'T6',
      day: 27,
      monthYearLabel: 'Tháng 10, 2023',
      status: AttendanceStatus.leave,
      leaveNote: 'Đã được phê duyệt',
    ),
  ];

  List<AttendanceHistoryItem> get _filteredItems {
    switch (_selectedFilter) {
      case HistoryFilter.all:
        return _items;
      case HistoryFilter.onTime:
        return _items.where((e) => e.status == AttendanceStatus.onTime).toList();
      case HistoryFilter.late:
        return _items.where((e) => e.status == AttendanceStatus.late).toList();
      case HistoryFilter.earlyLeave:
        return _items.where((e) => e.status == AttendanceStatus.earlyLeave).toList();
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
              child: SingleChildScrollView(
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
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    _buildMonthSelector(),
                    const SizedBox(height: 16),
                    _buildFilterChips(),
                    const SizedBox(height: 16),
                    ..._filteredItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildHistoryCard(item),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryRow(),
                  ],
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
            onPressed: () {
              // TODO: navitigation to notification screen
            },
            icon: const Icon(Icons.notifications_none, color: AppColors.textPrimary),
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
            const Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tháng $_selectedMonth, $_selectedYear',
                style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Future<void> _openMonthYearPicker() async {
    int tempMonth = _selectedMonth;
    int tempYear = _selectedYear;
    final currentYear = DateTime.now().year;
    final years = List.generate(6, (i) => currentYear - 3 + i); // 3 years before -> 1 year later

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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
                          onChanged: (value) => setSheetState(() => tempMonth = value!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdownField<int>(
                          label: 'Năm',
                          value: tempYear,
                          items: years,
                          itemLabel: (y) => '$y',
                          onChanged: (value) => setSheetState(() => tempYear = value!),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedMonth = tempMonth;
                          _selectedYear = tempYear;
                        });
                        // TODO: recall GET /api/attendance/history?month=&year= with new value
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Áp dụng',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
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
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
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
              icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
              items: items
                  .map((item) => DropdownMenuItem<T>(
                        value: item,
                        child: Text(itemLabel(item)),
                      ))
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
      (HistoryFilter.earlyLeave, 'Về sớm'),
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

  Widget _buildHistoryCard(AttendanceHistoryItem item) {
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
                  item.weekdayAbbr,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                Text(
                  '${item.day}',
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
            child: item.status == AttendanceStatus.leave
                ? _buildLeaveContent(item)
                : _buildTimeContent(item),
          ),
          const SizedBox(width: 8),
          _buildStatusPill(item.status),
        ],
      ),
    );
  }

  Widget _buildTimeContent(AttendanceHistoryItem item) {
    final isLate = item.status == AttendanceStatus.late;
    final isEarlyLeave = item.status == AttendanceStatus.earlyLeave;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.login, size: 16, color: isLate ? AppColors.dangerRed : AppColors.accentBlue),
            const SizedBox(width: 4),
            Text(
              item.checkInTime ?? '--:--',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(width: 6),
            const Text('—', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(width: 6),
            Icon(Icons.logout, size: 16, color: isEarlyLeave ? AppColors.amber : AppColors.successGreen),
            const SizedBox(width: 4),
            Text(
              item.checkOutTime ?? '--:--',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          item.monthYearLabel,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildLeaveContent(AttendanceHistoryItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.flight_takeoff, size: 16, color: AppColors.textSecondary),
            SizedBox(width: 6),
            Text(
              'Nghỉ phép',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          item.leaveNote ?? '',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildStatusPill(AttendanceStatus status) {
    late final String label;
    late final Color bg;
    late final Color fg;

    switch (status) {
      case AttendanceStatus.onTime:
        label = 'Đúng giờ';
        bg = AppColors.successGreenBg;
        fg = AppColors.successGreen;
        break;
      case AttendanceStatus.late:
        label = 'Đi muộn';
        bg = AppColors.dangerRedBg;
        fg = AppColors.dangerRed;
        break;
      case AttendanceStatus.earlyLeave:
        label = 'Về sớm';
        bg = AppColors.amberBg;
        fg = AppColors.amber;
        break;
      case AttendanceStatus.leave:
        label = 'Phép';
        bg = AppColors.chipUnselectedBg;
        fg = AppColors.chipUnselectedText;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
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
                const Text(
                  '160h',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
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
                const Icon(Icons.check_circle_outline, color: AppColors.successGreen, size: 22),
                const SizedBox(height: 10),
                const Text(
                  '22/22',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Ngày công đạt được',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
        setState(() => _selectedNavIndex = index);
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primaryBlue,
      unselectedItemColor: AppColors.textSecondary,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Trang chủ'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Lịch sử'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: 'Thống kê'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}