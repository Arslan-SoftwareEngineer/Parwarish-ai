import 'package:flutter/material.dart';
import 'services/tts_service.dart';
import 'services/therapist_service.dart';
import 'services/localization_service.dart';
import 'models/goal_record_model.dart';
import 'widgets/games/emotion_mirror_game.dart';
import 'widgets/games/drag_sequence_game.dart';
import 'widgets/games/voice_phonics_game.dart';
import 'widgets/games/sensory_breathe_game.dart';
import 'widgets/games/matching_sorting_game.dart';
import 'widgets/games/fine_motor_trace_game.dart';
import 'widgets/mood_checkin_dialog.dart';
import 'widgets/celebration_overlay.dart';
import 'theme/app_theme.dart';

class LessonScreen extends StatefulWidget {
  final String childId;
  final String moduleName;
  final String? videoUrl; // optional legacy param
  final Map<String, String> localizedPrompts;
  final String interactionType; // 'emotion_mirror', 'drag_sequence', 'voice_phonics', 'sensory_breathe', 'matching_sorting', 'fine_motor_trace', or 'voice'/'camera'/'breathe'
  final String? domainId;
  final String? goalId;

  const LessonScreen({
    super.key,
    required this.childId,
    required this.moduleName,
    this.videoUrl,
    required this.localizedPrompts,
    required this.interactionType,
    this.domainId,
    this.goalId,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  final Stopwatch _stopwatch = Stopwatch();
  bool _isSuccessCelebration = false;
  int _timeTakenSeconds = 0;
  String _selectedMood = 'Happy';

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
    _playInitialPrompt();
  }

  Future<void> _playInitialPrompt() async {
    final isUrdu = LocalizationService.instance.isUrdu;
    final prompt = widget.localizedPrompts[isUrdu ? 'ur' : 'en'] ??
        widget.localizedPrompts['en'] ??
        'Let\'s complete this fun mission together!';
    await TtsService.instance.speak(prompt, langCode: isUrdu ? 'ur' : 'en');
  }

  void _onGameEngineCompleted() {
    _stopwatch.stop();
    _timeTakenSeconds = _stopwatch.elapsed.inSeconds > 0 ? _stopwatch.elapsed.inSeconds : 45;

    // Show Child Mood Check-In Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return MoodCheckinDialog(
          onMoodSelected: (mood) async {
            Navigator.of(dialogContext).pop();
            setState(() {
              _selectedMood = mood;
              _isSuccessCelebration = true;
            });

            // Log goal record telemetry to Therapist Service & Firestore
            await TherapistService.instance.logGoalRecord(
              GoalRecordModel(
                id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
                childId: widget.childId,
                domainId: widget.domainId ?? 'dom_01',
                goalId: widget.goalId ?? 'goal_custom',
                moduleName: widget.moduleName,
                gameType: _normalizedGameType,
                timeTakenSeconds: _timeTakenSeconds,
                accuracyScore: 1.0,
                moodState: _selectedMood,
                completedAt: DateTime.now(),
              ),
            );
          },
        );
      },
    );
  }

  String get _normalizedGameType {
    final type = widget.interactionType.toLowerCase();
    if (type.contains('camera') || type.contains('mirror') || type.contains('emotion')) return 'emotion_mirror';
    if (type.contains('breathe') || type.contains('calm')) return 'sensory_breathe';
    if (type.contains('sort') || type.contains('match')) return 'matching_sorting';
    if (type.contains('trace') || type.contains('knot') || type.contains('tie')) return 'fine_motor_trace';
    if (type.contains('voice') || type.contains('speech')) return 'voice_phonics';
    return 'drag_sequence';
  }

  Widget _buildInteractiveGameEngine() {
    final promptEn = widget.localizedPrompts['en'] ?? widget.moduleName;
    final promptUr = widget.localizedPrompts['ur'] ?? widget.moduleName;

    switch (_normalizedGameType) {
      case 'emotion_mirror':
        return EmotionMirrorGame(
          promptEn: promptEn,
          promptUr: promptUr,
          onGameCompleted: _onGameEngineCompleted,
        );
      case 'voice_phonics':
        return VoicePhonicsGame(
          promptEn: promptEn,
          promptUr: promptUr,
          onGameCompleted: _onGameEngineCompleted,
        );
      case 'sensory_breathe':
        return SensoryBreatheGame(
          promptEn: promptEn,
          promptUr: promptUr,
          onGameCompleted: _onGameEngineCompleted,
        );
      case 'matching_sorting':
        return MatchingSortingGame(
          promptEn: promptEn,
          promptUr: promptUr,
          onGameCompleted: _onGameEngineCompleted,
        );
      case 'fine_motor_trace':
        return FineMotorTraceGame(
          promptEn: promptEn,
          promptUr: promptUr,
          onGameCompleted: _onGameEngineCompleted,
        );
      case 'drag_sequence':
      default:
        return DragSequenceGame(
          promptEn: promptEn,
          promptUr: promptUr,
          onGameCompleted: _onGameEngineCompleted,
        );
    }
  }

  @override
  void dispose() {
    _stopwatch.stop();
    TtsService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = LocalizationService.instance.isUrdu;

    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.instance.currentLocale,
      builder: (context, lang, _) {
        return Scaffold(
          backgroundColor: AppTheme.scaffoldBackground,
          appBar: AppBar(
            title: Text(widget.moduleName),
            actions: [
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
                onPressed: () {
                  LocalizationService.instance.toggleLanguage();
                  _playInitialPrompt();
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Interactive Game Hub
                    _buildInteractiveGameEngine(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // Celebration Overlay
              if (_isSuccessCelebration)
                Positioned.fill(
                  child: CelebrationOverlay(
                    moduleTitle: widget.moduleName,
                    starsEarned: 50,
                    onContinue: () {
                      Navigator.of(context).pop(true);
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
