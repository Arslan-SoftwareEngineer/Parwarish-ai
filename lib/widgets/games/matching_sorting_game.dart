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
  final String targetCategory; // 'school' or 'home'
  final LinearGradient gradient;

  const MatchItem({
    required this.id,
    required this.labelEn,
    required this.labelUr,
    required this.icon,
    required this.targetCategory,
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
  final List<MatchItem> _availableItems = [
    const MatchItem(
      id: 'it_1',
      labelEn: 'Notebook & Pencil',
      labelUr: 'کاپی اور پنسل',
      icon: Icons.menu_book_rounded,
      targetCategory: 'school',
      gradient: AppTheme.blueCyanGradient,
    ),
    const MatchItem(
      id: 'it_2',
      labelEn: 'Lunch Box',
      labelUr: 'لنچ باکس',
      icon: Icons.lunch_dining_rounded,
      targetCategory: 'school',
      gradient: AppTheme.orangePinkGradient,
    ),
    const MatchItem(
      id: 'it_3',
      labelEn: 'Soft Pillow',
      labelUr: 'نرم تکیہ',
      icon: Icons.bed_rounded,
      targetCategory: 'home',
      gradient: AppTheme.purpleBlueGradient,
    ),
    const MatchItem(
      id: 'it_4',
      labelEn: 'Teddy Bear',
      labelUr: 'ٹیڈی بیئر',
      icon: Icons.smart_toy_rounded,
      targetCategory: 'home',
      gradient: AppTheme.greenMintGradient,
    ),
  ];

  final List<MatchItem> _sortedSchool = [];
  final List<MatchItem> _sortedHome = [];

  void _sortItem(MatchItem item, String category) {
    if (item.targetCategory == category) {
      setState(() {
        _availableItems.remove(item);
        if (category == 'school') {
          _sortedSchool.add(item);
        } else {
          _sortedHome.add(item);
        }
      });

      final isUrdu = LocalizationService.instance.isUrdu;
      TtsService.instance.speak(
        isUrdu ? '${item.labelUr} بالکل درست!' : '${item.labelEn} sorted perfectly!',
        langCode: isUrdu ? 'ur' : 'en',
      );

      if (_availableItems.isEmpty) {
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) widget.onGameCompleted();
        });
      }
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
            border: Border.all(color: AppTheme.mintGreen.withValues(alpha: 0.35), width: 1.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.category_rounded, color: AppTheme.mintGreen, size: 26),
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

        // 2 Target Category Bins (School vs Home)
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.softCardShadow,
                  border: Border.all(color: AppTheme.electricBlue, width: 2),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.backpack_rounded, color: AppTheme.electricBlue, size: 30),
                    const SizedBox(height: 4),
                    Text(
                      isUrdu ? 'اسکول بیگ' : 'School Bag',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.electricBlue),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      children: _sortedSchool.map((i) => const Icon(Icons.check_circle_rounded, color: AppTheme.mintGreen, size: 20)).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.softCardShadow,
                  border: Border.all(color: AppTheme.purpleStart, width: 2),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.home_rounded, color: AppTheme.purpleStart, size: 30),
                    const SizedBox(height: 4),
                    Text(
                      isUrdu ? 'گھر کا کمرہ' : 'Home Bedroom',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.purpleStart),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      children: _sortedHome.map((i) => const Icon(Icons.check_circle_rounded, color: AppTheme.mintGreen, size: 20)).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        Text(
          isUrdu ? 'چیز پر کلک کر کے صحیح جگہ ڈالیں:' : 'Tap each item to sort into the right place:',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textSecondary),
        ),

        const SizedBox(height: 10),

        // Available items to sort
        ..._availableItems.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: item.gradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppTheme.heavyShadow(item.gradient.colors.first, opacity: 0.35, blur: 10),
              ),
              child: Row(
                children: [
                  Icon(item.icon, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isUrdu ? item.labelUr : item.labelEn,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.backpack_rounded, color: Colors.white),
                        tooltip: 'Put in School Bag',
                        onPressed: () => _sortItem(item, 'school'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.home_rounded, color: Colors.white),
                        tooltip: 'Put in Home',
                        onPressed: () => _sortItem(item, 'home'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
        }),
      ],
    );
  }
}
