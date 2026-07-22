import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum LeaveRequestStatus { accepted, pending, rejected }

class LeaveRequestStatusItem {
  final String title;
  final String dateRangeLabel;
  final LeaveRequestStatus status;

  const LeaveRequestStatusItem({
    required this.title,
    required this.dateRangeLabel,
    required this.status,
  });
}

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

  // TODO: thay bằng dữ liệu thật từ GET /api/leave-requests/me khi có backend
  final List<LeaveRequestStatusItem> _recentRequests = const [
    LeaveRequestStatusItem(
      title: 'Nghỉ phép năm',
      dateRangeLabel: '12/10/2023 - 14/10/2023',
      status: LeaveRequestStatus.accepted,
    ),
    LeaveRequestStatusItem(
      title: 'Nghỉ ốm',
      dateRangeLabel: '25/10/2023',
      status: LeaveRequestStatus.pending,
    ),
    LeaveRequestStatusItem(
      title: 'Việc riêng',
      dateRangeLabel: '05/11/2023',
      status: LeaveRequestStatus.rejected,
    ),
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'mm/dd/yyyy';
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '$mm/$dd/${date.year}';
  }

  Future<void> _pickDate({required bool isFromDate}) async {
    final now = DateTime.now();
    final initial = (isFromDate ? _fromDate : _toDate) ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

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

    setState(() => _isSubmitting = true);
    // TODO: call POST /api/leave-requests với { type, startDate, endDate, reason }
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() => _isSubmitting = false);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã gửi đơn nghỉ phép.')));
      Navigator.pop(context);
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
                    _buildForm(),
                    const SizedBox(height: 28),
                    const Text(
                      'Trạng thái đơn gần đây',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._recentRequests.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildStatusCard(item),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(bottom: BorderSide(color: AppColors.borderColor)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: AppColors.accentBlue),
          ),
          const Text(
            'Gửi Đơn Nghỉ Phép',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.accentBlue,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              // TODO: navitigation to notification screen
            },
            icon: const Icon(
              Icons.notifications_none,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('LOẠI NGHỈ PHÉP'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
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
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'TỪ NGÀY',
                  date: _fromDate,
                  isFromDate: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateField(
                  label: 'ĐẾN NGÀY',
                  date: _toDate,
                  isFromDate: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildFieldLabel('LÝ DO'),
          const SizedBox(height: 8),
          TextField(
            controller: _reasonController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Nhập lý do nghỉ phép của bạn...',
              hintStyle: const TextStyle(color: Color(0xFFB0B3BD)),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.accentBlue,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.4,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Gửi Đơn',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required bool isFromDate,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _pickDate(isFromDate: isFromDate),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _formatDate(date),
                    style: TextStyle(
                      color: date == null
                          ? const Color(0xFFB0B3BD)
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(LeaveRequestStatusItem item) {
    late final IconData icon;
    late final Color iconColor;
    late final Color iconBg;
    late final String label;
    late final Color pillBg;
    late final Color pillFg;

    switch (item.status) {
      case LeaveRequestStatus.accepted:
        icon = Icons.check_circle;
        iconColor = AppColors.successGreen;
        iconBg = AppColors.successGreenBg;
        label = 'Chấp nhận';
        pillBg = AppColors.successGreenBg;
        pillFg = AppColors.successGreen;
        break;
      case LeaveRequestStatus.pending:
        icon = Icons.access_time;
        iconColor = AppColors.pendingBlue;
        iconBg = AppColors.pendingBlueBg;
        label = 'Chờ duyệt';
        pillBg = AppColors.pendingBlueBg;
        pillFg = AppColors.pendingBlue;
        break;
      case LeaveRequestStatus.rejected:
        icon = Icons.cancel;
        iconColor = AppColors.dangerRed;
        iconBg = AppColors.dangerRedBg;
        label = 'Từ chối';
        pillBg = AppColors.dangerRedBg;
        pillFg = AppColors.dangerRed;
        break;
    }

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
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.dateRangeLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: pillBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: pillFg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
