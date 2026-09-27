import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/tts_service.dart';
import '../../services/localization_service.dart';
import '../../theme/app_theme.dart';

class MatchItem {
  final String id;
  final String labelEn;
  final String labelUr;
  final IconData icon;
  final bool isSchoolItem;
  final LinearGradient gradient;

  const MatchItem({
    required this.id,
    required this.labelEn,
    required this.labelUr,
    required this.icon,
    required this.isSchoolItem,
    required this.gradient,
  });
}

class MatchingSortingGame extends StatefulWidget {
  final String promptEn;
  final String promptUr;
  final VoidCallback onGameCompleted;

  const MatchingSortingGame({
    super.key,
    required this.promptEn,
    required this.promptUr,
    required this.onGameCompleted,
  });

  @override
  State<MatchingSortingGame> createState() => _MatchingSortingGameState();
}

class _MatchingSortingGameState extends State<MatchingSortingGame> {
  final List<MatchItem> _items = [
    const MatchItem(
      id: 'it_1',
      labelEn: 'Notebook & Pencil',
      labelUr: 'کاپی اور پنسل',
      icon: Icons.menu_book_rounded,
      isSchoolItem: true,
      gradient: AppTheme.blueCyanGradient,
    ),
    const MatchItem(
      id: 'it_2',
      labelEn: 'Lunch Box',
      labelUr: 'لنچ باکس',
      icon: Icons.lunch_dining_rounded,
      isSchoolItem: true,
      gradient: AppTheme.orangePinkGradient,
    ),
    const MatchItem(
      id: 'it_3',
      labelEn: 'Soft Bed Pillow',
      labelUr: 'نرم تکیہ',
      icon: Icons.bed_rounded,
      isSchoolItem: false,
      gradient: AppTheme.purpleBlueGradient,
    ),
    const MatchItem(
      id: 'it_4',
      labelEn: 'Water Bottle',
      labelUr: 'پانی کی بوتل',
      icon: Icons.water_drop_rounded,
      isSchoolItem: true,
      gradient: AppTheme.greenMintGradient,
    ),
    const MatchItem(
      id: 'it_5',
      labelEn: 'Teddy Bear Toy',
      labelUr: 'ٹیڈی بیئر کھلونا',
      icon: Icons.smart_toy_rounded,
      isSchoolItem: false,
      gradient: AppTheme.calmLavenderGradient,
    ),
  ];

  int _currentIndex = 0;
  bool _isAnsweredCorrectly = false;
  bool _isWigglingWrong = false;

  @override
  void initState() {
    super.initState();
    _speakCurrentItem();
  }

  void _speakCurrentItem() {
    final isUrdu = LocalizationService.instance.isUrdu;
    final item = _items[_currentIndex];
    TtsService.instance.speak(
      isUrdu
          ? '${item.labelUr}۔ کیا یہ اسکول کی چیز ہے؟'
          : '${item.labelEn}. Is this a school item?',
      langCode: isUrdu ? 'ur' : 'en',
    );
  }

  void _onAnswerSelected(bool selectedIsSchool) {
    if (_isAnsweredCorrectly) return;

    final currentItem = _items[_currentIndex];
    final isUrdu = LocalizationService.instance.isUrdu;

    if (selectedIsSchool == currentItem.isSchoolItem) {
      // Correct Answer
      setState(() {
        _isAnsweredCorrectly = true;
        _isWigglingWrong = false;
      });

      if (currentItem.isSchoolItem) {
        TtsService.instance.speak(
          isUrdu ? 'شاباش! ${currentItem.labelUr} اسکول بیگ میں جائے گا!' : 'Super! ${currentItem.labelEn} goes into the school bag!',
          langCode: isUrdu ? 'ur' : 'en',
        );
      } else {
        TtsService.instance.speak(
          isUrdu ? 'بالکل ٹھیک! ${currentItem.labelUr} گھر پر رہے گا!' : 'Correct! ${currentItem.labelEn} stays at home!',
          langCode: isUrdu ? 'ur' : 'en',
        );
      }

      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;

        if (_currentIndex < _items.length - 1) {
          setState(() {
            _currentIndex++;
            _isAnsweredCorrectly = false;
          });
          _speakCurrentItem();
        } else {
          // All items sorted
          TtsService.instance.speak(
            isUrdu ? 'شاندار! آپ نے تمام چیزیں بالکل درست پہچان لیں!' : 'Superstar! All items sorted perfectly! Fantastic job!',
            langCode: isUrdu ? 'ur' : 'en',
          );
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) widget.onGameCompleted();
          });
        }
      });
    } else {
      // Gentle wrong feedback
      setState(() {
        _isWigglingWrong = true;
      });

      if (currentItem.isSchoolItem) {
        TtsService.instance.speak(
          isUrdu ? 'آئیں دوبارہ سوچیں! کیا ہم ${currentItem.labelUr} اسکول لے جاتے ہیں؟' : 'Let\'s think! Do we take ${currentItem.labelEn} to school? Try again!',
          langCode: isUrdu ? 'ur' : 'en',
        );
      } else {
        TtsService.instance.speak(
          isUrdu ? 'آئیں سوچیں! کیا ${currentItem.labelUr} اسکول کی چیز ہے؟ دوبارہ کوشش کریں!' : 'Let\'s think! Is ${currentItem.labelEn} a school item? Try again!',
          langCode: isUrdu ? 'ur' : 'en',
        );
      }

      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _isWigglingWrong = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = LocalizationService.instance.isUrdu;
    final prompt = isUrdu ? widget.promptUr : widget.promptEn;
    final currentItem = _items[_currentIndex];

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
            border: Border.all(color: AppTheme.mintGreen.withValues(alpha: 0.35), width: 1.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.backpack_rounded, color: AppTheme.primaryOrange, size: 26),
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

        // Progress Pill Tracker
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppTheme.softCardShadow,
          ),
          child: Row(
            children: [
              Text(
                isUrdu ? 'چیز ${_currentIndex + 1} از ${_items.length}' : 'Item ${_currentIndex + 1} of ${_items.length}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: List.generate(_items.length, (idx) {
                    final isDone = idx < _currentIndex;
                    final isCurrent = idx == _currentIndex;

                    return Expanded(
                      child: Container(
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: isDone
                              ? AppTheme.mintGreen
                              : (isCurrent ? AppTheme.primaryOrange : Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Single Active Item Card
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) {
            return ScaleTransition(scale: animation, child: FadeTransition(opacity: animation, child: child));
          },
          child: Container(
            key: ValueKey<int>(_currentIndex),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: AppTheme.softCardShadow,
              border: Border.all(
                color: _isAnsweredCorrectly
                    ? AppTheme.mintGreen
                    : currentItem.gradient.colors.first.withValues(alpha: 0.35),
                width: 2.5,
              ),
            ),
            child: Column(
              children: [
                // Item Visual Container
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: currentItem.gradient,
                    boxShadow: AppTheme.heavyShadow(currentItem.gradient.colors.first, opacity: 0.4, blur: 18),
                  ),
                  child: Center(
                    child: Icon(
                      currentItem.icon,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                ).animate(target: _isWigglingWrong ? 1 : 0).shake(duration: 400.ms, curve: Curves.easeInOut),

                const SizedBox(height: 16),

                // Item Name (Urdu & English)
                Text(
                  isUrdu ? currentItem.labelUr : currentItem.labelEn,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  isUrdu ? currentItem.labelEn : currentItem.labelUr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),

                const SizedBox(height: 12),

                // Question pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.scaffoldBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isUrdu ? 'کیا یہ اسکول کی چیز ہے؟' : 'Is this for school?',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

        // Big Option Buttons Right Below Item
        Row(
          children: [
            // Button 1: School Item (🎒 اسکول کی چیز)
            Expanded(
              child: SizedBox(
                height: 70,
                child: ElevatedButton(
                  onPressed: () => _onAnswerSelected(true),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 4,
                    shadowColor: AppTheme.electricBlue.withValues(alpha: 0.4),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: AppTheme.blueCyanGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.backpack_rounded, color: Colors.white, size: 22),
                              SizedBox(width: 6),
                              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isUrdu ? 'اسکول کی چیز' : 'School Item',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Button 2: Not School Item (🏠 گھر کی چیز)
            Expanded(
              child: SizedBox(
                height: 70,
                child: ElevatedButton(
                  onPressed: () => _onAnswerSelected(false),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 4,
                    shadowColor: AppTheme.primaryOrange.withValues(alpha: 0.4),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: AppTheme.orangePinkGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.home_rounded, color: Colors.white, size: 22),
                              SizedBox(width: 6),
                              Icon(Icons.cancel_rounded, color: Colors.white, size: 18),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isUrdu ? 'گھر کی چیز' : 'Not for School',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}
