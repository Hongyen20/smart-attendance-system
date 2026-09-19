import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/auth_state.dart';

class BusinessTripRequestScreen extends StatefulWidget {
  const BusinessTripRequestScreen({super.key});

  @override
  State<BusinessTripRequestScreen> createState() =>
      _BusinessTripRequestScreenState();
}

class _BusinessTripRequestScreenState extends State<BusinessTripRequestScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  final _destinationController = TextEditingController();
  final _reasonController = TextEditingController();

  bool _isLoadingHistory = true;
  List<dynamic> _history = [];

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final result = await ApiService.getList(
      '/api/business-trip-requests/me',
      bearerToken: AuthState.instance.token,
    );
    if (!mounted) return;
    setState(() {
      _isLoadingHistory = false;
      if (result.success) _history = result.data!;
    });
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = (isStart ? _startDate : _endDate) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_startDate == null || _endDate == null) {
      setState(
        () => _errorMessage = 'Vui lòng chọn đầy đủ Từ ngày và Đến ngày.',
      );
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      setState(() => _errorMessage = 'Đến ngày phải sau hoặc bằng Từ ngày.');
      return;
    }
    if (_destinationController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập địa điểm công tác.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final result = await ApiService.post('/api/business-trip-requests', {
      'startDate': _startDate!.toIso8601String(),
      'endDate': _endDate!.toIso8601String(),
      'destination': _destinationController.text.trim(),
      'reason': _reasonController.text.trim(),
    }, bearerToken: AuthState.instance.token);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi yêu cầu đi công tác.')),
      );
      setState(() {
        _startDate = null;
        _endDate = null;
        _destinationController.clear();
        _reasonController.clear();
      });
      _loadHistory();
    } else {
      setState(() => _errorMessage = result.errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Yêu cầu đi công tác'),
        backgroundColor: AppColors.cardBackground,
        foregroundColor: AppColors.primaryBlue,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.infoBoxBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.accentBlue,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Nếu yêu cầu được duyệt, các ngày công tác sẽ bỏ qua xác thực IP/GPS khi check-in - vẫn tính đủ công.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildForm(),
              const SizedBox(height: 24),
              const Text(
                'Lịch sử yêu cầu',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildHistory(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
              Expanded(
                child: _buildDateField(
                  label: 'TỪ NGÀY',
                  date: _startDate,
                  isStart: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateField(
                  label: 'ĐẾN NGÀY',
                  date: _endDate,
                  isStart: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFieldLabel('ĐỊA ĐIỂM CÔNG TÁC'),
          const SizedBox(height: 8),
          TextField(
            controller: _destinationController,
            decoration: _inputDecoration(hint: 'VD: Chi nhánh Đà Nẵng'),
          ),
          const SizedBox(height: 16),
          _buildFieldLabel('LÝ DO (nếu cần)'),
          const SizedBox(height: 8),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            decoration: _inputDecoration(hint: 'Nhập lý do đi công tác...'),
          ),
          const SizedBox(height: 16),
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.dangerRedBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: AppColors.dangerRed,
                  fontSize: 13,
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.4,
                      ),
                    )
                  : const Text(
                      'Gửi yêu cầu',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
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

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
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
        borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.5),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required bool isStart,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _pickDate(isStart: isStart),
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
                    date == null ? 'Chọn ngày' : _formatDate(date),
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

  Widget _buildHistory() {
    if (_isLoadingHistory) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_history.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'Chưa có yêu cầu nào.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Column(
      children: _history.map((item) {
        final r = item as Map<String, dynamic>;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildHistoryCard(r),
        );
      }).toList(),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> r) {
    final status = r['status'] as String;
    late final String label;
    late final Color bg;
    late final Color fg;
    switch (status) {
      case 'Approved':
        label = 'Đã duyệt';
        bg = AppColors.successGreenBg;
        fg = AppColors.successGreen;
        break;
      case 'Rejected':
        label = 'Từ chối';
        bg = AppColors.dangerRedBg;
        fg = AppColors.dangerRed;
        break;
      default:
        label = 'Chờ duyệt';
        bg = AppColors.pendingBlueBg;
        fg = AppColors.pendingBlue;
    }

    final start = DateTime.parse(r['startDate'] as String);
    final end = DateTime.parse(r['endDate'] as String);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r['destination'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatDate(start)} - ${_formatDate(end)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
