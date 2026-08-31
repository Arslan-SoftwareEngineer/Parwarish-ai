import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/tts_service.dart';
import '../../services/localization_service.dart';
import '../../theme/app_theme.dart';

class FineMotorTraceGame extends StatefulWidget {
  final String promptEn;
  final String promptUr;
  final VoidCallback onGameCompleted;

  const FineMotorTraceGame({
    super.key,
    required this.promptEn,
    required this.promptUr,
    required this.onGameCompleted,
  });

  @override
  State<FineMotorTraceGame> createState() => _FineMotorTraceGameState();
}

class _FineMotorTraceGameState extends State<FineMotorTraceGame> {
  final List<Offset> _points = [];
  double _traceProgress = 0.0;

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    setState(() {
      _points.add(details.localPosition);
      _traceProgress = (_points.length / 35.0).clamp(0.0, 1.0);
    });

    if (_traceProgress >= 1.0) {
      final isUrdu = LocalizationService.instance.isUrdu;
      TtsService.instance.speak(
        isUrdu ? 'بہت خوبصورت لکیر کھینچی! شاباش!' : 'Beautiful tracing! You completed the path!',
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
        // Prompt Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.softCardShadow,
            border: Border.all(color: AppTheme.purpleStart.withValues(alpha: 0.35), width: 1.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.gesture_rounded, color: AppTheme.purpleStart, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  prompt,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Tactile Canvas for finger tracing
        Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.softCardShadow,
            border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onPanUpdate: (details) => _onPanUpdate(details, Size(constraints.maxWidth, constraints.maxHeight)),
                child: CustomPaint(
                  painter: _TracePathPainter(points: _points),
                  child: Center(
                    child: _points.isEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.touch_app_rounded, size: 40, color: AppTheme.primaryOrange)
                                  .animate(onPlay: (c) => c.repeat(reverse: true))
                                  .slideX(begin: -0.2, end: 0.2, duration: 900.ms),
                              const SizedBox(height: 8),
                              Text(
                                isUrdu ? 'اسکرین پر انگلی سے راستہ بنائیں' : 'Trace along with your finger',
                                style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // Trace Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: _traceProgress,
            minHeight: 12,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.mintGreen),
          ),
        ),

        const SizedBox(height: 16),

        ElevatedButton.icon(
          onPressed: () {
            widget.onGameCompleted();
          },
          icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
          label: Text(isUrdu ? 'مکمل ہوا! ✨' : 'Path Completed! ✨'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.mintGreen,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
      ],
    );
  }
}

class _TracePathPainter extends CustomPainter {
  final List<Offset> points;
  _TracePathPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    // Background Guide dotted line
    final guidePaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(40, size.height / 2);
    path.cubicTo(size.width * 0.35, 30, size.width * 0.65, size.height - 30, size.width - 40, size.height / 2);
    canvas.drawPath(path, guidePaint);

    // User drawn glowing trail
    final trailPaint = Paint()
      ..shader = AppTheme.orangePinkGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], trailPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TracePathPainter oldDelegate) => true;
}
