import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/tts_service.dart';
import '../../services/localization_service.dart';
import '../../theme/app_theme.dart';

class SequenceStepItem {
  final int stepNumber;
  final String titleEn;
  final String titleUr;
  final String actionEn;
  final String actionUr;
  final IconData icon;
  final LinearGradient gradient;

  const SequenceStepItem({
    required this.stepNumber,
    required this.titleEn,
    required this.titleUr,
    this.actionEn = 'Complete Step',
    this.actionUr = 'مرحلہ مکمل کریں',
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
  late List<SequenceStepItem> _steps;
  int _currentStepIndex = 0;
  bool _isStepAnimating = false;

  @override
  void initState() {
    super.initState();
    final defaultSteps = [
      const SequenceStepItem(
        stepNumber: 1,
        titleEn: 'Turn on Water & Wet Hands',
        titleUr: 'پانی کھولیں اور ہاتھ گیلے کریں',
        actionEn: 'Turn On Water 💧',
        actionUr: 'پانی کھولیں 💧',
        icon: Icons.water_drop_rounded,
        gradient: AppTheme.blueCyanGradient,
      ),
      const SequenceStepItem(
        stepNumber: 2,
        titleEn: 'Apply Soap & Rub Palms',
        titleUr: 'صابن لگائیں اور جھاگ بنائیں',
        actionEn: 'Rub Soapy Bubbles 🧼',
        actionUr: 'صابن ملیں 🧼',
        icon: Icons.soap_rounded,
        gradient: AppTheme.orangePinkGradient,
      ),
      const SequenceStepItem(
        stepNumber: 3,
        titleEn: 'Rinse Clean with Water',
        titleUr: 'پانی سے صابن صاف کریں',
        actionEn: 'Rinse with Water 🚿',
        actionUr: 'پانی سے دھوئیں 🚿',
        icon: Icons.clean_hands_rounded,
        gradient: AppTheme.greenMintGradient,
      ),
      const SequenceStepItem(
        stepNumber: 4,
        titleEn: 'Dry with Soft Towel',
        titleUr: 'نرم تولیے سے ہاتھ خشک کریں',
        actionEn: 'Dry Hands with Towel 🧺',
        actionUr: 'تولیے سے خشک کریں 🧺',
        icon: Icons.dry_cleaning_rounded,
        gradient: AppTheme.purpleBlueGradient,
      ),
    ];

    _steps = widget.customSteps ?? defaultSteps;
    _speakCurrentStep();
  }

  void _speakCurrentStep() {
    final isUrdu = LocalizationService.instance.isUrdu;
    final current = _steps[_currentStepIndex];
    TtsService.instance.speak(
      isUrdu ? current.titleUr : current.titleEn,
      langCode: isUrdu ? 'ur' : 'en',
    );
  }

  void _completeCurrentStep() {
    if (_isStepAnimating) return;

    setState(() {
      _isStepAnimating = true;
    });

    final isUrdu = LocalizationService.instance.isUrdu;
    final current = _steps[_currentStepIndex];

    final feedbackEn = _getStepFeedbackEn(current.stepNumber);
    final feedbackUr = _getStepFeedbackUr(current.stepNumber);

    TtsService.instance.speak(
      isUrdu ? feedbackUr : feedbackEn,
      langCode: isUrdu ? 'ur' : 'en',
    );

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;

      if (_currentStepIndex < _steps.length - 1) {
        setState(() {
          _currentStepIndex++;
          _isStepAnimating = false;
        });
        _speakCurrentStep();
      } else {
        TtsService.instance.speak(
          isUrdu ? 'شاباش! ہاتھ بالکل صاف اور چمکدار ہیں!' : 'Superstar! Clean and fresh hands! You did it!',
          langCode: isUrdu ? 'ur' : 'en',
        );
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) widget.onGameCompleted();
        });
      }
    });
  }

  String _getStepFeedbackEn(int step) {
    switch (step) {
      case 1:
        return 'Splash! Water is on and hands are wet!';
      case 2:
        return 'Great job! Lovely bubbles on hands!';
      case 3:
        return 'Awesome! All soap bubbles rinsed clean!';
      case 4:
      default:
        return 'Superstar! Hands are clean and soft!';
    }
  }

  String _getStepFeedbackUr(int step) {
    switch (step) {
      case 1:
        return 'شاباش! ہاتھ گیلے ہو گئے!';
      case 2:
        return 'بہت خوب! صابن کی جھاگ بن گئی!';
      case 3:
        return 'شاندار! صابن صاف ہو گیا!';
      case 4:
      default:
        return 'زبردست! ہاتھ بالکل صاف ہیں!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = LocalizationService.instance.isUrdu;
    final prompt = isUrdu ? widget.promptUr : widget.promptEn;
    final currentStep = _steps[_currentStepIndex];

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
              const Icon(Icons.clean_hands_rounded, color: AppTheme.electricBlue, size: 26),
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

        // Step Progress Tracker Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.softCardShadow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _steps.asMap().entries.map((entry) {
              final idx = entry.key;
              final step = entry.value;
              final isDone = idx < _currentStepIndex;
              final isCurrent = idx == _currentStepIndex;

              return Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isDone || isCurrent ? step.gradient : null,
                        color: isDone || isCurrent ? null : Colors.grey.shade200,
                        boxShadow: isCurrent
                            ? AppTheme.heavyShadow(step.gradient.colors.first, opacity: 0.4, blur: 8)
                            : null,
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                            : Icon(
                                step.icon,
                                color: isCurrent ? Colors.white : Colors.grey.shade500,
                                size: 18,
                              ),
                      ),
                    ),
                    if (idx < _steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: isDone ? AppTheme.mintGreen : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        // Main Active Step Card
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) {
            return ScaleTransition(scale: animation, child: FadeTransition(opacity: animation, child: child));
          },
          child: Container(
            key: ValueKey<int>(_currentStepIndex),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: AppTheme.softCardShadow,
              border: Border.all(color: currentStep.gradient.colors.first.withValues(alpha: 0.35), width: 2),
            ),
            child: Column(
              children: [
                // Step Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: currentStep.gradient.colors.first.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isUrdu
                        ? 'مرحلہ ${_currentStepIndex + 1} از ${_steps.length}'
                        : 'Step ${_currentStepIndex + 1} of ${_steps.length}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: currentStep.gradient.colors.first,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Step Illustration Circle
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: currentStep.gradient,
                    boxShadow: AppTheme.heavyShadow(currentStep.gradient.colors.first, opacity: 0.4, blur: 20),
                  ),
                  child: Center(
                    child: Icon(
                      currentStep.icon,
                      color: Colors.white,
                      size: 52,
                    ),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                      begin: const Offset(0.95, 0.95),
                      end: const Offset(1.05, 1.05),
                      duration: 1200.ms,
                      curve: Curves.easeInOut,
                    ),

                const SizedBox(height: 18),

                // Step Title (Urdu / English)
                Text(
                  isUrdu ? currentStep.titleUr : currentStep.titleEn,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  isUrdu ? currentStep.titleEn : currentStep.titleUr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),

                const SizedBox(height: 22),

                // Big Action Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _completeCurrentStep,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 4,
                      shadowColor: currentStep.gradient.colors.first.withValues(alpha: 0.5),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: currentStep.gradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isStepAnimating) ...[
                              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 26),
                              const SizedBox(width: 8),
                              Text(
                                isUrdu ? 'شاباش!' : 'Done! ✨',
                                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                            ] else ...[
                              Icon(currentStep.icon, color: Colors.white, size: 24),
                              const SizedBox(width: 10),
                              Text(
                                isUrdu ? currentStep.actionUr : currentStep.actionEn,
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}
