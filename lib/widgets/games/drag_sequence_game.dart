import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/tts_service.dart';
import '../../services/localization_service.dart';
import '../../theme/app_theme.dart';

class SequenceStepItem {
  final int stepNumber;
  final String titleEn;
  final String titleUr;
  final IconData icon;
  final LinearGradient gradient;

  const SequenceStepItem({
    required this.stepNumber,
    required this.titleEn,
    required this.titleUr,
    required this.icon,
    required this.gradient,
  });
}

class DragSequenceGame extends StatefulWidget {
  final String promptEn;
  final String promptUr;
  final List<SequenceStepItem>? customSteps;
  final VoidCallback onGameCompleted;

  const DragSequenceGame({
    super.key,
    required this.promptEn,
    required this.promptUr,
    this.customSteps,
    required this.onGameCompleted,
  });

  @override
  State<DragSequenceGame> createState() => _DragSequenceGameState();
}

class _DragSequenceGameState extends State<DragSequenceGame> {
  late List<SequenceStepItem> _shuffledSteps;
  final List<SequenceStepItem> _placedSteps = [];

  @override
  void initState() {
    super.initState();
    final defaultSteps = [
      const SequenceStepItem(
        stepNumber: 1,
        titleEn: 'Turn on Water & Wet Hands',
        titleUr: 'پانی کھولیں اور ہاتھ گیلے کریں',
        icon: Icons.water_drop_rounded,
        gradient: AppTheme.blueCyanGradient,
      ),
      const SequenceStepItem(
        stepNumber: 2,
        titleEn: 'Apply Soap & Rub Palms',
        titleUr: 'صابن لگائیں اور رگڑیں',
        icon: Icons.soap_rounded,
        gradient: AppTheme.orangePinkGradient,
      ),
      const SequenceStepItem(
        stepNumber: 3,
        titleEn: 'Rinse Clean with Water',
        titleUr: 'پانی سے ہاتھ دھوئیں',
        icon: Icons.clean_hands_rounded,
        gradient: AppTheme.greenMintGradient,
      ),
      const SequenceStepItem(
        stepNumber: 4,
        titleEn: 'Dry with Soft Towel',
        titleUr: 'تولیے سے ہاتھ خشک کریں',
        icon: Icons.dry_cleaning_rounded,
        gradient: AppTheme.purpleBlueGradient,
      ),
    ];

    final steps = widget.customSteps ?? defaultSteps;
    _shuffledSteps = List.from(steps)..shuffle();
  }

  void _onStepTapped(SequenceStepItem step) {
    if (_placedSteps.contains(step)) return;

    setState(() {
      _placedSteps.add(step);
      _shuffledSteps.remove(step);
    });

    final isUrdu = LocalizationService.instance.isUrdu;
    TtsService.instance.speak(
      isUrdu ? step.titleUr : step.titleEn,
      langCode: isUrdu ? 'ur' : 'en',
    );

    // Check if all placed
    if (_shuffledSteps.isEmpty) {
      _verifySequence();
    }
  }

  void _verifySequence() {
    // Check if sorted by stepNumber
    bool correct = true;
    for (int i = 0; i < _placedSteps.length; i++) {
      if (_placedSteps[i].stepNumber != i + 1) {
        correct = false;
        break;
      }
    }

    if (correct) {
      final isUrdu = LocalizationService.instance.isUrdu;
      TtsService.instance.speak(
        isUrdu ? 'شاندار! آپ نے تمام مراحل درست ترتیب دیے!' : 'Superstar! Perfect sequence completed!',
        langCode: isUrdu ? 'ur' : 'en',
      );
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) widget.onGameCompleted();
      });
    } else {
      // Friendly reset to try again
      final isUrdu = LocalizationService.instance.isUrdu;
      TtsService.instance.speak(
        isUrdu ? 'آئیں دوبارہ ترتیب دیں!' : 'Let\'s try ordering them from step 1 again!',
        langCode: isUrdu ? 'ur' : 'en',
      );
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _shuffledSteps.addAll(_placedSteps);
            _placedSteps.clear();
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = LocalizationService.instance.isUrdu;
    final prompt = isUrdu ? widget.promptUr : widget.promptEn;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Prompt Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.softCardShadow,
            border: Border.all(color: AppTheme.electricBlue.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.touch_app_rounded, color: AppTheme.electricBlue, size: 26),
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

        const SizedBox(height: 16),

        // Target Sequence Slots (Placed items)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: AppTheme.softCardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isUrdu ? 'ترتیب شدہ مراحل:' : 'Your Completed Steps:',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                  ),
                  Text(
                    '${_placedSteps.length} / ${_placedSteps.length + _shuffledSteps.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryOrange),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_placedSteps.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      isUrdu ? 'نیچے دیے گئے مراحل پر کلک کر کے ترتیب دیں' : 'Tap the steps below in order 1, 2, 3...',
                      style: const TextStyle(color: AppTheme.textLight, fontSize: 13),
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _placedSteps.asMap().entries.map((entry) {
                    final index = entry.key;
                    final step = entry.value;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: step.gradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: AppTheme.heavyShadow(step.gradient.colors.first, opacity: 0.3, blur: 8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.white,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: step.gradient.colors.first),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(step.icon, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            isUrdu ? step.titleUr : step.titleEn,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ).animate().scale(duration: 250.ms, curve: Curves.easeOutBack);
                  }).toList(),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Available Steps to Tap/Pick
        Text(
          isUrdu ? 'مرحلہ منتخب کریں:' : 'Tap next step:',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 8),

        ..._shuffledSteps.map((step) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _onStepTapped(step),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: step.gradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: AppTheme.heavyShadow(step.gradient.colors.first, opacity: 0.35, blur: 12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(step.icon, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          isUrdu ? step.titleUr : step.titleEn,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 24),
                    ],
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
        }),
      ],
    );
  }
}
