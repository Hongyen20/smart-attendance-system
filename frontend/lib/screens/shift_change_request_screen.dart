import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/auth_state.dart';

class ShiftChangeRequestScreen extends StatefulWidget {
  const ShiftChangeRequestScreen({super.key});

  @override
  State<ShiftChangeRequestScreen> createState() => _ShiftChangeRequestScreenState();
}

class _ShiftChangeRequestScreenState extends State<ShiftChangeRequestScreen> {
  static const List<String> _shiftTypes = ['Fixed', 'Flexible'];
  static const Map<String, String> _shiftTypeLabels = {
    'Fixed': 'Cố định',
    'Flexible': 'Linh hoạt (Flexible Time)',
  };

  String _selectedType = 'Fixed';
  DateTime? _effectiveDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final _reasonController = TextEditingController();

  bool _isLoadingCurrent = true;
  Map<String, dynamic>? _currentProfile;

  bool _isLoadingHistory = true;
  List<dynamic> _history = [];

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCurrentShift();
    _loadHistory();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentShift() async {
    final result = await ApiService.get('/api/users/me', bearerToken: AuthState.instance.token);
    if (!mounted) return;
    setState(() {
      _isLoadingCurrent = false;
      if (result.success) _currentProfile = result.data;
    });
  }

  Future<void> _loadHistory() async {
    final result = await ApiService.getList('/api/shift-change-requests/me', bearerToken: AuthState.instance.token);
    if (!mounted) return;
    setState(() {
      _isLoadingHistory = false;
      if (result.success) _history = result.data!;
    });
  }

  double? get _computedHours {
    if (_startTime == null || _endTime == null) return null;
    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    final diff = endMinutes - startMinutes;
    if (diff <= 0) return null;
    return diff / 60;
  }

  String _formatTimeOfDay(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _effectiveDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) setState(() => _effectiveDate = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isStart ? _startTime : _endTime) ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_effectiveDate == null) {
      setState(() => _errorMessage = 'Vui lòng chọn ngày áp dụng.');
      return;
    }
    if (_startTime == null || _endTime == null) {
      setState(() => _errorMessage = 'Vui lòng chọn giờ bắt đầu và kết thúc.');
      return;
    }
    if (_computedHours == null) {
      setState(() => _errorMessage = 'Giờ kết thúc phải sau giờ bắt đầu.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final result = await ApiService.post(
      '/api/shift-change-requests',
      {
        'effectiveDate': _effectiveDate!.toIso8601String(),
        'requestedShiftType': _selectedType,
        'requestedStartTime': _formatTimeOfDay(_startTime!),
        'requestedEndTime': _formatTimeOfDay(_endTime!),
        'reason': _reasonController.text.trim(),
      },
      bearerToken: AuthState.instance.token,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi yêu cầu đổi ca.')),
      );
      setState(() {
        _effectiveDate = null;
        _startTime = null;
        _endTime = null;
        _selectedType = 'Fixed';
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
        title: const Text('Yêu cầu đổi ca làm việc'),
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
              _buildCurrentShiftCard(),
              const SizedBox(height: 16),
              _buildForm(),
              const SizedBox(height: 24),
              const Text(
                'Lịch sử yêu cầu',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              _buildHistory(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentShiftCard() {
    if (_isLoadingCurrent) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_currentProfile == null) return const SizedBox.shrink();

    final type = _currentProfile!['currentShiftType'] as String? ?? 'Fixed';
    final start = _currentProfile!['currentShiftStart'] as String? ?? '--:--';
    final end = _currentProfile!['currentShiftEnd'] as String? ?? '--:--';
    final hours = _currentProfile!['currentShiftHours'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.infoBoxBackground, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ca làm việc hiện tại',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text(
            type == 'Flexible' ? 'Linh hoạt - $hours giờ/ngày' : 'Cố định - $start đến $end ($hours giờ)',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
          ),
        ],
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
          _buildFieldLabel('LOẠI CA LÀM VIỆC'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderColor)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedType,
                isExpanded: true,
                items: _shiftTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(_shiftTypeLabels[t] ?? t)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildFieldLabel('NGÀY ÁP DỤNG'),
          const SizedBox(height: 8),
          _buildPickerField(
            value: _effectiveDate == null
                ? 'Chọn ngày'
                : '${_effectiveDate!.day.toString().padLeft(2, '0')}/${_effectiveDate!.month.toString().padLeft(2, '0')}/${_effectiveDate!.year}',
            icon: Icons.calendar_today_outlined,
            onTap: _pickDate,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('GIỜ BẮT ĐẦU'),
                    const SizedBox(height: 8),
                    _buildPickerField(
                      value: _startTime == null ? '--:--' : _formatTimeOfDay(_startTime!),
                      icon: Icons.access_time,
                      onTap: () => _pickTime(isStart: true),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('GIỜ KẾT THÚC'),
                    const SizedBox(height: 8),
                    _buildPickerField(
                      value: _endTime == null ? '--:--' : _formatTimeOfDay(_endTime!),
                      icon: Icons.access_time,
                      onTap: () => _pickTime(isStart: false),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _computedHours != null
                ? 'Tổng số giờ làm việc: ${_computedHours!.toStringAsFixed(1)} giờ'
                : 'Tổng số giờ làm việc: --',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 16),
          _buildFieldLabel('LÝ DO (nếu cần)'),
          const SizedBox(height: 8),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Nhập lý do đổi ca...',
              hintStyle: const TextStyle(color: Color(0xFFB0B3BD)),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.5)),
            ),
          ),
          const SizedBox(height: 16),
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.dangerRedBg, borderRadius: BorderRadius.circular(12)),
              child: Text(_errorMessage!, style: const TextStyle(color: AppColors.dangerRed, fontSize: 13)),
            ),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4))
                  : const Text('Gửi yêu cầu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5));
  }

  Widget _buildPickerField({required String value, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderColor)),
        child: Row(
          children: [
            Expanded(child: Text(value, style: const TextStyle(color: AppColors.textPrimary))),
            Icon(icon, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory() {
    if (_isLoadingHistory) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: CircularProgressIndicator()));
    }
    if (_history.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: Text('Chưa có yêu cầu nào.', style: TextStyle(color: AppColors.textSecondary))),
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

    final type = r['requestedShiftType'] as String;
    final typeLabel = type == 'Flexible' ? 'Linh hoạt' : 'Cố định';

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
                Text('$typeLabel - ${r['requestedStartTime']} đến ${r['requestedEndTime']}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text('${r['requestedHours']} giờ/ngày', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
            child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
          ),
        ],
      ),
    );
  }
}