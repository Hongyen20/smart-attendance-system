import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

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

    _ipController = TextEditingController(
      text: c?['allowedIp']?.toString() ?? '',
    );

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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // LẤY PUBLIC IPV4 HIỆN TẠI

  Future<void> _detectCurrentIp() async {
    if (_isDetectingIp) return;

    setState(() {
      _isDetectingIp = true;
      _errorMessage = null;
    });

    try {
      final response = await http
          .get(
            Uri.parse('https://api.ipify.org?format=json'),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(
          'API trả về mã trạng thái ${response.statusCode}.',
        );
      }

      final data = jsonDecode(response.body);

      if (data is! Map<String, dynamic>) {
        throw Exception('Dữ liệu IP không hợp lệ.');
      }

      final ip = data['ip']?.toString().trim();

      if (ip == null || ip.isEmpty) {
        throw Exception('Không nhận được địa chỉ IP.');
      }

      if (!_isValidIPv4(ip)) {
        throw Exception('API trả về địa chỉ IPv4 không hợp lệ.');
      }

      if (!mounted) return;

      setState(() {
        _ipController.text = ip;
      });

      _showSnack('Đã lấy IP công cộng hiện tại: $ip');
    } catch (e) {
      if (!mounted) return;

      _showSnack(
        'Không thể lấy IP hiện tại. Vui lòng kiểm tra kết nối Internet.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDetectingIp = false;
        });
      }
    }
  }

  // Kiểm tra IPv4 dạng:
  // 192.168.1.1
  // 118.70.12.34
  bool _isValidIPv4(String ip) {
    final parts = ip.split('.');

    if (parts.length != 4) {
      return false;
    }

    for (final part in parts) {
      final value = int.tryParse(part);

      if (value == null || value < 0 || value > 255) {
        return false;
      }
    }

    return true;
  }

  // LẤY GPS HIỆN TẠI

  Future<void> _detectCurrentLocation() async {
    if (_isDetectingLocation) return;

    setState(() {
      _isDetectingLocation = true;
      _errorMessage = null;
    });

    try {
      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showSnack(
          'Cần cấp quyền vị trí để lấy tọa độ hiện tại.',
        );
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnack(
          'Quyền vị trí đã bị từ chối vĩnh viễn. '
          'Vui lòng cấp quyền trong cài đặt thiết bị.',
        );
        return;
      }

      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _showSnack(
          'Vui lòng bật định vị (GPS) trên thiết bị.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        _latController.text =
            position.latitude.toStringAsFixed(6);
        _lngController.text =
            position.longitude.toStringAsFixed(6);
      });

      _showSnack('Đã lấy vị trí hiện tại.');
    } catch (e) {
      if (mounted) {
        _showSnack(
          'Không lấy được vị trí hiện tại. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDetectingLocation = false;
        });
      }
    }
  }

  // LƯU CẤU HÌNH

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();

    final ip = _ipController.text.trim();
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    final radius = double.tryParse(
      _radiusController.text.trim(),
    );

    // Validate IP
    if (ip.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập địa chỉ IP.';
      });
      return;
    }

    if (!_isValidIPv4(ip)) {
      setState(() {
        _errorMessage =
            'Địa chỉ IPv4 không hợp lệ. Ví dụ: 118.70.12.34';
      });
      return;
    }

    // Validate GPS
    if (lat == null || lat < -90 || lat > 90) {
      setState(() {
        _errorMessage = 'Vĩ độ không hợp lệ.';
      });
      return;
    }

    if (lng == null || lng < -180 || lng > 180) {
      setState(() {
        _errorMessage = 'Kinh độ không hợp lệ.';
      });
      return;
    }

    // Validate radius
    if (radius == null || radius < 1 || radius > 5000) {
      setState(() {
        _errorMessage =
            'Bán kính phải nằm trong khoảng từ 1 đến 5000 mét.';
      });
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
            {
              ...body,
              'isActive':
                  widget.existingConfig!['isActive'] ?? true,
            },
            bearerToken: AuthState.instance.token,
          )
        : await ApiService.post(
            '/api/ip-configs',
            body,
            bearerToken: AuthState.instance.token,
          );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (result.success) {
      _showSnack(
        _isEditing
            ? 'Đã cập nhật cấu hình IP.'
            : 'Đã thêm cấu hình IP.',
      );

      Navigator.pop(context, true);
    } else {
      setState(() {
        _errorMessage =
            result.errorMessage ??
            'Không thể lưu cấu hình IP.';
      });
    }
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isEditing
              ? 'Sửa cấu hình IP'
              : 'Thêm cấu hình IP',
        ),
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
              // ==================================================
              // NÚT LẤY IP
              // ==================================================

              _buildDetectButton(
                icon: Icons.public,
                label: 'Lấy IP hiện tại',
                isLoading: _isDetectingIp,
                onPressed: _detectCurrentIp,
              ),

              const SizedBox(height: 8),

              const Text(
                'Đứng trong khu vực công ty (kết nối đúng mạng cần cấu hình) rồi bấm để lấy IP công cộng hiện tại.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // FORM
              // ==================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.borderColor,
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      controller: _ipController,
                      label: 'Địa chỉ IP công cộng',
                      hint: '118.70.12.34',
                      keyboardType:
                          TextInputType.number,
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // NÚT LẤY GPS
                    // ==================================================

                    _buildDetectButton(
                      icon: Icons.my_location,
                      label:
                          'Lấy vị trí hiện tại (GPS)',
                      isLoading: _isDetectingLocation,
                      onPressed:
                          _detectCurrentLocation,
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller:
                                _latController,
                            label: 'Vĩ độ (lat)',
                            hint: '10.7769',
                            keyboardType:
                                const TextInputType
                                    .numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller:
                                _lngController,
                            label: 'Kinh độ (lng)',
                            hint: '106.7009',
                            keyboardType:
                                const TextInputType
                                    .numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    _buildTextField(
                      controller:
                          _radiusController,
                      label:
                          'Bán kính cho phép (mét)',
                      hint: '100',
                      keyboardType:
                          TextInputType.number,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // ERROR
              // ==================================================

              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(
                    bottom: 12,
                  ),
                  padding:
                      const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color:
                        AppColors.dangerRedBg,
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color:
                          AppColors.dangerRed,
                      fontSize: 13,
                    ),
                  ),
                ),

              // ==================================================
              // SUBMIT
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : _handleSubmit,
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.primaryBlue,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                              CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.4,
                          ),
                        )
                      : Text(
                          _isEditing
                              ? 'Lưu thay đổi'
                              : 'Thêm cấu hình',
                          style:
                              const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
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

  // DETECT BUTTON

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
        onPressed:
            isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : Icon(
                icon,
                color:
                    AppColors.accentBlue,
                size: 20,
              ),
        label: Text(
          label,
          style: const TextStyle(
            color:
                AppColors.accentBlue,
            fontWeight:
                FontWeight.w600,
          ),
        ),
        style:
            OutlinedButton.styleFrom(
          side: const BorderSide(
            color:
                AppColors.accentBlue,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // TEXT FIELD

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType =
        TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight:
                FontWeight.w600,
            color:
                AppColors.textSecondary,
          ),
        ),

        const SizedBox(height: 6),

        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration:
              InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(
              color:
                  Color(0xFFB0B3BD),
            ),
            contentPadding:
                const EdgeInsets
                    .symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                      12),
              borderSide:
                  const BorderSide(
                color:
                    AppColors
                        .borderColor,
              ),
            ),
            enabledBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                      12),
              borderSide:
                  const BorderSide(
                color:
                    AppColors
                        .borderColor,
              ),
            ),
            focusedBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                      12),
              borderSide:
                  const BorderSide(
                color:
                    AppColors
                        .accentBlue,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

