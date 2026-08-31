import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/localization_service.dart';
import '../theme/app_theme.dart';

class MoodOption {
  final String key;
  final String labelEn;
  final String labelUr;
  final String emoji;
  final LinearGradient gradient;

  const MoodOption({
    required this.key,
    required this.labelEn,
    required this.labelUr,
    required this.emoji,
    required this.gradient,
  });
}

class MoodCheckinDialog extends StatelessWidget {
  final Function(String selectedMood) onMoodSelected;

  const MoodCheckinDialog({super.key, required this.onMoodSelected});

  static const List<MoodOption> moodOptions = [
    MoodOption(
      key: 'Happy',
      labelEn: 'Happy & Joyful',
      labelUr: 'بہت خوش اور پرجوش',
      emoji: '😄',
      gradient: AppTheme.sunshineGradient,
    ),
    MoodOption(
      key: 'Calm',
      labelEn: 'Calm & Peaceful',
      labelUr: 'پرسکون اور آرام دہ',
      emoji: '🧘',
      gradient: AppTheme.blueCyanGradient,
    ),
    MoodOption(
      key: 'Excited',
      labelEn: 'Super Energetic',
      labelUr: 'بہت انرجیٹک',
      emoji: '⚡',
      gradient: AppTheme.orangePinkGradient,
    ),
    MoodOption(
      key: 'Focused',
      labelEn: 'Super Focused',
      labelUr: 'مکمل توجہ کے ساتھ',
      emoji: '🎯',
      gradient: AppTheme.purpleBlueGradient,
    ),
    MoodOption(
      key: 'Tired',
      labelEn: 'A bit tired',
      labelUr: 'تھوڑا سا تھکا ہوا',
      emoji: '😴',
      gradient: AppTheme.calmLavenderGradient,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isUrdu = LocalizationService.instance.isUrdu;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: AppTheme.heavyShadow(AppTheme.primaryOrange, opacity: 0.35, blur: 28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.orangePinkGradient,
              ),
              child: const Icon(Icons.mood_rounded, color: Colors.white, size: 36),
            ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),

            const SizedBox(height: 14),

            Text(
              LocalizationService.instance.tr('how_did_you_feel'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
              ),
            ),

            const SizedBox(height: 20),

            // Grid of Mood options
            ...moodOptions.map((mood) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => onMoodSelected(mood.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: mood.gradient,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: AppTheme.heavyShadow(mood.gradient.colors.first, opacity: 0.25, blur: 8),
                      ),
                      child: Row(
                        children: [
                          Text(mood.emoji, style: const TextStyle(fontSize: 26)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              isUrdu ? mood.labelUr : mood.labelEn,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
