import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/auth_state.dart';
import 'company_detail_screen.dart';
import 'create_company_screen.dart';

class CompanyListScreen extends StatefulWidget {
  const CompanyListScreen({super.key});

  @override
  State<CompanyListScreen> createState() => _CompanyListScreenState();
}

class _CompanyListScreenState extends State<CompanyListScreen> {
  List<Map<String, dynamic>> _companies = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  // ============================================================
  // LOAD COMPANIES
  // ============================================================

  Future<void> _loadCompanies() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final result = await ApiService.getList(
      '/api/companies',
      bearerToken: AuthState.instance.token,
    );

    if (!mounted) return;

    if (result.success) {
      final rawList = result.data ?? <dynamic>[];

      final companies = rawList
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      setState(() {
        _companies = companies;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage =
            result.errorMessage ?? 'Không thể tải danh sách công ty.';
      });
    }
  }

  // ============================================================
  // CREATE COMPANY
  // ============================================================

  Future<void> _openCreateCompany() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateCompanyScreen()),
    );

    if (!mounted) return;

    // Sau khi tạo công ty xong → load lại danh sách
    _loadCompanies();
  }

  // ============================================================
  // COMPANY DETAIL
  // ============================================================

  Future<void> _openCompanyDetail(Map<String, dynamic> company) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CompanyDetailScreen(company: company)),
    );

    if (!mounted) return;

    // Detail có thể đã chỉnh sửa company
    _loadCompanies();
  }

  // ============================================================
  // CHANGE COMPANY STATUS
  // ============================================================

  Future<void> _changeCompanyStatus(Map<String, dynamic> company) async {
    final currentStatus = company['status']?.toString() ?? 'Active';

    final isActive = currentStatus == 'Active';

    final newStatus = isActive ? 'Suspended' : 'Active';

    final companyName = company['name']?.toString() ?? 'công ty này';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isActive ? 'Tạm khóa công ty?' : 'Mở khóa công ty?'),
          content: Text(
            isActive
                ? 'Công ty "$companyName" sẽ không thể đăng nhập '
                      'vào hệ thống cho đến khi được mở khóa.'
                : 'Bạn có chắc muốn mở khóa công ty '
                      '"$companyName" không?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive
                    ? AppColors.dangerRed
                    : AppColors.successGreen,
                foregroundColor: Colors.white,
              ),
              child: Text(isActive ? 'Tạm khóa' : 'Mở khóa'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final companyId = company['id']?.toString();

    if (companyId == null || companyId.isEmpty) {
      _showError('Không tìm thấy ID công ty.');
      return;
    }

    final result = await ApiService.put('/api/companies/$companyId/status', {
      'status': newStatus,
    }, bearerToken: AuthState.instance.token);

    if (!mounted) return;

    if (result.success) {
      _showSuccess(isActive ? 'Đã tạm khóa công ty.' : 'Đã mở khóa công ty.');

      await _loadCompanies();
    } else {
      _showError(
        result.errorMessage ?? 'Không thể thay đổi trạng thái công ty.',
      );
    }
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.dangerRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.cardBackground,
        foregroundColor: AppColors.primaryBlue,

        title: const Text(
          'Quản lý công ty',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),

        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadCompanies,
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh_rounded),
          ),

          const SizedBox(width: 4),

          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: _openCreateCompany,
              tooltip: 'Tạo công ty',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.add_rounded),
            ),
          ),
        ],
      ),

      body: SafeArea(child: _buildBody()),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_companies.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadCompanies,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          _buildHeader(),

          const SizedBox(height: 20),

          ..._companies.map(
            (company) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildCompanyCard(company),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    final total = _companies.length;

    final activeCount = _companies
        .where((company) => company['status']?.toString() == 'Active')
        .length;

    final suspendedCount = total - activeCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Danh sách công ty',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Quản lý thông tin và trạng thái các công ty',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.business_outlined,
                title: 'Tổng số',
                value: total.toString(),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _buildSummaryCard(
                icon: Icons.check_circle_outline,
                title: 'Hoạt động',
                value: activeCount.toString(),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _buildSummaryCard(
                icon: Icons.lock_outline,
                title: 'Tạm khóa',
                value: suspendedCount.toString(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primaryBlue),

          const SizedBox(height: 10),

          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COMPANY CARD
  // ============================================================

  Widget _buildCompanyCard(Map<String, dynamic> company) {
    final name = company['name']?.toString() ?? 'Chưa có tên';

    final code = company['companyCode']?.toString() ?? '';

    final address = company['address']?.toString() ?? '';

    final email = company['contactEmail']?.toString() ?? '';

    final phone = company['contactPhone']?.toString() ?? '';

    final status = company['status']?.toString() ?? 'Active';

    final isActive = status == 'Active';

    return Material(
      color: Colors.transparent,

      child: InkWell(
        borderRadius: BorderRadius.circular(18),

        onTap: () {
          _openCompanyDetail(company);
        },

        child: Container(
          width: double.infinity,

          padding: const EdgeInsets.all(18),

          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderColor),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // ------------------------------------------------
              // HEADER
              // ------------------------------------------------
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Container(
                    width: 50,
                    height: 50,

                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),

                    child: const Icon(
                      Icons.business_outlined,
                      color: AppColors.primaryBlue,
                      size: 25,
                    ),
                  ),

                  const SizedBox(width: 13),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,

                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          'Mã công ty: $code',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  _buildStatusBadge(isActive),
                ],
              ),

              const SizedBox(height: 16),

              const Divider(height: 1, color: AppColors.borderColor),

              const SizedBox(height: 14),

              // ------------------------------------------------
              // CONTACT INFO
              // ------------------------------------------------
              if (address.isNotEmpty)
                _buildInfoRow(Icons.location_on_outlined, address),

              if (email.isNotEmpty) ...[
                const SizedBox(height: 9),
                _buildInfoRow(Icons.email_outlined, email),
              ],

              if (phone.isNotEmpty) ...[
                const SizedBox(height: 9),
                _buildInfoRow(Icons.phone_outlined, phone),
              ],

              const SizedBox(height: 16),

              // ------------------------------------------------
              // ACTIONS
              // ------------------------------------------------
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _openCompanyDetail(company);
                      },

                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryBlue,

                        side: const BorderSide(color: AppColors.primaryBlue),

                        minimumSize: const Size.fromHeight(42),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),

                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.visibility_outlined, size: 18),
                          SizedBox(width: 7),
                          Text('Chi tiết'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _changeCompanyStatus(company);
                      },

                      style: OutlinedButton.styleFrom(
                        foregroundColor: isActive
                            ? AppColors.dangerRed
                            : AppColors.successGreen,

                        side: BorderSide(
                          color: isActive
                              ? AppColors.dangerRed
                              : AppColors.successGreen,
                        ),

                        minimumSize: const Size.fromHeight(42),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),

                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,

                        children: [
                          Icon(
                            isActive
                                ? Icons.lock_outline
                                : Icons.lock_open_outlined,
                            size: 18,
                          ),

                          const SizedBox(width: 7),

                          Text(isActive ? 'Tạm khóa' : 'Mở khóa'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ------------------------------------------------
              // VIEW DETAIL HINT
              // ------------------------------------------------
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  Text(
                    'Nhấn vào công ty để xem thông tin',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  SizedBox(width: 4),

                  Icon(
                    Icons.arrow_forward_ios,
                    size: 10,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),

      decoration: BoxDecoration(
        color: isActive ? AppColors.successGreenBg : AppColors.dangerRedBg,

        borderRadius: BorderRadius.circular(20),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,

            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AppColors.successGreen : AppColors.dangerRed,
            ),
          ),

          const SizedBox(width: 5),

          Text(
            isActive ? 'Hoạt động' : 'Tạm khóa',

            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isActive ? AppColors.successGreen : AppColors.dangerRed,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Icon(icon, size: 17, color: AppColors.textSecondary),

        const SizedBox(width: 9),

        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,

            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Container(
              width: 70,
              height: 70,

              decoration: BoxDecoration(
                color: AppColors.dangerRedBg,
                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.cloud_off_outlined,
                size: 34,
                color: AppColors.dangerRed,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Không thể tải danh sách công ty',
              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _errorMessage ?? 'Đã xảy ra lỗi không xác định.',
              textAlign: TextAlign.center,

              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _loadCompanies,

              icon: const Icon(Icons.refresh_rounded),

              label: const Text('Thử lại'),

              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,

                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Container(
              width: 80,
              height: 80,

              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.08),
                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.business_outlined,
                size: 40,
                color: AppColors.primaryBlue,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Chưa có công ty nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 7),

            const Text(
              'Hãy tạo công ty đầu tiên để bắt đầu quản lý.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _openCreateCompany,

              icon: const Icon(Icons.add_business_outlined),

              label: const Text('Tạo công ty'),

              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,

                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
