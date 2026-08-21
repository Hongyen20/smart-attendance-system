import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/auth_state.dart';
import 'ip_config_form_screen.dart';

class IpConfigScreen extends StatefulWidget {
  const IpConfigScreen({super.key});

  @override
  State<IpConfigScreen> createState() => _IpConfigScreenState();
}

class _IpConfigScreenState extends State<IpConfigScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _configs = [];

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService.getList('/api/ip-configs', bearerToken: AuthState.instance.token);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result.success) {
        _configs = result.data!;
      } else {
        _errorMessage = result.errorMessage;
      }
    });
  }

  Future<void> _handleDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa cấu hình IP?'),
        content: const Text('Nhân viên sẽ không thể check-in bằng IP này nữa sau khi xóa.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: AppColors.dangerRed)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await ApiService.delete('/api/ip-configs/$id', bearerToken: AuthState.instance.token);
    if (result.success) {
      _loadConfigs();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'Xóa thất bại.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cấu hình IP'),
        backgroundColor: AppColors.cardBackground,
        foregroundColor: AppColors.primaryBlue,
        elevation: 0,
      ),
      body: RefreshIndicator(onRefresh: _loadConfigs, child: _buildBody()),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const IpConfigFormScreen()),
          );
          if (created == true) _loadConfigs();
        },
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm IP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          const SizedBox(height: 40),
          const Icon(Icons.error_outline, color: AppColors.dangerRed, size: 40),
          const SizedBox(height: 12),
          Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.dangerRed)),
        ],
      );
    }

    if (_configs.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          SizedBox(height: 60),
          Icon(Icons.wifi_off, color: AppColors.textSecondary, size: 48),
          SizedBox(height: 12),
          Text(
            'Chưa có cấu hình IP nào. Nhân viên sẽ không check-in được cho tới khi thêm ít nhất 1 cấu hình.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
      itemCount: _configs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final c = _configs[index] as Map<String, dynamic>;
        return _buildConfigCard(c);
      },
    );
  }

  Widget _buildConfigCard(Map<String, dynamic> c) {
    final isActive = c['isActive'] == true;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isActive ? AppColors.successGreenBg : AppColors.dangerRedBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.public,
              color: isActive ? AppColors.successGreen : AppColors.dangerRed,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c['allowedIp'] ?? '',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                Text(
                  'Bán kính ${c['radiusMeters']}m',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            onSelected: (value) async {
              if (value == 'edit') {
                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => IpConfigFormScreen(existingConfig: c)),
                );
                if (updated == true) _loadConfigs();
              } else if (value == 'delete') {
                _handleDelete(c['id'] as String);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Sửa')),
              PopupMenuItem(value: 'delete', child: Text('Xóa', style: TextStyle(color: AppColors.dangerRed))),
            ],
          ),
        ],
      ),
    );
  }
}