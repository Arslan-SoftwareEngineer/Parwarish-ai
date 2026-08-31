import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import '../services/localization_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';

class CelebrationOverlay extends StatefulWidget {
  final VoidCallback onContinue;
  final int starsEarned;
  final String moduleTitle;

  const CelebrationOverlay({
    super.key,
    required this.onContinue,
    this.starsEarned = 50,
    required this.moduleTitle,
  });

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay> {
  @override
  void initState() {
    super.initState();
    _triggerCelebrationAudio();
  }

  Future<void> _triggerCelebrationAudio() async {
    final isUrdu = LocalizationService.instance.isUrdu;
    final text = isUrdu
        ? 'شاباش! آپ نے مشن مکمل کر لیا اور ستارے حاصل کیے!'
        : 'Awesome job! You completed the mission and earned stars!';
    await TtsService.instance.speak(text, langCode: isUrdu ? 'ur' : 'en');
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = LocalizationService.instance.isUrdu;

    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: AppTheme.heavyShadow(AppTheme.primaryOrange, opacity: 0.4, blur: 30),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Lottie celebration or star bursts
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: Lottie.asset(
                      'assets/animations/celebration.json',
                      repeat: false,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 100,
                          height: 100,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.sunshineGradient,
                          ),
                          child: const Icon(
                            Icons.emoji_events_rounded,
                            color: Colors.white,
                            size: 56,
                          ),
                        );
                      },
                    ),
                  )
                      .animate()
                      .scale(duration: 500.ms, curve: Curves.elasticOut)
                      .shimmer(duration: 1000.ms),

                  const SizedBox(height: 16),

                  Text(
                    LocalizationService.instance.tr('congratulations'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 8),

                  Text(
                    widget.moduleTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Star Reward Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: AppTheme.sunshineGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppTheme.heavyShadow(AppTheme.amberGold, opacity: 0.4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.white, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          isUrdu ? '+${widget.starsEarned} ستارے ملے!' : '+${widget.starsEarned} Stars Earned!',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate(delay: 200.ms)
                      .scale(duration: 400.ms, curve: Curves.bounceOut),

                  const SizedBox(height: 28),

                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: widget.onContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.mintGreen,
                        foregroundColor: Colors.white,
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        LocalizationService.instance.tr('continue_btn'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                      .animate(delay: 400.ms)
                      .fadeIn(duration: 300.ms)
                      .shimmer(duration: 1200.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
