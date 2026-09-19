import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

// Màn hình chụp khuôn mặt bằng camera trực tiếp (getUserMedia trên web).
// Trả về XFile qua Navigator.pop, hoặc null nếu người dùng hủy.
class FaceCaptureScreen extends StatefulWidget {
  const FaceCaptureScreen({super.key});

  @override
  State<FaceCaptureScreen> createState() => _FaceCaptureScreenState();
}

class _FaceCaptureScreenState extends State<FaceCaptureScreen> {
  CameraController? _controller;

  bool _isInitializing = true;
  bool _isCapturing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _initCamera();
  }

  Future<void> _initCamera() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      final cameras = await availableCameras().timeout(
        const Duration(seconds: 20),
      );

      if (cameras.isEmpty) {
        throw Exception('Không tìm thấy camera trên thiết bị.');
      }

      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize().timeout(const Duration(seconds: 20));

      if (!mounted) {
        await controller.dispose();

        return;
      }

      setState(() {
        _controller = controller;
        _isInitializing = false;
      });
    } catch (e) {
      debugPrint('Init camera error: $e');

      if (!mounted) return;

      setState(() {
        _isInitializing = false;
        _errorMessage =
            'Không thể mở camera. Hãy cho phép quyền Camera cho trình duyệt '
            '(và đảm bảo trang chạy HTTPS), rồi thử lại.';
      });
    }
  }

  Future<void> _capture() async {
    final controller = _controller;

    if (controller == null ||
        !controller.value.isInitialized ||
        _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final file = await controller.takePicture();

      if (!mounted) return;

      Navigator.of(context).pop(file);
    } catch (e) {
      debugPrint('Take picture error: $e');

      if (!mounted) return;

      setState(() {
        _isCapturing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể chụp ảnh. Vui lòng thử lại.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Chụp khuôn mặt'),
      ),

      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isInitializing) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              const Icon(
                Icons.videocam_off_outlined,
                color: Colors.white70,
                size: 48,
              ),

              const SizedBox(height: 16),

              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _initCamera,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _controller!;

    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,

            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: CameraPreview(controller),
                ),
              ),

              // KHUNG GỢI Ý ĐẶT KHUÔN MẶT
              IgnorePointer(
                child: Container(
                  width: 240,
                  height: 320,

                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(
                      Radius.elliptical(120, 160),
                    ),

                    border: Border.all(color: Colors.white70, width: 3),
                  ),
                ),
              ),
            ],
          ),
        ),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),

          child: Text(
            'Đặt khuôn mặt vào khung, đủ sáng và nhìn thẳng camera.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(bottom: 24),

          child: GestureDetector(
            onTap: _isCapturing ? null : _capture,

            child: Container(
              width: 72,
              height: 72,

              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isCapturing ? Colors.grey : AppColors.primaryBlue,
                border: Border.all(color: Colors.white, width: 4),
              ),

              child: _isCapturing
                  ? const Padding(
                      padding: EdgeInsets.all(22),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : const Icon(Icons.camera_alt, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}