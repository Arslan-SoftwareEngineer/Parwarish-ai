import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'models/child_model.dart';
import 'models/schedule_item_model.dart';
import 'models/badge_model.dart';
import 'services/localization_service.dart';
import 'services/auth_service.dart';
import 'services/tts_service.dart';
import 'widgets/companion_pet_widget.dart';
import 'widgets/adaptive_tile_widget.dart';
import 'child_profile_selection.dart';
import 'child_login_screen.dart';
import 'lesson_screen.dart';
import 'theme/app_theme.dart';

class ChildDashboard extends StatefulWidget {
  final ChildModel child;

  const ChildDashboard({super.key, required this.child});

  @override
  State<ChildDashboard> createState() => _ChildDashboardState();
}

class _ChildDashboardState extends State<ChildDashboard> {
  int _currentTabIndex = 0;
  int _starCoins = 150;
  bool _isPetHappy = false;
  late ChildModel _currentChild;

  // Daily Routine Schedule items
  late List<ScheduleItemModel> _scheduleItems;

  // Gamified Badges
  late List<BadgeModel> _badges;

  @override
  void initState() {
    super.initState();
    _currentChild = widget.child;
    _initSchedule();
    _initBadges();
  }

  void _initSchedule() {
    _scheduleItems = [
      const ScheduleItemModel(
        id: 'sch_1',
        titleEn: 'Step-by-Step Handwashing Sequence',
        titleUr: 'ہاتھ دھونے کے جادوئی مراحل',
        time: '08:00 AM',
        icon: Icons.soap_rounded,
        gradient: AppTheme.blueCyanGradient,
        isCompleted: true,
      ),
      const ScheduleItemModel(
        id: 'sch_2',
        titleEn: 'Big Bright Happy Smile Mirror',
        titleUr: 'خوبصورت مسکراہٹ کیمرہ مشن',
        time: '10:00 AM',
        icon: Icons.face_rounded,
        gradient: AppTheme.sunshineGradient,
        isCompleted: true,
      ),
      const ScheduleItemModel(
        id: 'sch_3',
        titleEn: 'Sensory 4-Count Zen Breathing',
        titleUr: 'پرسکون گہرا سانس اور بلبلے',
        time: '02:00 PM',
        icon: Icons.air_rounded,
        gradient: AppTheme.greenMintGradient,
        isCompleted: false,
      ),
      const ScheduleItemModel(
        id: 'sch_4',
        titleEn: 'School Backpack Sorting Challenge',
        titleUr: 'اسکول بستہ پیکنگ مشن',
        time: '05:00 PM',
        icon: Icons.backpack_rounded,
        gradient: AppTheme.purpleBlueGradient,
        isCompleted: false,
      ),
      const ScheduleItemModel(
        id: 'sch_5',
        titleEn: 'Shoelace Knot & Fine Motor Tracing',
        titleUr: 'تسمے باندھنے کی مشق',
        time: '08:30 PM',
        icon: Icons.gesture_rounded,
        gradient: AppTheme.orangePinkGradient,
        isCompleted: false,
      ),
    ];
  }

  void _initBadges() {
    _badges = [
      const BadgeModel(
        id: 'bdg_1',
        titleEn: 'Streak Warrior',
        titleUr: 'تسلسل کا چیمپئن',
        descriptionEn: 'Kept daily mission streak alive!',
        descriptionUr: 'مسلسل دنوں تک مشنز مکمل کیے!',
        icon: Icons.local_fire_department_rounded,
        gradient: AppTheme.orangePinkGradient,
        isUnlocked: true,
      ),
      const BadgeModel(
        id: 'bdg_2',
        titleEn: 'Emotion Master',
        titleUr: 'مسکراہٹ اور جذبات کے ماہر',
        descriptionEn: 'Shared bright smiles with the camera!',
        descriptionUr: 'کیمرے میں خوبصورت مسکراہٹ دکھائی!',
        icon: Icons.face_retouching_natural_rounded,
        gradient: AppTheme.sunshineGradient,
        isUnlocked: true,
      ),
      const BadgeModel(
        id: 'bdg_3',
        titleEn: 'Hygiene Hero',
        titleUr: 'صفائی کے ہیرو',
        descriptionEn: 'Mastered hand washing sequence!',
        descriptionUr: 'ہاتھ دھونے کے مراحل مکمل کیے!',
        icon: Icons.clean_hands_rounded,
        gradient: AppTheme.greenMintGradient,
        isUnlocked: true,
      ),
      const BadgeModel(
        id: 'bdg_4',
        titleEn: 'Super Organizer',
        titleUr: 'منظم سپر اسٹار',
        descriptionEn: 'Sorted school bag essentials!',
        descriptionUr: 'اسکول بیگ ترتیب دیا!',
        icon: Icons.backpack_rounded,
        gradient: AppTheme.blueCyanGradient,
        isUnlocked: false,
      ),
      const BadgeModel(
        id: 'bdg_5',
        titleEn: 'Zen Zen Calm',
        titleUr: 'پرسکون سانس کا بیج',
        descriptionEn: 'Completed sensory breathing cycles!',
        descriptionUr: 'پرسکون سانس لینے کی مشقیں مکمل کیں!',
        icon: Icons.air_rounded,
        gradient: AppTheme.purpleBlueGradient,
        isUnlocked: true,
      ),
    ];
  }

  void _triggerHappyPetCelebration() {
    setState(() {
      _isPetHappy = true;
      _starCoins += 50;
    });

    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() => _isPetHappy = false);
      }
    });
  }

  Future<void> _startInteractiveMission({
    required String moduleName,
    required String gameType,
    required Map<String, String> localizedPrompts,
    String? domainId,
  }) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LessonScreen(
          childId: _currentChild.id,
          moduleName: moduleName,
          interactionType: gameType,
          localizedPrompts: localizedPrompts,
          domainId: domainId,
        ),
      ),
    );

    if (result == true) {
      _triggerHappyPetCelebration();
    }
  }

  List<Widget> _buildPrescribedInteractiveGames() {
    return [
      // 1. Emotion Mirror Game
      AdaptiveTileWidget(
        titleEn: 'Happy Smile Mirror Mission',
        titleUr: 'خوبصورت مسکراہٹ کیمرہ مشن',
        descriptionEn: 'Look into the camera and share your brightest superstar smile!',
        descriptionUr: 'کیمرے میں دیکھیں اور اپنی پیاری مسکراہٹ دکھائیں!',
        icon: Icons.sentiment_very_satisfied_rounded,
        gradient: AppTheme.sunshineGradient,
        interactionType: 'camera',
        onTap: () => _startInteractiveMission(
          moduleName: 'Happy Smile Mirror Mission',
          gameType: 'emotion_mirror',
          localizedPrompts: {
            'en': 'Show your brightest smile to the friendly camera!',
            'ur': 'کیمرے کے سامنے اپنی خوبصورت مسکراہٹ لائیں!',
          },
          domainId: 'dom_04',
        ),
      ),

      // 2. Drag-and-Drop Sequencing Game
      AdaptiveTileWidget(
        titleEn: 'Step-by-Step Handwashing Order',
        titleUr: 'ہاتھ دھونے کے جادوئی مراحل',
        descriptionEn: 'Order: Water On &rarr; Soap Rub &rarr; Rinse &rarr; Towel Dry!',
        descriptionUr: 'پانی &rarr; صابن &rarr; دھونا &rarr; تولیہ۔',
        icon: Icons.soap_rounded,
        gradient: AppTheme.blueCyanGradient,
        interactionType: 'drag_sequence',
        onTap: () => _startInteractiveMission(
          moduleName: 'Step-by-Step Handwashing Order',
          gameType: 'drag_sequence',
          localizedPrompts: {
            'en': 'Put the handwashing steps in the correct magic order!',
            'ur': 'ہاتھ دھونے کے مراحل کو درست ترتیب میں رکھیں!',
          },
          domainId: 'dom_09',
        ),
      ),

      // 3. Sensory Breathe & Bubble Pop Game
      AdaptiveTileWidget(
        titleEn: 'Sensory 4-Count Zen Breathing',
        titleUr: 'پرسکون گہرا سانس اور بلبلے',
        descriptionEn: 'Breathe with glowing ring and tap soothing pastel bubbles!',
        descriptionUr: 'دائرے کے ساتھ پرسکون سانس لیں اور بلبلے پھوڑیں۔',
        icon: Icons.air_rounded,
        gradient: AppTheme.greenMintGradient,
        interactionType: 'breathe',
        onTap: () => _startInteractiveMission(
          moduleName: 'Sensory 4-Count Zen Breathing',
          gameType: 'sensory_breathe',
          localizedPrompts: {
            'en': 'Breathe gently in with the ring and out softly.',
            'ur': 'دائرے کے ساتھ گہرا سانس لیں اور آرام سے نکالیں۔',
          },
          domainId: 'dom_17',
        ),
      ),

      // 4. Voice & Phonics Challenge
      AdaptiveTileWidget(
        titleEn: 'Voice Phonics: "Clean & Fresh!"',
        titleUr: 'آواز کی مشق: "میرے ہاتھ صاف ہیں!"',
        descriptionEn: 'Speak clearly into the microphone to power up the soundwave star!',
        descriptionUr: 'مائیکروفون میں بول کر تارہ روشن کریں!',
        icon: Icons.record_voice_over_rounded,
        gradient: AppTheme.orangePinkGradient,
        interactionType: 'voice',
        onTap: () => _startInteractiveMission(
          moduleName: 'Voice Phonics: "Clean & Fresh!"',
          gameType: 'voice_phonics',
          localizedPrompts: {
            'en': 'Say: "Clean and Fresh!" into the mic!',
            'ur': 'کہیں: "میرے ہاتھ صاف ہیں!"',
          },
          domainId: 'dom_02',
        ),
      ),

      // 5. Backpack Sorting Challenge
      AdaptiveTileWidget(
        titleEn: 'School Backpack Sorting Challenge',
        titleUr: 'اسکول بستہ پیکنگ مشن',
        descriptionEn: 'Sort school supplies into backpack and bedroom items to bed!',
        descriptionUr: 'کتابیں بستے میں اور تکیہ بستر پر رکھیں۔',
        icon: Icons.backpack_rounded,
        gradient: AppTheme.purpleBlueGradient,
        interactionType: 'matching_sorting',
        onTap: () => _startInteractiveMission(
          moduleName: 'School Backpack Sorting Challenge',
          gameType: 'matching_sorting',
          localizedPrompts: {
            'en': 'Sort school essentials into your backpack!',
            'ur': 'اسکول کی تمام ضروری چیزیں بستہ میں ڈالیں!',
          },
          domainId: 'dom_13',
        ),
      ),

      // 6. Tactile Line & Knot Tracing
      AdaptiveTileWidget(
        titleEn: 'Shoelace Knot & Fine Motor Tracing',
        titleUr: 'تسمے باندھنے اور لکیر کی مشق',
        descriptionEn: 'Trace finger through glowing rainbow path to tie the bunny knot!',
        descriptionUr: 'انگلی سے چمکتے راستے پر لکیر بنائیں۔',
        icon: Icons.gesture_rounded,
        gradient: AppTheme.sunshineGradient,
        interactionType: 'fine_motor_trace',
        onTap: () => _startInteractiveMission(
          moduleName: 'Shoelace Knot & Fine Motor Tracing',
          gameType: 'fine_motor_trace',
          localizedPrompts: {
            'en': 'Trace the bunny loop from start to star!',
            'ur': 'شروع سے تارے تک انگلی سے راستہ بنائیں!',
          },
          domainId: 'dom_06',
        ),
      ),
    ];
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
                  MaterialPageRoute(builder: (_) => const ChildProfileSelection()),
                );
              },
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryOrange,
                  child: Text(
                    _currentChild.name.isNotEmpty ? _currentChild.name[0].toUpperCase() : 'H',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _currentChild.name,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ],
            ),
            actions: [
              // Star Coins Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: AppTheme.sunshineGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.heavyShadow(AppTheme.amberGold, opacity: 0.3, blur: 8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '$_starCoins',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ).animate().shimmer(duration: 1500.ms),

              const SizedBox(width: 8),

              // Language Toggle Button
              IconButton(
                tooltip: 'Toggle Language',
                icon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppTheme.softCardShadow,
                  ),
                  child: Text(
                    isUrdu ? 'EN' : 'اردو',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryOrange),
                  ),
                ),
                onPressed: () => LocalizationService.instance.toggleLanguage(),
              ),

              // Switch to Parent / Therapist Settings button
              IconButton(
                tooltip: 'Switch Role',
                icon: const Icon(Icons.shield_outlined, color: AppTheme.textSecondary),
                onPressed: () async {
                  await AuthService.instance.cacheUserRole('parent');
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const ChildLoginScreen()),
                    );
                  }
                },
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: IndexedStack(
            index: _currentTabIndex,
            children: [
              // TAB 0: Learn & Play (Therapist's Prescribed Interactive Games)
              _buildLearnTab(),

              // TAB 1: Visual Daily Schedule
              _buildScheduleTab(),

              // TAB 2: Gamified Badges
              _buildBadgesTab(),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: AppTheme.softCardShadow,
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      index: 0,
                      label: tr('tab_learn'),
                      icon: Icons.sports_esports_rounded,
                      activeGradient: AppTheme.orangePinkGradient,
                    ),
                    _buildNavItem(
                      index: 1,
                      label: tr('tab_schedule'),
                      icon: Icons.calendar_month_rounded,
                      activeGradient: AppTheme.blueCyanGradient,
                    ),
                    _buildNavItem(
                      index: 2,
                      label: tr('tab_badges'),
                      icon: Icons.military_tech_rounded,
                      activeGradient: AppTheme.greenMintGradient,
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

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required LinearGradient activeGradient,
  }) {
    final isSelected = _currentTabIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentTabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? activeGradient : null,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected ? AppTheme.heavyShadow(activeGradient.colors.first, opacity: 0.3, blur: 10) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- TAB 0: Learn & Play (Interactive Games) ---
  Widget _buildLearnTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 12),

          // Lottie Pet Companion Widget
          CompanionPetWidget(
            isHappy: _isPetHappy,
          ),

          const SizedBox(height: 16),

          // Streak Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppTheme.softCardShadow,
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department_rounded, color: AppTheme.amberGold, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${_currentChild.currentStreak} Day Learning Streak! Keep shining!',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: AppTheme.sunshineGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '🌟 Champion',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Interactive Games List
          ..._buildPrescribedInteractiveGames(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // --- TAB 1: Visual Routine Schedule ---
  Widget _buildScheduleTab() {
    final isUrdu = LocalizationService.instance.isUrdu;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.blueCyanGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.heavyShadow(AppTheme.electricBlue),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded, color: Colors.white, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isUrdu ? 'آج کا تصویری شیڈول' : 'Today\'s Visual Routine',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isUrdu ? 'مراحل پر نشان لگائیں اور ستارے کمائیں' : 'Check off steps and earn star coins!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _scheduleItems.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = _scheduleItems[index];
              final title = isUrdu ? item.titleUr : item.titleEn;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.softCardShadow,
                  border: item.isCompleted
                      ? Border.all(color: AppTheme.mintGreen.withValues(alpha: 0.5), width: 1.5)
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: item.gradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(item.icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: item.isCompleted ? AppTheme.textSecondary : AppTheme.textPrimary,
                              decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.time,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        item.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        color: item.isCompleted ? AppTheme.mintGreen : AppTheme.textLight,
                        size: 28,
                      ),
                      onPressed: () {
                        setState(() {
                          _scheduleItems[index] = item.copyWith(isCompleted: !item.isCompleted);
                          if (!item.isCompleted) {
                            _starCoins += 10;
                            TtsService.instance.speak(
                              isUrdu ? 'شاباش! مرحلہ مکمل ہوا!' : 'Great job! Routine step completed!',
                              langCode: isUrdu ? 'ur' : 'en',
                            );
                          }
                        });
                      },
                    ),
                  ],
                ),
              ).animate(delay: (index * 60).ms).fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
            },
          ),
        ],
      ),
    );
  }

  // --- TAB 2: Gamified Badges ---
  Widget _buildBadgesTab() {
    final isUrdu = LocalizationService.instance.isUrdu;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.greenMintGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.heavyShadow(AppTheme.mintGreen),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isUrdu ? 'میرے انعامی بیجز' : 'My Hero Badges',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isUrdu ? 'اسباق مکمل کر کے تمام بیجز کھولیں!' : 'Unlock shiny badges as you complete lessons!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _badges.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.92,
            ),
            itemBuilder: (context, index) {
              final badge = _badges[index];
              final title = isUrdu ? badge.titleUr : badge.titleEn;
              final desc = isUrdu ? badge.descriptionUr : badge.descriptionEn;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: AppTheme.softCardShadow,
                  border: badge.isUnlocked
                      ? Border.all(color: badge.gradient.colors.first.withValues(alpha: 0.4), width: 2)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: badge.isUnlocked ? badge.gradient : null,
                        color: badge.isUnlocked ? null : Colors.grey.shade200,
                        boxShadow: badge.isUnlocked
                            ? AppTheme.heavyShadow(badge.gradient.colors.first, opacity: 0.3, blur: 12)
                            : null,
                      ),
                      child: Icon(
                        badge.icon,
                        color: badge.isUnlocked ? Colors.white : Colors.grey.shade400,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: badge.isUnlocked ? AppTheme.textPrimary : AppTheme.textLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: badge.isUnlocked ? AppTheme.textSecondary : AppTheme.textLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: badge.isUnlocked
                            ? AppTheme.mintGreen.withValues(alpha: 0.15)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge.isUnlocked ? 'Unlocked ✨' : 'Locked 🔒',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: badge.isUnlocked ? AppTheme.mintGreen : AppTheme.textLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate(delay: (index * 60).ms).fadeIn(duration: 300.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
            },
          ),
        ],
      ),
    );
  }
}
