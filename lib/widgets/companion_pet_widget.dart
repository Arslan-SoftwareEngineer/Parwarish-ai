import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import '../services/tts_service.dart';
import '../services/localization_service.dart';
import '../theme/app_theme.dart';

class CompanionPetWidget extends StatefulWidget {
  final bool isHappy;
  final String? customSpeech;
  final String autismLevel;
  final VoidCallback? onTap;

  const CompanionPetWidget({
    super.key,
    this.isHappy = false,
    this.customSpeech,
    this.autismLevel = 'Mild',
    this.onTap,
  });

  @override
  State<CompanionPetWidget> createState() => _CompanionPetWidgetState();
}

class _CompanionPetWidgetState extends State<CompanionPetWidget> with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  bool _isPlayingSound = false;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  String _getSpeechText() {
    if (widget.customSpeech != null && widget.customSpeech!.isNotEmpty) {
      return widget.customSpeech!;
    }
    if (widget.isHappy) {
      return LocalizationService.instance.tr('pet_happy_praise');
    }
    switch (widget.autismLevel.toLowerCase()) {
      case 'severe':
        return LocalizationService.instance.tr('pet_greeting_severe');
      case 'moderate':
        return LocalizationService.instance.tr('pet_greeting_moderate');
      default:
        return LocalizationService.instance.tr('pet_greeting_mild');
    }
  }

  Future<void> _handlePetTap() async {
    widget.onTap?.call();
    if (_isPlayingSound) return;
    _isPlayingSound = true;
    final speech = _getSpeechText();
    final lang = LocalizationService.instance.currentLocale.value;
    await TtsService.instance.speak(speech, langCode: lang);
    _isPlayingSound = false;
  }

  @override
  Widget build(BuildContext context) {
    final speech = _getSpeechText();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Speech Bubble
        GestureDetector(
          onTap: _handlePetTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.softCardShadow,
              border: Border.all(
                color: widget.isHappy ? AppTheme.amberGold : AppTheme.primaryOrange.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.isHappy ? Icons.star_rounded : Icons.chat_bubble_rounded,
                  color: widget.isHappy ? AppTheme.amberGold : AppTheme.primaryOrange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    speech,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.volume_up_rounded,
                  color: AppTheme.electricBlue,
                  size: 18,
                ),
              ],
            ),
          )
              .animate(key: ValueKey(speech))
              .fadeIn(duration: 400.ms)
              .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), curve: Curves.easeOutBack),
        ),

        const SizedBox(height: 8),

        // Interactive Pet Body
        GestureDetector(
          onTap: _handlePetTap,
          child: AnimatedBuilder(
            animation: _bounceController,
            builder: (context, child) {
              final offset = widget.isHappy
                  ? (_bounceController.value * -16)
                  : (_bounceController.value * -8);
              return Transform.translate(
                offset: Offset(0, offset),
                child: SizedBox(
                  width: 170,
                  height: 170,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glow halo behind pet
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (widget.isHappy ? AppTheme.amberGold : AppTheme.primaryOrange)
                                  .withValues(alpha: 0.35),
                              blurRadius: 30,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      // Lottie Pet with fallback custom mascot
                      Lottie.asset(
                        widget.isHappy
                            ? 'assets/animations/pet_happy.json'
                            : 'assets/animations/pet_idle.json',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildFallbackMascot();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackMascot() {
    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: widget.isHappy ? AppTheme.sunshineGradient : AppTheme.orangePinkGradient,
        boxShadow: AppTheme.heavyShadow(AppTheme.primaryOrange),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Eyes
          Positioned(
            top: 42,
            left: 36,
            child: Container(
              width: 14,
              height: widget.isHappy ? 10 : 16,
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 42,
            right: 36,
            child: Container(
              width: 14,
              height: widget.isHappy ? 10 : 16,
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Cheerful Blush
          Positioned(
            top: 56,
            left: 20,
            child: Container(
              width: 18,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.pinkAccent.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Positioned(
            top: 56,
            right: 20,
            child: Container(
              width: 18,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.pinkAccent.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          // Big Smile
          Positioned(
            bottom: 34,
            child: Container(
              width: 32,
              height: widget.isHappy ? 22 : 14,
              decoration: BoxDecoration(
                color: const Color(0xFFD90429),
                borderRadius: BorderRadius.vertical(
                  bottom: const Radius.circular(30),
                  top: widget.isHappy ? const Radius.circular(8) : Radius.zero,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
