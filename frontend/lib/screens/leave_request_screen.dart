import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/auth_state.dart';

import 'employee_home_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

enum LeaveRequestStatus { accepted, pending, rejected }

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  static const List<String> _leaveTypes = [
    'Nghỉ ốm',
    'Nghỉ phép năm',
    'Việc riêng',
    'Không lương',
  ];

  String _selectedType = _leaveTypes.first;

  DateTime? _fromDate;
  DateTime? _toDate;

  final _reasonController = TextEditingController();

  bool _isSubmitting = false;
  bool _isLoadingRequests = true;

  List<dynamic> _recentRequests = [];

  @override
  void initState() {
    super.initState();
    _loadRecentRequests();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  // LOAD REQUESTS

  Future<void> _loadRecentRequests() async {
    setState(() {
      _isLoadingRequests = true;
    });

    final result = await ApiService.getList(
      '/api/leave-requests/me',
      bearerToken: AuthState.instance.token,
    );

    if (!mounted) return;

    setState(() {
      _isLoadingRequests = false;

      if (result.success) {
        _recentRequests = result.data!;
      }
    });
  }

  // DATE FORMAT

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'dd/mm/yyyy';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  // PICK DATE

  Future<void> _pickDate({required bool isFromDate}) async {
    final now = DateTime.now();

    final initialDate = (isFromDate ? _fromDate : _toDate) ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      if (isFromDate) {
        _fromDate = picked;

        // Nếu ngày bắt đầu lớn hơn ngày kết thúc
        // thì reset ngày kết thúc.
        if (_toDate != null && _toDate!.isBefore(picked)) {
          _toDate = null;
        }
      } else {
        _toDate = picked;
      }
    });
  }

  // SUBMIT

  Future<void> _handleSubmit() async {
    if (_fromDate == null || _toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn đầy đủ Từ ngày và Đến ngày.'),
        ),
      );

      return;
    }

    if (_toDate!.isBefore(_fromDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đến ngày phải sau hoặc bằng Từ ngày.')),
      );

      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final result = await ApiService.post('/api/leave-requests', {
      'type': _selectedType,
      'startDate': _fromDate!.toIso8601String(),
      'endDate': _toDate!.toIso8601String(),
      'reason': _reasonController.text.trim(),
    }, bearerToken: AuthState.instance.token);

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã gửi đơn nghỉ phép.'),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      _reasonController.clear();

      setState(() {
        _fromDate = null;
        _toDate = null;
        _selectedType = _leaveTypes.first;
      });

      _loadRecentRequests();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'Gửi đơn thất bại.')),
      );
    }
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
                color: AppColors.primaryBlue,
                onRefresh: _loadRecentRequests,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPageTitle(),

                      const SizedBox(height: 18),

                      _buildForm(),

                      const SizedBox(height: 28),

                      _buildRecentRequestsSection(),
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
          _buildLogoHeader(),

          const Spacer(),

          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.infoBoxBackground,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_outlined,
              color: AppColors.primaryBlue,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  // LOGO

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

  // PAGE TITLE

  Widget _buildPageTitle() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.infoBoxBackground,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.event_busy_outlined,
            color: AppColors.primaryBlue,
            size: 25,
          ),
        ),

        const SizedBox(width: 13),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Xin nghỉ phép',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),

              SizedBox(height: 3),

              Text(
                'Gửi yêu cầu nghỉ phép đến quản lý',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // FORM

  Widget _buildForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('LOẠI NGHỈ PHÉP'),

          const SizedBox(height: 8),

          _buildLeaveTypeDropdown(),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'TỪ NGÀY',
                  date: _fromDate,
                  isFromDate: true,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _buildDateField(
                  label: 'ĐẾN NGÀY',
                  date: _toDate,
                  isFromDate: false,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _buildFieldLabel('LÝ DO'),

          const SizedBox(height: 8),

          TextField(
            controller: _reasonController,
            maxLines: 4,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Nhập lý do nghỉ phép của bạn...',
              hintStyle: const TextStyle(
                color: Color(0xFFB0B3BD),
                fontSize: 13,
              ),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.primaryBlue,
                  width: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                disabledBackgroundColor: AppColors.primaryBlue.withOpacity(
                  0.55,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 21,
                      height: 21,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.4,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.send_outlined,
                          color: Colors.white,
                          size: 19,
                        ),

                        SizedBox(width: 8),

                        Text(
                          'Gửi đơn nghỉ phép',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // LEAVE TYPE DROPDOWN

  Widget _buildLeaveTypeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedType,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.textSecondary,
          ),
          items: _leaveTypes
              .map(
                (type) => DropdownMenuItem(
                  value: type,
                  child: Text(
                    type,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              _selectedType = value;
            });
          },
        ),
      ),
    );
  }

  // FIELD LABEL

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }

  // DATE FIELD

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required bool isFromDate,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),

        const SizedBox(height: 7),

        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _pickDate(isFromDate: isFromDate),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _formatDate(date),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: date == null
                          ? FontWeight.normal
                          : FontWeight.w600,
                      color: date == null
                          ? const Color(0xFFB0B3BD)
                          : AppColors.textPrimary,
                    ),
                  ),
                ),

                const Icon(
                  Icons.calendar_today_outlined,
                  size: 17,
                  color: AppColors.primaryBlue,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // RECENT REQUESTS

  Widget _buildRecentRequestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Đơn nghỉ phép gần đây',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 12),

        if (_isLoadingRequests)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            ),
          )
        else if (_recentRequests.isEmpty)
          _buildEmptyRequests()
        else
          ..._recentRequests.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildStatusCard(item as Map<String, dynamic>),
            ),
          ),
      ],
    );
  }

  // EMPTY REQUEST

  Widget _buildEmptyRequests() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.infoBoxBackground,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.description_outlined,
              color: AppColors.primaryBlue,
              size: 25,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'Chưa có đơn nghỉ phép nào.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // STATUS CARD

  Widget _buildStatusCard(Map<String, dynamic> item) {
    final status = item['status'] as String;

    late final IconData icon;
    late final Color iconColor;
    late final Color iconBg;
    late final String label;
    late final Color pillBg;
    late final Color pillFg;

    switch (status) {
      case 'Approved':
        icon = Icons.check_circle;
        iconColor = AppColors.successGreen;
        iconBg = AppColors.successGreenBg;
        label = 'Chấp nhận';
        pillBg = AppColors.successGreenBg;
        pillFg = AppColors.successGreen;
        break;

      case 'Rejected':
        icon = Icons.cancel;
        iconColor = AppColors.dangerRed;
        iconBg = AppColors.dangerRedBg;
        label = 'Từ chối';
        pillBg = AppColors.dangerRedBg;
        pillFg = AppColors.dangerRed;
        break;

      default:
        icon = Icons.access_time;
        iconColor = AppColors.pendingBlue;
        iconBg = AppColors.pendingBlueBg;
        label = 'Chờ duyệt';
        pillBg = AppColors.pendingBlueBg;
        pillFg = AppColors.pendingBlue;
    }

    final startDate = DateTime.parse(item['startDate'] as String);

    final endDate = DateTime.parse(item['endDate'] as String);

    final sameDay =
        startDate.day == endDate.day &&
        startDate.month == endDate.month &&
        startDate.year == endDate.year;

    final startLabel =
        '${startDate.day.toString().padLeft(2, '0')}/'
        '${startDate.month.toString().padLeft(2, '0')}/'
        '${startDate.year}';

    final endLabel =
        '${endDate.day.toString().padLeft(2, '0')}/'
        '${endDate.month.toString().padLeft(2, '0')}/'
        '${endDate.year}';

    final dateLabel = sameDay ? startLabel : '$startLabel - $endLabel';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 22),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['type'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  dateLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: pillBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: pillFg,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // BOTTOM NAVIGATION

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 2,

      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const EmployeeHomeScreen()),
            );
            break;

          case 1:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            );
            break;

          case 2:
            // Đang ở màn hình Yêu cầu.
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
          activeIcon: Icon(Icons.home),
          label: 'Trang chủ',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.history_outlined),
          activeIcon: Icon(Icons.history),
          label: 'Lịch sử',
        ),

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
