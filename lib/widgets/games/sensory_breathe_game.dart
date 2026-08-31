import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/tts_service.dart';
import '../../services/localization_service.dart';
import '../../theme/app_theme.dart';
import '../breathe_circle_widget.dart';

class SensoryBreatheGame extends StatefulWidget {
  final String promptEn;
  final String promptUr;
  final VoidCallback onGameCompleted;

  const SensoryBreatheGame({
    super.key,
    required this.promptEn,
    required this.promptUr,
    required this.onGameCompleted,
  });

  @override
  State<SensoryBreatheGame> createState() => _SensoryBreatheGameState();
}

class _SensoryBreatheGameState extends State<SensoryBreatheGame> {
  int _poppedBubbles = 0;
  final int _targetBubbles = 4;
  final List<bool> _bubblePopped = [false, false, false, false];

  void _popBubble(int index) {
    if (_bubblePopped[index]) return;
    setState(() {
      _bubblePopped[index] = true;
      _poppedBubbles++;
    });

    if (_poppedBubbles >= _targetBubbles) {
      final isUrdu = LocalizationService.instance.isUrdu;
      TtsService.instance.speak(
        isUrdu ? 'بہت پرسکون اور شاندار! آپ نے تمام بلبلے پھوڑ دیے!' : 'So peaceful and calm! All sensory bubbles popped!',
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
        // Prompt Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.softCardShadow,
            border: Border.all(color: AppTheme.electricCyan.withValues(alpha: 0.4), width: 1.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.air_rounded, color: AppTheme.electricBlue, size: 26),
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

        // Sensory Breathing Pacer
        BreatheCircleWidget(
          onCycleCompleted: () {
            // cycle completed
          },
        ),

        const SizedBox(height: 24),

        Text(
          isUrdu ? 'بلبلوں پر ٹیپ کریں:' : 'Tap calm bubbles to pop:',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textSecondary),
        ),

        const SizedBox(height: 12),

        // Floating Sensory Bubbles
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (index) {
            final popped = _bubblePopped[index];

            return GestureDetector(
              onTap: () => _popBubble(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: popped
                      ? AppTheme.greenMintGradient
                      : (index % 2 == 0 ? AppTheme.blueCyanGradient : AppTheme.calmLavenderGradient),
                  boxShadow: popped
                      ? AppTheme.heavyShadow(AppTheme.mintGreen, opacity: 0.3, blur: 8)
                      : AppTheme.heavyShadow(AppTheme.electricBlue, opacity: 0.35, blur: 12),
                ),
                child: Icon(
                  popped ? Icons.check_rounded : Icons.bubble_chart_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
            );
          }),
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}
