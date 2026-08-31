import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'models/child_model.dart';
import 'services/firebase_service.dart';
import 'services/auth_service.dart';
import 'services/streak_service.dart';
import 'services/localization_service.dart';
import 'child_dashboard.dart';
import 'child_login_screen.dart';
import 'theme/app_theme.dart';

class ChildProfileSelection extends StatefulWidget {
  const ChildProfileSelection({super.key});

  @override
  State<ChildProfileSelection> createState() => _ChildProfileSelectionState();
}

class _ChildProfileSelectionState extends State<ChildProfileSelection> {
  List<ChildModel> _children = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    setState(() => _isLoading = true);
    final parentUid = AuthService.instance.currentUserUid;
    final list = await FirebaseService.instance.getChildrenForParent(parentUid);
    setState(() {
      _children = list;
      _isLoading = false;
    });
  }

  Future<void> _selectChild(ChildModel child) async {
    // 1. Cache child_id and autism_level locally in SharedPreferences
    await AuthService.instance.cacheActiveChild(
      childId: child.id,
      autismLevel: child.autismLevel,
    );

    // 2. Check against last_login timestamp in Firestore & calculate streak
    final newStreak = StreakService.calculateNewStreak(
      lastLogin: child.lastLogin,
      currentStreak: child.currentStreak,
    );

    final now = DateTime.now();

    // 3. Update Firestore
    await FirebaseService.instance.updateChildStreakAndLogin(
      childId: child.id,
      newStreak: newStreak,
      lastLogin: now,
    );

    final updatedChild = child.copyWith(
      currentStreak: newStreak,
      lastLogin: now,
    );

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ChildDashboard(child: updatedChild),
        ),
      );
    }
  }

  LinearGradient _getLevelGradient(String level, int index) {
    switch (level.toLowerCase()) {
      case 'severe':
        return AppTheme.severeGradient;
      case 'moderate':
        return AppTheme.moderateGradient;
      default:
        return index % 2 == 0 ? AppTheme.orangePinkGradient : AppTheme.greenMintGradient;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.instance.currentLocale,
      builder: (context, lang, _) {
        final tr = LocalizationService.instance.tr;
        final isUrdu = LocalizationService.instance.isUrdu;

        return Scaffold(
          backgroundColor: AppTheme.scaffoldBackground,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const ChildLoginScreen()),
                );
              },
            ),
            title: Text(
              tr('select_profile'),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
            ),
            actions: [
              IconButton(
                tooltip: 'Toggle Language',
                icon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppTheme.softCardShadow,
                  ),
                  child: Text(
                    isUrdu ? 'EN' : 'اردو',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryOrange),
                  ),
                ),
                onPressed: () => LocalizationService.instance.toggleLanguage(),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange))
              : SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 12),

                          // Header Companion Icon & Cheerful prompt
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: AppTheme.softCardShadow,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.stars_rounded, color: AppTheme.amberGold, size: 24),
                                const SizedBox(width: 8),
                                Text(
                                  isUrdu ? 'کھیلنے کے لیے اپنا کارڈ منتخب کریں!' : 'Tap your hero card to start!',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),

                          const SizedBox(height: 20),

                          if (_children.isEmpty)
                            Expanded(
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.child_care_rounded, size: 64, color: AppTheme.textLight),
                                      const SizedBox(height: 16),
                                      Text(
                                        tr('no_children_yet'),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          else
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                itemCount: _children.length,
                                itemBuilder: (context, index) {
                                  final child = _children[index];
                                  final gradient = _getLevelGradient(child.autismLevel, index);

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 20),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(28),
                                        onTap: () => _selectChild(child),
                                        splashColor: Colors.white.withValues(alpha: 0.3),
                                        child: Container(
                                          padding: const EdgeInsets.all(22),
                                          decoration: BoxDecoration(
                                            gradient: gradient,
                                            borderRadius: BorderRadius.circular(28),
                                            boxShadow: AppTheme.heavyShadow(gradient.colors.first, opacity: 0.38, blur: 20),
                                          ),
                                          child: Row(
                                            children: [
                                              // Large Animated Avatar
                                              Container(
                                                width: 72,
                                                height: 72,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                  boxShadow: AppTheme.heavyShadow(Colors.black, opacity: 0.1),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    child.name.isNotEmpty ? child.name[0].toUpperCase() : 'H',
                                                    style: TextStyle(
                                                      fontSize: 32,
                                                      fontWeight: FontWeight.w900,
                                                      color: gradient.colors.first,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 20),

                                              // Name & Streak Info
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      child.name,
                                                      style: const TextStyle(
                                                        fontSize: 24,
                                                        fontWeight: FontWeight.w900,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Row(
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: Colors.black.withValues(alpha: 0.22),
                                                            borderRadius: BorderRadius.circular(12),
                                                          ),
                                                          child: Text(
                                                            'Level: ${child.autismLevel}',
                                                            style: const TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: Colors.white.withValues(alpha: 0.25),
                                                            borderRadius: BorderRadius.circular(12),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              const Icon(
                                                                Icons.local_fire_department_rounded,
                                                                color: AppTheme.amberGold,
                                                                size: 16,
                                                              ),
                                                              const SizedBox(width: 4),
                                                              Text(
                                                                '${child.currentStreak} ${tr('days')}',
                                                                style: const TextStyle(
                                                                  color: Colors.white,
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 12,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // Play Button Arrow
                                              Container(
                                                width: 46,
                                                height: 46,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                  boxShadow: AppTheme.softCardShadow,
                                                ),
                                                child: Icon(
                                                  Icons.play_arrow_rounded,
                                                  color: gradient.colors.first,
                                                  size: 32,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                      .animate(delay: (index * 100).ms)
                                      .fadeIn(duration: 400.ms)
                                      .scale(begin: const Offset(0.92, 0.92), end: const Offset(1, 1), curve: Curves.easeOutBack);
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
