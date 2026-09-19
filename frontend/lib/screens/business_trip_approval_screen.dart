import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/auth_state.dart';

class BusinessTripApprovalScreen extends StatefulWidget {
  const BusinessTripApprovalScreen({super.key});

  @override
  State<BusinessTripApprovalScreen> createState() =>
      _BusinessTripApprovalScreenState();
}

class _BusinessTripApprovalScreenState
    extends State<BusinessTripApprovalScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  List<dynamic> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService.getList(
      '/api/business-trip-requests/pending',
      bearerToken: AuthState.instance.token,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;

      if (result.success) {
        _requests = result.data ?? [];
      } else {
        _errorMessage = result.errorMessage;
      }
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _approveRequest(Map<String, dynamic> request) async {
    final id = request['id']?.toString();

    if (id == null || id.isEmpty) {
      _showMessage('Không xác định được yêu cầu.');
      return;
    }

    final confirmed = await _showConfirmDialog(
      title: 'Duyệt yêu cầu',
      message:
          'Bạn có chắc muốn duyệt yêu cầu đi công tác của '
          '${request['employeeName'] ?? request['employeeUsername'] ?? 'nhân viên này'}?',
      confirmText: 'Duyệt',
      confirmColor: AppColors.successGreen,
    );

    if (!confirmed) return;

    await _updateRequestStatus(
      id: id,
      action: 'approve',
      successMessage: 'Đã duyệt yêu cầu đi công tác.',
    );
  }

  Future<void> _rejectRequest(Map<String, dynamic> request) async {
    final id = request['id']?.toString();

    if (id == null || id.isEmpty) {
      _showMessage('Không xác định được yêu cầu.');
      return;
    }

    final confirmed = await _showConfirmDialog(
      title: 'Từ chối yêu cầu',
      message:
          'Bạn có chắc muốn từ chối yêu cầu đi công tác của '
          '${request['employeeName'] ?? request['employeeUsername'] ?? 'nhân viên này'}?',
      confirmText: 'Từ chối',
      confirmColor: AppColors.dangerRed,
    );

    if (!confirmed) return;

    await _updateRequestStatus(
      id: id,
      action: 'reject',
      successMessage: 'Đã từ chối yêu cầu đi công tác.',
    );
  }

  Future<void> _updateRequestStatus({
    required String id,
    required String action,
    required String successMessage,
  }) async {
    final result = await ApiService.put(
      '/api/business-trip-requests/$id/$action',
      {},
      bearerToken: AuthState.instance.token,
    );

    if (!mounted) return;

    if (result.success) {
      _showMessage(successMessage);

      await _loadRequests();
    } else {
      _showMessage(result.errorMessage ?? 'Không thể cập nhật yêu cầu.');
    }
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Hủy',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                confirmText,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Duyệt đơn đi công tác'),
        backgroundColor: AppColors.cardBackground,
        foregroundColor: AppColors.primaryBlue,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadRequests,
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(onRefresh: _loadRequests, child: _buildBody()),
      ),
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
          _buildErrorBox(),
          const SizedBox(height: 12),
          SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _loadRequests,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (_requests.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 100),
          Icon(
            Icons.assignment_turned_in_outlined,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Không có yêu cầu đi công tác nào đang chờ duyệt.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        _buildSummaryHeader(),
        const SizedBox(height: 16),
        ..._requests.map((item) {
          final request = Map<String, dynamic>.from(item as Map);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildRequestCard(request),
          );
        }),
      ],
    );
  }

  Widget _buildSummaryHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.infoBoxBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.business_center_outlined,
              color: AppColors.accentBlue,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Yêu cầu đang chờ duyệt',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_requests.length} yêu cầu',
                  style: const TextStyle(
                    fontSize: 12,
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

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final employeeName = request['employeeName']?.toString().trim();

    final employeeUsername = request['employeeUsername']?.toString().trim();

    final destination = request['destination']?.toString() ?? '';

    final reason = request['reason']?.toString().trim() ?? '';

    final startDate = _parseDate(request['startDate']);

    final endDate = _parseDate(request['endDate']);

    return Container(
      width: double.infinity,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: AppColors.primaryBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employeeName?.isNotEmpty == true
                          ? employeeName!
                          : 'Nhân viên',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (employeeUsername?.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Text(
                        '@$employeeUsername',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _buildPendingBadge(),
            ],
          ),

          const SizedBox(height: 16),

          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Thời gian',
            value: startDate != null && endDate != null
                ? '${_formatDate(startDate)} - ${_formatDate(endDate)}'
                : 'Không xác định',
          ),

          const SizedBox(height: 10),

          _buildInfoRow(
            icon: Icons.location_on_outlined,
            label: 'Địa điểm',
            value: destination.isEmpty ? 'Không có thông tin' : destination,
          ),

          if (reason.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildInfoRow(
              icon: Icons.notes_outlined,
              label: 'Lý do',
              value: reason,
            ),
          ],

          const SizedBox(height: 16),

          const Divider(height: 1, color: AppColors.borderColor),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _rejectRequest(request),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Từ chối'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.dangerRed,
                    side: const BorderSide(color: AppColors.dangerRed),
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _approveRequest(request),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Duyệt'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.successGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.pendingBlueBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Chờ duyệt',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.pendingBlue,
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.dangerRedBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _errorMessage ?? 'Đã xảy ra lỗi.',
        style: const TextStyle(color: AppColors.dangerRed, fontSize: 13),
      ),
    );
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }
}
