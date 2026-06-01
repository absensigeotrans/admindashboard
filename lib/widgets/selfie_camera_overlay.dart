import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/selfie_service.dart';

class SelfieCameraOverlay extends StatefulWidget {
  const SelfieCameraOverlay({super.key});

  @override
  State<SelfieCameraOverlay> createState() => _SelfieCameraOverlayState();
}

class _SelfieCameraOverlayState extends State<SelfieCameraOverlay>
    with TickerProviderStateMixin {
  CameraController? _controller;
  bool _isProcessing = false;
  int _countdown = 2;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _anim = Tween<double>(begin: 0.0, end: 1.0).animate(_animController);
    _animController.repeat();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      final service = SelfieService();
      final camera = await service.getFrontCamera();
      if (camera == null) {
        if (mounted) {
          setState(() => _errorMessage = 'Tidak ada kamera tersedia');
        }
        return;
      }

      _controller = CameraController(camera, ResolutionPreset.medium);
      await _controller!.initialize();

      if (!mounted) return;

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) _startCountdown();
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Gagal inisialisasi kamera: $e');
      }
    }
  }

  void _startCountdown() async {
    for (int i = 2; i >= 0; i--) {
      if (!mounted) return;
      setState(() => _countdown = i);
      await Future.delayed(const Duration(seconds: 1));
    }
    if (mounted) _captureAndProcess();
  }

  Future<void> _captureAndProcess() async {
    if (_controller == null || !mounted) return;
    setState(() => _isProcessing = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) Navigator.of(context).pop(null);
        return;
      }

      final service = SelfieService();
      final result = await service.captureAndUpload(
        controller: _controller!,
        userId: user.id,
      );

      if (mounted) Navigator.of(context).pop(result);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = '${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_controller != null && _controller!.value.isInitialized)
            CameraPreview(_controller!)
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [Colors.black54, Colors.transparent],
              ),
            ),
          ),

          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                _isProcessing ? 'Memproses...' : 'Mengambil Foto Selfie',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          Center(
            child: _isProcessing
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage ?? 'Memproses gambar...',
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _anim,
                        builder: (context, child) {
                          return SizedBox(
                            width: 100,
                            height: 100,
                            child: CustomPaint(
                              painter: _CountdownPainter(
                                progress: _anim.value,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _countdown > 0 ? '$_countdown' : '📸',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),

          if (_errorMessage != null)
            Positioned(
              bottom: 80,
              left: 24,
              right: 24,
              child: Column(
                children: [
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(null),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                        ),
                        child: const Text('Lanjut Tanpa Foto'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _errorMessage = null;
                            _isProcessing = false;
                          });
                          _startCountdown();
                        },
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          if (!_isProcessing && _errorMessage == null)
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Lanjut Tanpa Foto?'),
                      content: const Text(
                        'Anda bisa melanjutkan absensi tanpa foto selfie.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Tetap Foto'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            Navigator.of(context).pop(null);
                          },
                          child: const Text('Lanjut Tanpa Foto'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _CountdownPainter extends CustomPainter {
  final double progress;

  _CountdownPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    canvas.drawCircle(center, radius, paint);

    final progressPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -90 * 3.14159 / 180,
      360 * progress * 3.14159 / 180,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CountdownPainter old) =>
      old.progress != progress;
}
