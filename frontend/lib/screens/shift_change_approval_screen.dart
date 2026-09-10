import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/auth_state.dart';

class ShiftChangeApprovalScreen extends StatefulWidget {
  const ShiftChangeApprovalScreen({super.key});

  @override
  State<ShiftChangeApprovalScreen> createState() => _ShiftChangeApprovalScreenState();
}

class _ShiftChangeApprovalScreenState extends State<ShiftChangeApprovalScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _pendingRequests = [];
  final Set<String> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  Future<void> _loadPending() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService.getList('/api/shift-change-requests/pending', bearerToken: AuthState.instance.token);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result.success) {
        _pendingRequests = result.data!;
      } else {
        _errorMessage = result.errorMessage;
      }
    });
  }

  Future<void> _handleDecision(String id, bool approve) async {
    setState(() => _processingIds.add(id));

    final result = await ApiService.put(
      '/api/shift-change-requests/$id/${approve ? 'approve' : 'reject'}',
      {},
      bearerToken: AuthState.instance.token,
    );

    if (!mounted) return;

    setState(() => _processingIds.remove(id));

    if (result.success) {
      setState(() => _pendingRequests.removeWhere((r) => r['id'] == id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approve ? 'Đã duyệt - ca làm việc mới đã được áp dụng.' : 'Đã từ chối - ca hiện tại giữ nguyên.'),
          backgroundColor: approve ? AppColors.successGreen : AppColors.dangerRed,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'Thao tác thất bại.')),
      );
    }
  }

  String _formatDate(String iso) {
    final d = DateTime.parse(iso);
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Duyệt yêu cầu đổi ca'),
        backgroundColor: AppColors.cardBackground,
        foregroundColor: AppColors.primaryBlue,
        elevation: 0,
      ),
      body: RefreshIndicator(onRefresh: _loadPending, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.error_outline, color: AppColors.dangerRed, size: 40),
          const SizedBox(height: 12),
          Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.dangerRed)),
        ],
      );
    }

    if (_pendingRequests.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          SizedBox(height: 60),
          Icon(Icons.schedule_outlined, color: AppColors.textSecondary, size: 48),
          SizedBox(height: 12),
          Center(child: Text('Không có yêu cầu nào đang chờ duyệt.', style: TextStyle(color: AppColors.textSecondary))),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      itemCount: _pendingRequests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final r = _pendingRequests[index] as Map<String, dynamic>;
        return _buildRequestCard(r);
      },
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> r) {
    final id = r['id'] as String;
    final isProcessing = _processingIds.contains(id);
    final type = r['requestedShiftType'] as String;
    final typeLabel = type == 'Flexible' ? 'Linh hoạt (Flexible)' : 'Cố định';

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
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.infoBoxBackground,
                child: Text(
                  ((r['employeeName'] as String?)?.isNotEmpty == true) ? r['employeeName'][0].toUpperCase() : '?',
                  style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r['employeeName'] ?? 'Không rõ',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    Text(r['employeeCode'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppColors.pendingBlueBg, borderRadius: BorderRadius.circular(20)),
                child: Text(typeLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.pendingBlue)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text('Áp dụng từ ${_formatDate(r['effectiveDate'] as String)}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text('${r['requestedStartTime']} - ${r['requestedEndTime']} (${r['requestedHours']} giờ)',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
          if ((r['reason'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(r['reason'], style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isProcessing ? null : () => _handleDecision(id, false),
                  icon: const Icon(Icons.close, size: 18, color: AppColors.dangerRed),
                  label: const Text('Từ chối', style: TextStyle(color: AppColors.dangerRed)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.dangerRed),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isProcessing ? null : () => _handleDecision(id, true),
                  icon: isProcessing
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check, size: 18, color: Colors.white),
                  label: const Text('Duyệt', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.successGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}