import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/child_model.dart';
import '../../models/daily_session_model.dart';
import '../../theme/app_theme.dart';
import '../../services/localization_service.dart';
import '../../services/clinical_service.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import 'lesson_screen.dart';
import '../welcome_screen.dart';
import '../games/games_registry.dart';
import '../settings/child_settings_screen.dart';
import 'child_profile_selection.dart';

class AdaptiveLessonItem {
  final String title;
  final String titleUrdu;
  final String interactionType; // 'voice', 'camera', 'breathe'
  final String videoUrl;
  final String englishPrompt;
  final String urduPrompt;
  final IconData icon;
  final LinearGradient gradient;

  const AdaptiveLessonItem({
    required this.title,
    required this.titleUrdu,
    required this.interactionType,
    required this.videoUrl,
    required this.englishPrompt,
    required this.urduPrompt,
    required this.icon,
    required this.gradient,
  });
}

class ChildDashboard extends StatefulWidget {
  final ChildModel? child;

  const ChildDashboard({super.key, this.child});

  @override
  State<ChildDashboard> createState() => _ChildDashboardState();
}

class _ChildDashboardState extends State<ChildDashboard> {
  String _childId = 'child_demo_01';
  String _childName = 'Aayan';
  String _autismLevel = 'Moderate';
  int _currentStreak = 4;

  bool isUrdu = false;
  bool isCelebrating = false;
  int _currentTabIndex = 0;
  Timer? _celebrationTimer;

  // Active clinical goals assigned by therapist
  List<ActiveGoalItem> _activeGoals = [];
  List<AdaptiveLessonItem> _assignedQuests = [];
  List<GameMetadata> _assignedGames = [];

  // Dynamic visual schedule items state (auto-marked on quest/game completion)
  final Map<String, bool> _scheduleCompletion = {};

  @override
  void initState() {
    super.initState();
    _initChildProfile();
  }

  @override
  void dispose() {
    _celebrationTimer?.cancel();
    super.dispose();
  }

  Future<void> _initChildProfile() async {
    final prefs = await SharedPreferences.getInstance();

    if (widget.child != null) {
      _childId = widget.child!.id;
      _childName = widget.child!.name;
      _autismLevel = widget.child!.autismLevel;
      _currentStreak = widget.child!.currentStreak;

      await prefs.setString('child_id', _childId);
      await prefs.setString('child_name', _childName);
      await prefs.setString('autism_level', _autismLevel);
    } else {
      _childId = prefs.getString('child_id') ?? 'child_demo_01';
      _childName = prefs.getString('child_name') ?? 'Aayan';
      _autismLevel = prefs.getString('autism_level') ?? 'Moderate';
    }

    // Load therapist-assigned goals for this child (Requirement 3)
    final goals = await ClinicalService.instance.fetchChildGoals(_childId);
    if (goals.isNotEmpty) {
      _activeGoals = goals;
    } else {
      _activeGoals = _getDefaultGoalsForLevel(_autismLevel);
    }

    _assignedQuests = _getTherapistAssignedQuests();
    _assignedGames = _getTherapistAssignedGames();

    await _initSchedule();

    if (mounted) setState(() {});
  }

  List<ActiveGoalItem> _getDefaultGoalsForLevel(String level) {
    switch (level.toLowerCase()) {
      case 'severe':
        return [
          ActiveGoalItem(
            goalId: 'g_06_02',
            domainId: 6,
            domainName: 'Emotional Recognition',
            goalTitle: 'Emotions Mirror',
            assignedAt: DateTime.now(),
          ),
          ActiveGoalItem(
            goalId: 'g_08_01',
            domainId: 8,
            domainName: 'ADL Hygiene',
            goalTitle: 'Wash Hands',
            assignedAt: DateTime.now(),
          ),
          ActiveGoalItem(
            goalId: 'g_07_01',
            domainId: 7,
            domainName: 'Sensory Regulation',
            goalTitle: 'Calm Down',
            assignedAt: DateTime.now(),
          ),
        ];
      case 'mild':
        return [
          ActiveGoalItem(
            goalId: 'g_09_01',
            domainId: 9,
            domainName: 'Fine Motor / Dressing',
            goalTitle: 'Tie Shoes',
            assignedAt: DateTime.now(),
          ),
          ActiveGoalItem(
            goalId: 'g_08_02',
            domainId: 8,
            domainName: 'Personal Hygiene',
            goalTitle: 'Brush Hair',
            assignedAt: DateTime.now(),
          ),
          ActiveGoalItem(
            goalId: 'g_14_01',
            domainId: 14,
            domainName: 'Organization',
            goalTitle: 'Pack Bag',
            assignedAt: DateTime.now(),
          ),
        ];
      case 'moderate':
      default:
        return [
          ActiveGoalItem(
            goalId: 'g_08_01',
            domainId: 8,
            domainName: 'ADL Hygiene',
            goalTitle: 'Wash Hands',
            assignedAt: DateTime.now(),
          ),
          ActiveGoalItem(
            goalId: 'g_09_02',
            domainId: 9,
            domainName: 'Dressing',
            goalTitle: 'Dress Up',
            assignedAt: DateTime.now(),
          ),
          ActiveGoalItem(
            goalId: 'g_11_01',
            domainId: 11,
            domainName: 'Eating Routine',
            goalTitle: 'Eating Routine',
            assignedAt: DateTime.now(),
          ),
        ];
    }
  }

  AdaptiveLessonItem _createQuestForGoal(ActiveGoalItem goal) {
    final titleLower = goal.goalTitle.toLowerCase();
    final domain = goal.domainId;

    if (titleLower.contains('hand') || titleLower.contains('wash') || domain == 8) {
      return const AdaptiveLessonItem(
        title: 'Wash Hands',
        titleUrdu: 'ہاتھ دھونا',
        interactionType: 'voice',
        videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
        englishPrompt: 'Say "Clean bubbles" while washing your hands!',
        urduPrompt: 'ہاتھ دھوتے وقت کہیں "صاف جھاگ"!',
        icon: Icons.clean_hands_rounded,
        gradient: AppTheme.blueCyanGradient,
      );
    } else if (titleLower.contains('breath') || titleLower.contains('calm') || domain == 7) {
      return const AdaptiveLessonItem(
        title: 'Calm Down',
        titleUrdu: 'پرسکون سانس',
        interactionType: 'breathe',
        videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
        englishPrompt: 'Breathe in slowly like smelling a sweet flower.',
        urduPrompt: 'پھول سونگھنے کی طرح آہستہ سے گہرا سانس لیں۔',
        icon: Icons.air_rounded,
        gradient: AppTheme.greenMintGradient,
      );
    } else if (titleLower.contains('emotion') || titleLower.contains('facial') || domain == 6) {
      return const AdaptiveLessonItem(
        title: 'Emotions Mirror',
        titleUrdu: 'جذبات کا آئینہ',
        interactionType: 'camera',
        videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
        englishPrompt: 'Look at the mirror and smile with joy!',
        urduPrompt: 'آئینے میں دیکھیں اور خوشی سے مسکرائیں!',
        icon: Icons.face_rounded,
        gradient: AppTheme.orangePinkGradient,
      );
    } else if (titleLower.contains('shoe') || titleLower.contains('tie')) {
      return const AdaptiveLessonItem(
        title: 'Tie Shoes',
        titleUrdu: 'جوتے کے تسمے باندھنا',
        interactionType: 'voice',
        videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
        englishPrompt: 'Say "Loop and pull" to tie your laces tight!',
        urduPrompt: 'تسمے باندھتے ہوئے کہیں "لوپ اور کھینچیں"!',
        icon: Icons.sports_martial_arts_rounded,
        gradient: AppTheme.purpleBlueGradient,
      );
    } else if (titleLower.contains('hair') || titleLower.contains('brush hair')) {
      return const AdaptiveLessonItem(
        title: 'Brush Hair',
        titleUrdu: 'بالوں میں کنگھی کرنا',
        interactionType: 'voice',
        videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
        englishPrompt: 'Say "Looking neat" when brushing your hair!',
        urduPrompt: 'کنگھی کرتے ہوئے کہیں "صاف ستھرا انداز"!',
        icon: Icons.brush_rounded,
        gradient: AppTheme.orangePinkGradient,
      );
    } else if (titleLower.contains('bag') || titleLower.contains('pack')) {
      return const AdaptiveLessonItem(
        title: 'Pack Bag',
        titleUrdu: 'بستہ تیار کرنا',
        interactionType: 'voice',
        videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
        englishPrompt: 'Say "Books and bottle ready" for school!',
        urduPrompt: 'کہیں "کتابیں اور بوتل تیار ہیں"!',
        icon: Icons.backpack_rounded,
        gradient: AppTheme.blueCyanGradient,
      );
    } else if (titleLower.contains('toilet') || domain == 10) {
      return const AdaptiveLessonItem(
        title: 'Toilet Routine',
        titleUrdu: 'بیت الخلاء کی روٹین',
        interactionType: 'voice',
        videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
        englishPrompt: 'Say "Wash hands" after using the bathroom!',
        urduPrompt: 'بیت الخلاء کے بعد کہیں "ہاتھ دھوئیں"!',
        icon: Icons.water_drop_rounded,
        gradient: AppTheme.blueCyanGradient,
      );
    } else if (titleLower.contains('dress') || titleLower.contains('clothes')) {
      return const AdaptiveLessonItem(
        title: 'Dress Up',
        titleUrdu: 'کپڑے پہننا',
        interactionType: 'voice',
        videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
        englishPrompt: 'Say "Shirt on" as you wear your clean clothes!',
        urduPrompt: 'کپڑے پہنتے وقت کہیں "شرٹ پہن لی"!',
        icon: Icons.checkroom_rounded,
        gradient: AppTheme.orangePinkGradient,
      );
    } else if (titleLower.contains('eat') || titleLower.contains('food')) {
      return const AdaptiveLessonItem(
        title: 'Eating Routine',
        titleUrdu: 'کھانا کھانے کی روٹین',
        interactionType: 'voice',
        videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
        englishPrompt: 'Say "Thank you for healthy food" before eating!',
        urduPrompt: 'کھانے سے پہلے کہیں "شکریہ مزیدار کھانے کے لیے"!',
        icon: Icons.restaurant_rounded,
        gradient: AppTheme.greenMintGradient,
      );
    } else {
      return AdaptiveLessonItem(
        title: goal.goalTitle,
        titleUrdu: goal.goalTitle,
        interactionType: 'voice',
        videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
        englishPrompt: 'Let\'s practice: ${goal.goalTitle}',
        urduPrompt: 'آئیے مشق کریں: ${goal.goalTitle}',
        icon: Icons.star_rounded,
        gradient: AppTheme.purpleBlueGradient,
      );
    }
  }

  GameMetadata? _getGameForGoal(ActiveGoalItem goal) {
    final title = goal.goalTitle.toLowerCase();
    final domain = goal.domainId;

    if (title.contains('hand') || title.contains('wash') || domain == 8) {
      return GamesRegistry.getGameById('wash_hands');
    } else if (title.contains('teeth') || title.contains('brush teeth')) {
      return GamesRegistry.getGameById('brush_teeth');
    } else if (title.contains('laundry') || domain == 16) {
      return GamesRegistry.getGameById('laundry_sort');
    } else if (title.contains('breath') || domain == 7) {
      return GamesRegistry.getGameById('breathing_flower');
    } else if (title.contains('bubble')) {
      return GamesRegistry.getGameById('pop_bubbles');
    } else if (title.contains('bag') || title.contains('pack')) {
      return GamesRegistry.getGameById('pack_bag');
    } else if (title.contains('tower') || title.contains('ring')) {
      return GamesRegistry.getGameById('shape_tower');
    } else if (title.contains('fruit') || domain == 17) {
      return GamesRegistry.getGameById('fruit_merge');
    } else if (title.contains('toy') || title.contains('cleanup') || domain == 14) {
      return GamesRegistry.getGameById('toy_chest_cleanup');
    } else if (title.contains('vehicle') || title.contains('car')) {
      return GamesRegistry.getGameById('build_vehicle');
    } else if (title.contains('shadow') || domain == 18) {
      return GamesRegistry.getGameById('shadow_match');
    }
    return null;
  }

  List<AdaptiveLessonItem> _getTherapistAssignedQuests() {
    final quests = <AdaptiveLessonItem>[];
    final seen = <String>{};

    for (final goal in _activeGoals) {
      final q = _createQuestForGoal(goal);
      if (!seen.contains(q.title)) {
        seen.add(q.title);
        quests.add(q);
      }
    }

    if (quests.isEmpty) {
      return _getLessonsForAutismLevel(_autismLevel);
    }
    return quests;
  }

  List<GameMetadata> _getTherapistAssignedGames() {
    final games = <GameMetadata>[];
    final seen = <String>{};

    for (final goal in _activeGoals) {
      final g = _getGameForGoal(goal);
      if (g != null && !seen.contains(g.id)) {
        seen.add(g.id);
        games.add(g);
      }
    }

    if (games.isEmpty) {
      final defaultGame = GamesRegistry.getGameById('wash_hands');
      if (defaultGame != null) games.add(defaultGame);
    }
    return games;
  }

  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  Future<void> _initSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayKey();
    final prefKey = 'schedule_completion_${_childId}_$today';

    _scheduleCompletion.clear();
    _scheduleCompletion['Morning Routine: Wake Up & Stretch'] = true;
    for (final q in _assignedQuests) {
      _scheduleCompletion['Quest: ${q.title}'] = false;
    }
    for (final g in _assignedGames) {
      _scheduleCompletion['Game: ${g.titleEn}'] = false;
    }
    _scheduleCompletion['Evening: Bedtime Story & Rest'] = false;

    final savedList = prefs.getStringList(prefKey);
    if (savedList != null) {
      for (final item in savedList) {
        if (_scheduleCompletion.containsKey(item)) {
          _scheduleCompletion[item] = true;
        }
      }
    }
  }

  Future<void> _persistSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayKey();
    final prefKey = 'schedule_completion_${_childId}_$today';
    final completed = _scheduleCompletion.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
    await prefs.setStringList(prefKey, completed);
  }

  void _markScheduleItemCompleted(String name, {required bool isGame}) {
    bool found = false;
    final search = name.toLowerCase();

    for (final key in _scheduleCompletion.keys.toList()) {
      final keyLower = key.toLowerCase();
      if (keyLower.contains(search)) {
        _scheduleCompletion[key] = true;
        found = true;
      }
    }

    if (!found) {
      _scheduleCompletion['${isGame ? "Game: " : "Quest: "}$name'] = true;
    }

    _persistSchedule();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Schedule auto-marked: $name completed!'),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  void _toggleLanguage() {
    setState(() {
      isUrdu = !isUrdu;
    });
    LocalizationService.instance.toggleLanguage();
  }

  List<AdaptiveLessonItem> _getLessonsForAutismLevel(String level) {
    switch (level.toLowerCase()) {
      case 'severe':
        return [
          const AdaptiveLessonItem(
            title: 'Emotions Mirror',
            titleUrdu: 'جذبات کا آئینہ',
            interactionType: 'camera',
            videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
            englishPrompt: 'Look at the mirror and smile with joy!',
            urduPrompt: 'آئینے میں دیکھیں اور خوشی سے مسکرائیں!',
            icon: Icons.face_rounded,
            gradient: AppTheme.orangePinkGradient,
          ),
          const AdaptiveLessonItem(
            title: 'Toilet Routine',
            titleUrdu: 'بیت الخلاء کی روٹین',
            interactionType: 'voice',
            videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
            englishPrompt: 'Say "Wash hands" after using the bathroom!',
            urduPrompt: 'بیت الخلاء کے بعد کہیں "ہاتھ دھوئیں"!',
            icon: Icons.water_drop_rounded,
            gradient: AppTheme.blueCyanGradient,
          ),
          const AdaptiveLessonItem(
            title: 'Calm Down',
            titleUrdu: 'پرسکون سانس',
            interactionType: 'breathe',
            videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
            englishPrompt: 'Breathe in slowly like smelling a sweet flower.',
            urduPrompt: 'پھول سونگھنے کی طرح آہستہ سے گہرا سانس لیں۔',
            icon: Icons.air_rounded,
            gradient: AppTheme.greenMintGradient,
          ),
        ];

      case 'mild':
        return [
          const AdaptiveLessonItem(
            title: 'Tie Shoes',
            titleUrdu: 'جوتے کے تسمے باندھنا',
            interactionType: 'voice',
            videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
            englishPrompt: 'Say "Loop and pull" to tie your laces tight!',
            urduPrompt: 'تسمے باندھتے ہوئے کہیں "لوپ اور کھینچیں"!',
            icon: Icons.sports_martial_arts_rounded,
            gradient: AppTheme.purpleBlueGradient,
          ),
          const AdaptiveLessonItem(
            title: 'Brush Hair',
            titleUrdu: 'بالوں میں کنگھی کرنا',
            interactionType: 'voice',
            videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
            englishPrompt: 'Say "Looking neat" when brushing your hair!',
            urduPrompt: 'کنگھی کرتے ہوئے کہیں "صاف ستھرا انداز"!',
            icon: Icons.brush_rounded,
            gradient: AppTheme.orangePinkGradient,
          ),
          const AdaptiveLessonItem(
            title: 'Pack Bag',
            titleUrdu: 'بستہ تیار کرنا',
            interactionType: 'voice',
            videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
            englishPrompt: 'Say "Books and bottle ready" for school!',
            urduPrompt: 'کہیں "کتابیں اور بوتل تیار ہیں"!',
            icon: Icons.backpack_rounded,
            gradient: AppTheme.blueCyanGradient,
          ),
        ];

      case 'moderate':
      default:
        return [
          const AdaptiveLessonItem(
            title: 'Wash Hands',
            titleUrdu: 'ہاتھ دھونا',
            interactionType: 'voice',
            videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
            englishPrompt: 'Say "Clean bubbles" while washing your hands!',
            urduPrompt: 'ہاتھ دھوتے وقت کہیں "صاف جھاگ"!',
            icon: Icons.clean_hands_rounded,
            gradient: AppTheme.blueCyanGradient,
          ),
          const AdaptiveLessonItem(
            title: 'Dress Up',
            titleUrdu: 'کپڑے پہننا',
            interactionType: 'voice',
            videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
            englishPrompt: 'Say "Shirt on" as you wear your clean clothes!',
            urduPrompt: 'کپڑے پہنتے وقت کہیں "شرٹ پہن لی"!',
            icon: Icons.checkroom_rounded,
            gradient: AppTheme.orangePinkGradient,
          ),
          const AdaptiveLessonItem(
            title: 'Eating Routine',
            titleUrdu: 'کھانا کھانے کی روٹین',
            interactionType: 'voice',
            videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
            englishPrompt: 'Say "Thank you for healthy food" before eating!',
            urduPrompt: 'کھانے سے پہلے کہیں "شکریہ مزیدار کھانے کے لیے"!',
            icon: Icons.restaurant_rounded,
            gradient: AppTheme.greenMintGradient,
          ),
        ];
    }
  }

  Future<void> _openLesson(AdaptiveLessonItem item) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => LessonScreen(
          lessonTitle: item.title,
          videoUrl: item.videoUrl,
          englishPrompt: item.englishPrompt,
          urduPrompt: item.urduPrompt,
          interactionType: item.interactionType,
          isUrdu: isUrdu,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {
        isCelebrating = true;
        _currentStreak += 1;
        _completedDailyActivities += 1;
        // Auto-mark quest completion in schedule (Requirement 4)
        _markScheduleItemCompleted(item.title, isGame: false);
      });
      _celebrationTimer?.cancel();
      _celebrationTimer = Timer(const Duration(minutes: 2), () {
        if (mounted) {
          setState(() => isCelebrating = false);
        }
      });
    }
  }

  Future<void> _openAdlGame(String gameId) async {
    final game = GamesRegistry.getGameById(gameId);
    final result = await GamesRegistry.openGame(
      context,
      gameId,
      childId: _childId,
      isUrdu: isUrdu,
    );

    if (result == true && mounted) {
      setState(() {
        isCelebrating = true;
        _currentStreak += 1;
        _completedDailyActivities += 1;
        // Auto-mark game completion in schedule (Requirement 4)
        if (game != null) {
          _markScheduleItemCompleted(game.titleEn, isGame: true);
        }
      });
      _celebrationTimer?.cancel();
      _celebrationTimer = Timer(const Duration(minutes: 2), () {
        if (mounted) {
          setState(() => isCelebrating = false);
        }
      });
    }
  }

  int _completedDailyActivities = 1;
  int get _assignedDailyActivities =>
      (_assignedQuests.length + _assignedGames.length).clamp(1, 10);

  double get _petEnergyProgress =>
      (_completedDailyActivities / _assignedDailyActivities).clamp(0.0, 1.0);

  String get _petMoodTitle {
    if (_completedDailyActivities == 0) {
      return isUrdu ? 'حالت: اداس / سویا ہوا 😴' : 'Mood: Sleepy / Restless 😴';
    } else if (_completedDailyActivities < _assignedDailyActivities) {
      return isUrdu ? 'حالت: پرجوش اور خوش 😊' : 'Mood: Cheerful & Active 😊';
    } else {
      return isUrdu ? 'حالت: انتہائی خوش اور مسرور 🥳' : 'Mood: Super Happy & Dancing 🥳';
    }
  }

  Color get _petMoodColor {
    if (_completedDailyActivities == 0) {
      return const Color(0xFF64748B);
    } else if (_completedDailyActivities < _assignedDailyActivities) {
      return const Color(0xFFF59E0B);
    } else {
      return const Color(0xFF10B981);
    }
  }

  void _showChildProfileModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalCtx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pull bar
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),

              // Glowing Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppTheme.orangePinkGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryPink.withOpacity(0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _childName.isNotEmpty ? _childName[0].toUpperCase() : 'C',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Text(
                _childName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Text(
                  '🌟 Champion Explorer',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF15803D),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // KPI stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildProfileStatCard(
                    icon: '🔥',
                    title: isUrdu ? 'اسٹریک' : 'Streak',
                    value: '$_currentStreak Days',
                  ),
                  _buildProfileStatCard(
                    icon: '⚡',
                    title: isUrdu ? 'آج کی انرجی' : 'Today\'s Energy',
                    value: '$_completedDailyActivities / $_assignedDailyActivities',
                  ),
                  _buildProfileStatCard(
                    icon: '🏆',
                    title: isUrdu ? 'بیجز' : 'Badges',
                    value: '4 Unlocked',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Parent Portal Exit Option
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                icon: const Icon(Icons.lock_outline_rounded, size: 18),
                label: Text(
                  isUrdu ? 'والدین کے کنٹرولز / لاگ آؤٹ' : 'Parent Controls / Switch User',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                onPressed: () {
                  Navigator.of(modalCtx).pop();
                  _showParentGateModal();
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileStatCard({
    required String icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: 95,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.scaffoldBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _handleChildSettingsClick() async {
    // Requirement 7: Whenever child clicks on settings to change it and is shown the parent login screen,
    // a notification to the parent app must be given letting them know that their child is trying to change the settings.
    await ParentNotificationService.instance.sendNotification(
      title: 'Security Alert: Settings Access Attempt',
      message: '$_childName is attempting to access and modify settings on the child device.',
      type: 'settings_access_attempt',
    );

    if (mounted) {
      _showParentSettingsLoginDialog();
    }
  }

  void _showParentSettingsLoginDialog() {
    final emailController = TextEditingController(text: AuthService.instance.currentUserEmail);
    final passwordController = TextEditingController();
    bool obscure = true;
    String? errorMsg;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (gateCtx) {
        return StatefulBuilder(
          builder: (context, setGateState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A11CB).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_rounded, color: Color(0xFF6A11CB), size: 24),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isUrdu ? 'والدین کی توثیق' : 'Parent Authorization',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCD34D)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_active_rounded, color: Color(0xFFD97706), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isUrdu
                                  ? 'والدین کو الرٹ بھیج دیا گیا ہے۔ سیٹنگز تبدیل کرنے کے لیے پیرنٹ لاگ ان درج کریں۔'
                                  : 'Parent app notified. Enter parent credentials to authorize setting changes.',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.amber.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      key: const Key('parent_gate_email'),
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: isUrdu ? 'والدین کا ای میل' : 'Parent Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('parent_gate_password'),
                      controller: passwordController,
                      obscureText: obscure,
                      decoration: InputDecoration(
                        labelText: isUrdu ? 'پاس ورڈ' : 'Parent Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setGateState(() => obscure = !obscure),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    if (errorMsg != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        errorMsg!,
                        style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(gateCtx).pop(),
                  child: Text(isUrdu ? 'منسوخ' : 'Cancel'),
                ),
                ElevatedButton(
                  key: const Key('parent_gate_unlock_btn'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A11CB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    final email = emailController.text.trim();
                    final pass = passwordController.text.trim();
                    if (email.isEmpty || pass.isEmpty) {
                      setGateState(() => errorMsg = isUrdu ? 'براہ کرم ای میل اور پاس ورڈ درج کریں۔' : 'Please enter email and password.');
                      return;
                    }
                    if (email.contains('@') && pass.isNotEmpty) {
                      Navigator.of(gateCtx).pop();
                      if (mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ChildSettingsScreen()),
                        );
                      }
                    } else {
                      setGateState(() => errorMsg = isUrdu ? 'غلط معلومات' : 'Invalid parent credentials.');
                    }
                  },
                  child: Text(isUrdu ? 'ان لاک کریں' : 'Unlock Settings', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showParentGateModal() {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (gateCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.shield_rounded, color: Color(0xFF6A11CB)),
              SizedBox(width: 8),
              Text('Parent Authorization', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter parent password to switch to Parent Portal:'),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Parent Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(gateCtx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A11CB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (passwordController.text.trim().isNotEmpty) {
                  Navigator.of(gateCtx).pop();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('selected_device_space', 'parent');
                  await AuthService.instance.setDefaultDeviceMode('parent');
                  if (mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    );
                  }
                }
              },
              child: const Text('Unlock', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.04),
        leading: IconButton(
          icon: const Icon(Icons.people_outline_rounded, color: AppTheme.textPrimary),
          tooltip: 'Switch Child Profile',
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => ChildProfileSelection(parentUid: AuthService.instance.currentUserUid),
              ),
            );
          },
        ),
        title: Text(
          isUrdu ? '$_childName کی جگہ' : '$_childName\'s Space',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        actions: [
          // Streak Counter Badge: ⭐ Streak: X
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFEDD5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⭐', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  'Streak: $_currentStreak',
                  key: const Key('streak_badge_text'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFEA580C),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),

          // Settings Button (Req 7)
          IconButton(
            key: const Key('child_settings_btn'),
            icon: const Icon(Icons.settings_rounded, color: AppTheme.textPrimary),
            tooltip: 'Settings',
            onPressed: _handleChildSettingsClick,
          ),

          // Child Profile Button (Req 19)
          IconButton(
            key: const Key('child_profile_btn'),
            icon: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.orangePinkGradient,
              ),
              child: CircleAvatar(
                radius: 13,
                backgroundColor: Colors.white,
                child: Text(
                  _childName.isNotEmpty ? _childName[0].toUpperCase() : 'C',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ),
            ),
            tooltip: 'View Profile',
            onPressed: _showChildProfileModal,
          ),

          // English/Urdu Toggle Button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            child: InkWell(
              key: const Key('lang_toggle_chip'),
              onTap: _toggleLanguage,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppTheme.orangePinkGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryPink.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    isUrdu ? 'ENG' : 'اردو',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Center Pet Companion Area
            _buildPetCompanionSection(),

            // Tab View Area via IndexedStack
            Expanded(
              child: IndexedStack(
                index: _currentTabIndex,
                children: [
                  _buildLearnTab(),
                  _buildScheduleTab(),
                  _buildBadgesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: (index) => setState(() => _currentTabIndex = index),
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: const Color(0xFF6A11CB),
          unselectedItemColor: AppTheme.textLight,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.school_rounded),
              label: isUrdu ? 'سیکھیں' : 'Learn',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.calendar_today_rounded),
              label: isUrdu ? 'شیڈول' : 'Schedule',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.military_tech_rounded),
              label: isUrdu ? 'بیجز' : 'Badges',
            ),
          ],
        ),
      ),
    );
  }

  /// Center Pet Companion Widget with Pet Mood State & Daily Activity Energy Bar (Req 20)
  Widget _buildPetCompanionSection() {
    final petLottieUrl = isCelebrating || _completedDailyActivities >= _assignedDailyActivities
        ? 'https://lottie.host/933ebf99-a681-42db-98db-c88f3a3ad024/9xVfW55oXN.json'
        : 'https://lottie.host/40375535-6fa4-46c3-9fae-6ed9f30b777a/sH3c3B1hP8.json';

    final isGoalMet = _completedDailyActivities >= _assignedDailyActivities;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isGoalMet || isCelebrating ? AppTheme.primaryPink : const Color(0xFF6A11CB))
                .withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isGoalMet || isCelebrating ? const Color(0xFFFFD166) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Lottie Pet Animation with graceful fallback
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: isGoalMet || isCelebrating ? const Color(0xFFFFFBEB) : const Color(0xFFF3E8FF),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Lottie.network(
                petLottieUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(
                      isGoalMet || isCelebrating ? Icons.star_rounded : Icons.pets_rounded,
                      size: 46,
                      color: isGoalMet || isCelebrating ? const Color(0xFFF59E0B) : const Color(0xFF6A11CB),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pet Mood State Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _petMoodColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _petMoodColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    _petMoodTitle,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _petMoodColor,
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Energy Progress Bar Label
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isUrdu ? 'تھراپسٹ کے تفویض کردہ اہداف' : 'Daily Therapist Goals',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '$_completedDailyActivities/$_assignedDailyActivities',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _petMoodColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Animated Gradient Energy Level Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 8,
                    child: LinearProgressIndicator(
                      value: _petEnergyProgress,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(_petMoodColor),
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // State description
                Text(
                  isGoalMet
                      ? (isUrdu ? '🎉 سب اہداف مکمل! پالتو دوست بے حد خوش ہے!' : '🎉 All goals done! Pet is bursting with joy!')
                      : (isUrdu
                          ? 'پالتو دوست کو خوش کرنے کے لیے مزید اسباق مکمل کریں!'
                          : 'Complete ${_assignedDailyActivities - _completedDailyActivities} more to make your pet super happy!'),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tab 0: Learn Tab (Showing ONLY therapist-assigned quests and games, without category filters)
  Widget _buildLearnTab() {
    final lessons = _assignedQuests.isNotEmpty
        ? _assignedQuests
        : _getLessonsForAutismLevel(_autismLevel);

    final games = _assignedGames.isNotEmpty
        ? _assignedGames
        : _getTherapistAssignedGames();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isUrdu ? 'تھراپسٹ کے تفویض کردہ اسباق' : 'Today\'s Assigned Quests',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Text(
                '${lessons.length} Goals',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF16A34A),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...lessons.asMap().entries.map((entry) {
          final index = entry.key;
          final lesson = entry.value;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              key: Key('lesson_card_${lesson.title.toLowerCase().replaceAll(' ', '_')}'),
              borderRadius: BorderRadius.circular(22),
              onTap: () => _openLesson(lesson),
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: lesson.gradient,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(lesson.icon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isUrdu ? lesson.titleUrdu : lesson.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isUrdu ? lesson.urduPrompt : lesson.englishPrompt,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  lesson.interactionType.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF6A11CB),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: lesson.gradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(delay: (80 * index).ms, duration: 350.ms)
              .slideX(begin: 0.08, end: 0);
        }),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isUrdu ? 'تھراپسٹ کی تفویض کردہ گیمز' : 'Today\'s Assigned Games',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${games.length} Active',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD97706),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Filter chips removed completely per Requirement 2
        ...games.map((game) {
          return Material(
            color: Colors.transparent,
            child: InkWell(
              key: Key('game_card_${game.id}'),
              borderRadius: BorderRadius.circular(22),
              onTap: () => _openAdlGame(game.id),
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: game.themeColor.withOpacity(0.2), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: game.themeColor.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [game.themeColor.withOpacity(0.7), game.themeColor],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(game.icon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isUrdu ? game.titleUr : game.titleEn,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isUrdu ? game.descriptionUr : game.descriptionEn,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: game.themeColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.sports_esports_rounded,
                        color: game.themeColor,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  /// Tab 1: Schedule Tab (Visual Timeline dynamically marked as quests/games finish)
  Widget _buildScheduleTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isUrdu ? 'روزمرہ روٹین ٹائم لائن' : 'Daily Visual Routine Timeline',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Auto-Tracked',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.green.shade800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          isUrdu
              ? 'اسباق اور گیمز مکمل ہونے پر روٹین خودکار طور پر مکمل نشان زد ہوتی ہے۔'
              : 'Tasks automatically check off when you complete assigned quests and games.',
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 14),
        ..._scheduleCompletion.entries.map((entry) {
          final title = entry.key;
          final isDone = entry.value;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDone ? const Color(0xFF10B981) : Colors.grey.withOpacity(0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Checkbox(
                  value: isDone,
                  activeColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  onChanged: (val) {
                    setState(() {
                      _scheduleCompletion[title] = val ?? false;
                      _persistSchedule();
                    });
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      color: isDone ? AppTheme.textLight : null,
                    ),
                  ),
                ),
                if (isDone)
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// Tab 2: Badges Tab (Streak Milestones: 1, 5, 10, 20 Days)
  Widget _buildBadgesTab() {
    final milestones = [
      {'days': 1, 'name': 'First Spark', 'urdu': 'پہلی کرن', 'icon': Icons.star_rounded},
      {'days': 5, 'name': 'Streak Hero', 'urdu': 'ہیرو اسٹریک', 'icon': Icons.bolt_rounded},
      {'days': 10, 'name': 'Routine Master', 'urdu': 'روٹین ماسٹر', 'icon': Icons.shield_rounded},
      {'days': 20, 'name': 'Super Legend', 'urdu': 'سپر لیجنڈ', 'icon': Icons.military_tech_rounded},
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: milestones.length,
      itemBuilder: (context, index) {
        final item = milestones[index];
        final daysReq = item['days'] as int;
        final isUnlocked = _currentStreak >= daysReq;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isUnlocked ? const Color(0xFFFFD166) : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: isUnlocked ? AppTheme.orangePinkGradient : null,
                  color: isUnlocked ? null : AppTheme.scaffoldBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item['icon'] as IconData,
                  size: 32,
                  color: isUnlocked ? Colors.white : AppTheme.textLight,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isUrdu ? (item['urdu'] as String) : (item['name'] as String),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isUnlocked ? AppTheme.textPrimary : AppTheme.textLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isUnlocked ? const Color(0xFFFEF3C7) : AppTheme.scaffoldBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isUnlocked ? 'Unlocked!' : 'Goal: $daysReq Days',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isUnlocked ? const Color(0xFFB45309) : AppTheme.textLight,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
