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

enum _StatusFilter { all, active, suspended }

class _CompanyListScreenState extends State<CompanyListScreen> {
  List<Map<String, dynamic>> _companies = [];

  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  _StatusFilter _statusFilter = _StatusFilter.all;

  // AttendGo COLORS

  static const Color primary = Color(0xFF2864E8);
  static const Color primaryDark = Color(0xFF294477);

  static const Color background = Color(0xFFF1F5FF);
  static const Color card = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF294477);
  static const Color textSecondary = Color(0xFF687895);

  static const Color border = Color(0xFFC9D9FF);
  static const Color softBlue = Color(0xFFEAF0FF);

  // AVATAR PALETTE (cycled per company, like the reference design)
  static const List<Map<String, Color>> _avatarPalette = [
    {'bg': Color(0xFFEAF0FF), 'icon': Color(0xFF2864E8)}, // blue
    {'bg': Color(0xFFE7F8EF), 'icon': Color(0xFF16A34A)}, // green
    {'bg': Color(0xFFF3EAFE), 'icon': Color(0xFF9333EA)}, // purple
    {'bg': Color(0xFFFFF3E0), 'icon': Color(0xFFF08C1E)}, // orange
  ];

  @override
  void initState() {
    super.initState();
    _loadCompanies();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // LOAD COMPANIES
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

  // FILTERED LIST (search + status)
  List<Map<String, dynamic>> get _filteredCompanies {
    return _companies.where((company) {
      final name = (company['name']?.toString() ?? '').toLowerCase();
      final code = (company['companyCode']?.toString() ?? '').toLowerCase();
      final status = company['status']?.toString() ?? 'Active';

      final matchesSearch =
          _searchQuery.isEmpty ||
          name.contains(_searchQuery) ||
          code.contains(_searchQuery);

      final matchesStatus =
          _statusFilter == _StatusFilter.all ||
          (_statusFilter == _StatusFilter.active && status == 'Active') ||
          (_statusFilter == _StatusFilter.suspended && status != 'Active');

      return matchesSearch && matchesStatus;
    }).toList();
  }

  // CREATE COMPANY
  Future<void> _openCreateCompany() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateCompanyScreen()),
    );

    if (!mounted) return;

    _loadCompanies();
  }

  // COMPANY DETAIL
  Future<void> _openCompanyDetail(Map<String, dynamic> company) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CompanyDetailScreen(company: company)),
    );

    if (!mounted) return;

    _loadCompanies();
  }

  // CHANGE COMPANY STATUS
  Future<void> _changeCompanyStatus(Map<String, dynamic> company) async {
    final currentStatus = company['status']?.toString() ?? 'Active';

    final isActive = currentStatus == 'Active';

    final newStatus = isActive ? 'Suspended' : 'Active';

    final companyName = company['name']?.toString() ?? 'công ty này';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            isActive ? 'Tạm khóa công ty?' : 'Mở khóa công ty?',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          content: Text(
            isActive
                ? 'Công ty "$companyName" sẽ không thể đăng nhập '
                      'vào hệ thống cho đến khi được mở khóa.'
                : 'Bạn có chắc muốn mở khóa công ty '
                      '"$companyName" không?',
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: textSecondary,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Hủy',
                style: TextStyle(
                  color: textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
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

  // FILTER SHEET
  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<_StatusFilter>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        _StatusFilter selected = _statusFilter;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            Widget option(_StatusFilter value, String label, IconData icon) {
              final isSelected = selected == value;

              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  setSheetState(() => selected = value);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? softBlue : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isSelected ? primary : border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        size: 19,
                        color: isSelected ? primary : textSecondary,
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? primary : textPrimary,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 19,
                          color: primary,
                        ),
                    ],
                  ),
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                14,
                20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const Text(
                    'Lọc theo trạng thái',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  option(_StatusFilter.all, 'Tất cả', Icons.apps_rounded),
                  option(
                    _StatusFilter.active,
                    'Đang hoạt động',
                    Icons.check_circle_outline_rounded,
                  ),
                  option(
                    _StatusFilter.suspended,
                    'Tạm khóa',
                    Icons.lock_outline_rounded,
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(sheetContext, selected);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Áp dụng',
                        style: TextStyle(fontWeight: FontWeight.w700),
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

    if (result != null && mounted) {
      setState(() => _statusFilter = result);
    }
  }

  // SNACKBAR
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: background,
        foregroundColor: primaryDark,
        automaticallyImplyLeading: false,

        titleSpacing: 20,

        title: Row(
          children: [
            _buildRoundIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Quản lý công ty',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: primaryDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Danh sách và trạng thái các công ty',
                    style: TextStyle(fontSize: 11.5, color: textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildRoundIconButton(
              icon: Icons.refresh_rounded,
              onTap: _isLoading ? null : _loadCompanies,
            ),
          ],
        ),
      ),

      body: SafeArea(top: false, child: _buildBody()),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateCompany,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add_business_outlined),
        label: const Text(
          'Tạo công ty',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildRoundIconButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 19, color: primary),
        splashRadius: 20,
      ),
    );
  }

  // BODY
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: primary));
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_companies.isEmpty) {
      return _buildEmptyState();
    }

    final filtered = _filteredCompanies;

    return RefreshIndicator(
      color: primary,
      backgroundColor: Colors.white,
      onRefresh: _loadCompanies,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          _buildSummaryRow(),

          const SizedBox(height: 16),

          _buildSearchAndFilter(),

          const SizedBox(height: 18),

          const Text(
            'Danh sách công ty',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),

          const SizedBox(height: 12),

          if (filtered.isEmpty)
            _buildNoResultsState()
          else
            ...filtered.map(
              (company) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildCompanyCard(company),
              ),
            ),

          const SizedBox(height: 10),

          _buildResultsFooter(filtered.length),
        ],
      ),
    );
  }

  // SUMMARY ROW
  Widget _buildSummaryRow() {
    final total = _companies.length;

    final activeCount = _companies
        .where((company) => company['status']?.toString() == 'Active')
        .length;

    final suspendedCount = total - activeCount;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.business_outlined,
            title: 'Tổng số',
            value: total.toString(),
            iconColor: primary,
            iconBg: softBlue,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _buildSummaryCard(
            icon: Icons.check_circle_outline_rounded,
            title: 'Đang hoạt động',
            value: activeCount.toString(),
            iconColor: AppColors.successGreen,
            iconBg: const Color(0xFFEAF9F2),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _buildSummaryCard(
            icon: Icons.lock_outline_rounded,
            title: 'Tạm khóa',
            value: suspendedCount.toString(),
            iconColor: AppColors.dangerRed,
            iconBg: AppColors.dangerRedBg,
          ),
        ),
      ],
    );
  }

  // SUMMARY CARD
  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
    required Color iconBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),

      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,

            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),

            child: Icon(icon, size: 18, color: iconColor),
          ),

          const SizedBox(height: 11),

          Text(
            value,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // SEARCH + FILTER
  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    size: 19,
                    color: textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: textPrimary,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Tìm kiếm theo tên hoặc mã công ty...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    InkWell(
                      onTap: () => _searchController.clear(),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 17,
                        color: textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 10),

          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _openFilterSheet,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _statusFilter == _StatusFilter.all ? softBlue : primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.filter_list_rounded,
                    size: 18,
                    color: _statusFilter == _StatusFilter.all
                        ? primary
                        : Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Bộ lọc',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _statusFilter == _StatusFilter.all
                          ? primary
                          : Colors.white,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: _statusFilter == _StatusFilter.all
                        ? primary
                        : Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // COMPANY CARD
  Widget _buildCompanyCard(Map<String, dynamic> company) {
    final name = company['name']?.toString() ?? 'Chưa có tên';

    final code = company['companyCode']?.toString() ?? '';

    final address = company['address']?.toString() ?? '';

    final email = company['contactEmail']?.toString() ?? '';

    final phone = company['contactPhone']?.toString() ?? '';

    final status = company['status']?.toString() ?? 'Active';

    final isActive = status == 'Active';

    final paletteIndex = _companies.indexOf(company) % _avatarPalette.length;
    final avatarBg = _avatarPalette[paletteIndex]['bg']!;
    final avatarIconColor = _avatarPalette[paletteIndex]['icon']!;

    return Material(
      color: Colors.transparent,

      child: InkWell(
        borderRadius: BorderRadius.circular(20),

        onTap: () {
          _openCompanyDetail(company);
        },

        child: Ink(
          width: double.infinity,

          padding: const EdgeInsets.all(15),

          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(20),

            border: Border.all(color: border),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // COMPANY HEADER
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Container(
                    width: 46,
                    height: 46,

                    decoration: BoxDecoration(
                      color: avatarBg,
                      borderRadius: BorderRadius.circular(14),
                    ),

                    child: Icon(
                      Icons.business_rounded,
                      color: avatarIconColor,
                      size: 23,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,

                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),

                        const SizedBox(height: 4),

                        if (address.isNotEmpty)
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 12,
                                color: textSecondary,
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 6),

                  _buildStatusBadge(isActive),

                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: textSecondary,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    onSelected: (value) {
                      if (value == 'detail') {
                        _openCompanyDetail(company);
                      } else if (value == 'toggle') {
                        _changeCompanyStatus(company);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'detail',
                        child: Row(
                          children: [
                            Icon(
                              Icons.visibility_outlined,
                              size: 18,
                              color: textPrimary,
                            ),
                            SizedBox(width: 10),
                            Text('Xem chi tiết'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              isActive
                                  ? Icons.lock_outline_rounded
                                  : Icons.lock_open_rounded,
                              size: 18,
                              color: isActive
                                  ? AppColors.dangerRed
                                  : AppColors.successGreen,
                            ),
                            const SizedBox(width: 10),
                            Text(isActive ? 'Tạm khóa' : 'Mở khóa'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Container(height: 1, color: const Color(0xFFE5ECFA)),

              const SizedBox(height: 12),

              // MÃ CÔNG TY
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: softBlue,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      'Mã: $code',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // CONTACT INFORMATION
              if (email.isNotEmpty) _buildInfoRow(Icons.email_outlined, email),

              if (phone.isNotEmpty) ...[
                const SizedBox(height: 8),

                _buildInfoRow(Icons.phone_outlined, phone),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // STATUS BADGE
  Widget _buildStatusBadge(bool isActive) {
    return Container(
      margin: const EdgeInsets.only(right: 2),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),

      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFEAF9F2) : AppColors.dangerRedBg,

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

  // INFO ROW
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Icon(icon, size: 15, color: primary),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,

            style: const TextStyle(fontSize: 12, color: textSecondary),
          ),
        ),
      ],
    );
  }

  // RESULTS FOOTER
  Widget _buildResultsFooter(int shownCount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      alignment: Alignment.center,
      child: Text(
        'Hiển thị $shownCount trong ${_companies.length} công ty',
        style: const TextStyle(fontSize: 12, color: textSecondary),
      ),
    );
  }

  // NO SEARCH RESULTS
  Widget _buildNoResultsState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, size: 34, color: textSecondary),
          const SizedBox(height: 10),
          const Text(
            'Không tìm thấy công ty phù hợp',
            style: TextStyle(fontSize: 13, color: textSecondary),
          ),
        ],
      ),
    );
  }

  // ERROR STATE
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Container(
              width: 72,
              height: 72,

              decoration: BoxDecoration(
                color: softBlue,
                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.cloud_off_outlined,
                size: 34,
                color: primary,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Không thể tải danh sách công ty',
              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _errorMessage ?? 'Đã xảy ra lỗi không xác định.',
              textAlign: TextAlign.center,

              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: textSecondary,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _loadCompanies,

              icon: const Icon(Icons.refresh_rounded, size: 18),

              label: const Text('Thử lại'),

              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,

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

  // EMPTY STATE
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Container(
              width: 82,
              height: 82,

              decoration: BoxDecoration(
                color: softBlue,
                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.business_outlined,
                size: 40,
                color: primary,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Chưa có công ty nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),

            const SizedBox(height: 7),

            const Text(
              'Hãy tạo công ty đầu tiên để bắt đầu quản lý.',
              textAlign: TextAlign.center,

              style: TextStyle(fontSize: 13, color: textSecondary),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _openCreateCompany,

              icon: const Icon(Icons.add_business_outlined),

              label: const Text('Tạo công ty'),

              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,

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
