import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/camera_service.dart';
import '../../services/tts_service.dart';
import '../../services/localization_service.dart';
import '../../theme/app_theme.dart';

class EmotionMirrorGame extends StatefulWidget {
  final String promptEn;
  final String promptUr;
  final VoidCallback onGameCompleted;

  const EmotionMirrorGame({
    super.key,
    required this.promptEn,
    required this.promptUr,
    required this.onGameCompleted,
  });

  @override
  State<EmotionMirrorGame> createState() => _EmotionMirrorGameState();
}

class _EmotionMirrorGameState extends State<EmotionMirrorGame> with SingleTickerProviderStateMixin {
  bool _isCameraInitialized = false;
  double _joyProgress = 0.2;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _initCamera();
  }

  Future<void> _initCamera() async {
    final ok = await CameraService.instance.initializeFrontCamera();
    if (mounted) {
      setState(() => _isCameraInitialized = ok);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    CameraService.instance.dispose();
    super.dispose();
  }

  void _boostJoyMeter() {
    setState(() {
      _joyProgress = (_joyProgress + 0.35).clamp(0.0, 1.0);
    });

    if (_joyProgress >= 1.0) {
      final isUrdu = LocalizationService.instance.isUrdu;
      TtsService.instance.speak(
        isUrdu ? 'کیا خوبصورت مسکراہٹ ہے! شاندار!' : 'What a wonderful radiant smile! Amazing!',
        langCode: isUrdu ? 'ur' : 'en',
      );
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) widget.onGameCompleted();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = LocalizationService.instance.isUrdu;
    final prompt = isUrdu ? widget.promptUr : widget.promptEn;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // AI Instruction Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: AppTheme.softCardShadow,
            border: Border.all(color: AppTheme.primaryOrange.withValues(alpha: 0.35), width: 2),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.sunshineGradient,
                ),
                child: const Icon(Icons.face_retouching_natural_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  prompt,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.1, end: 0),

        const SizedBox(height: 20),

        // Live Camera Mirror Frame
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer Glowing Halo
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 220 + (_pulseController.value * 16),
                  height: 220 + (_pulseController.value * 16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.amberGold.withValues(alpha: 0.2 + (_pulseController.value * 0.15)),
                  ),
                );
              },
            ),
            // Circular Camera View
            Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.amberGold, width: 4),
                boxShadow: AppTheme.heavyShadow(AppTheme.primaryOrange, opacity: 0.35, blur: 20),
              ),
              clipBehavior: Clip.antiAlias,
              child: _isCameraInitialized && CameraService.instance.controller != null
                  ? CameraPreview(CameraService.instance.controller!)
                  : Container(
                      color: const Color(0xFF1E293B),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.face_rounded, color: AppTheme.yellowAccent, size: 60),
                          SizedBox(height: 8),
                          Text(
                            'Mirror Active',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Joy-O-Meter Progress Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isUrdu ? 'مسکراہٹ اور تاثرات کا میٹر' : 'Joy-O-Meter',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  Text(
                    '${(_joyProgress * 100).toInt()}%',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppTheme.primaryOrange),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _joyProgress,
                  minHeight: 14,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.amberGold),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Interactive Smile & Gesture Button
        ElevatedButton.icon(
          onPressed: _boostJoyMeter,
          icon: const Icon(Icons.star_rounded, color: Colors.white, size: 24),
          label: Text(
            isUrdu ? 'مسکراہٹ شیئر کریں! ✨' : 'Share My Smile! ✨',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryOrange,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 4,
          ),
        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
      ],
    );
  }
}
