import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/auth_state.dart';

class IpConfigFormScreen extends StatefulWidget {
  final Map<String, dynamic>? existingConfig;

  const IpConfigFormScreen({super.key, this.existingConfig});

  @override
  State<IpConfigFormScreen> createState() => _IpConfigFormScreenState();
}

class _IpConfigFormScreenState extends State<IpConfigFormScreen> {
  late final TextEditingController _ipController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  late final TextEditingController _radiusController;

  bool _isDetectingIp = false;
  bool _isDetectingLocation = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.existingConfig != null;

  @override
  void initState() {
    super.initState();
    final c = widget.existingConfig;
    _ipController = TextEditingController(text: c?['allowedIp'] ?? '');
    _latController = TextEditingController(
      text: c != null ? '${c['lat']}' : '',
    );
    _lngController = TextEditingController(
      text: c != null ? '${c['lng']}' : '',
    );
    _radiusController = TextEditingController(
      text: c != null ? '${c['radiusMeters']}' : '100',
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _detectCurrentIp() async {
    setState(() => _isDetectingIp = true);

    final result = await ApiService.get(
      '/api/utils/current-ip',
      bearerToken: AuthState.instance.token,
    );

    if (!mounted) return;
    setState(() => _isDetectingIp = false);

    if (result.success) {
      setState(() => _ipController.text = result.data!['ip'] as String);
      _showSnack('Đã lấy IP hiện tại.');
    } else {
      _showSnack(result.errorMessage ?? 'Không lấy được IP.');
    }
  }

  Future<void> _detectCurrentLocation() async {
    setState(() => _isDetectingLocation = true);

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showSnack('Cần cấp quyền vị trí để lấy tọa độ hiện tại.');
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Vui lòng bật định vị (GPS) trên thiết bị.');
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _latController.text = position.latitude.toStringAsFixed(6);
        _lngController.text = position.longitude.toStringAsFixed(6);
      });
      _showSnack('Đã lấy vị trí hiện tại.');
    } catch (e) {
      _showSnack('Không lấy được vị trí: $e');
    } finally {
      if (mounted) setState(() => _isDetectingLocation = false);
    }
  }

  Future<void> _handleSubmit() async {
    final ip = _ipController.text.trim();
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    final radius = double.tryParse(_radiusController.text.trim());

    if (ip.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập địa chỉ IP.');
      return;
    }
    if (lat == null || lng == null) {
      setState(() => _errorMessage = 'Vĩ độ/kinh độ không hợp lệ.');
      return;
    }
    if (radius == null || radius <= 0) {
      setState(() => _errorMessage = 'Bán kính phải là số dương.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final body = {
      'allowedIp': ip,
      'lat': lat,
      'lng': lng,
      'radiusMeters': radius,
    };

    final result = _isEditing
        ? await ApiService.put(
            '/api/ip-configs/${widget.existingConfig!['id']}',
            {...body, 'isActive': widget.existingConfig!['isActive'] ?? true},
            bearerToken: AuthState.instance.token,
          )
        : await ApiService.post(
            '/api/ip-configs',
            body,
            bearerToken: AuthState.instance.token,
          );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.success) {
      Navigator.pop(context, true);
    } else {
      setState(() => _errorMessage = result.errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa cấu hình IP' : 'Thêm cấu hình IP'),
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
              Row(
                children: [
                  Expanded(
                    child: _buildDetectButton(
                      icon: Icons.public,
                      label: 'Lấy IP hiện tại',
                      isLoading: _isDetectingIp,
                      onPressed: _detectCurrentIp,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Đứng trong khu vực công ty (kết nối đúng mạng cần cấu hình) rồi bấm để lấy IP công cộng hiện tại.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              Container(
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
                    _buildTextField(
                      controller: _ipController,
                      label: 'Địa chỉ IP',
                      hint: '118.70.12.34',
                    ),
                    const SizedBox(height: 16),
                    _buildDetectButton(
                      icon: Icons.my_location,
                      label: 'Lấy vị trí hiện tại (GPS)',
                      isLoading: _isDetectingLocation,
                      onPressed: _detectCurrentLocation,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _latController,
                            label: 'Vĩ độ (lat)',
                            hint: '10.7769',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _lngController,
                            label: 'Kinh độ (lng)',
                            hint: '106.7009',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _radiusController,
                      label: 'Bán kính cho phép (mét)',
                      hint: '100',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
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
                height: 52,
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
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.4,
                          ),
                        )
                      : Text(
                          _isEditing ? 'Lưu thay đổi' : 'Thêm cấu hình',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetectButton({
    required IconData icon,
    required String label,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, color: AppColors.accentBlue, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            color: AppColors.accentBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.accentBlue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFB0B3BD)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
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
      ],
    );
  }
}
