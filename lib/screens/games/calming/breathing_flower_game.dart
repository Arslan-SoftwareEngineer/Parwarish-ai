import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/tts_service.dart';
import '../../../services/localization_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/celebration_overlay.dart';

enum BreathPhase { inhale, hold, exhale }

class BreathingFlowerGame extends StatefulWidget {
  final String? childId;
  final bool? isUrdu;

  const BreathingFlowerGame({
    super.key,
    this.childId,
    this.isUrdu,
  });

  @override
  State<BreathingFlowerGame> createState() => _BreathingFlowerGameState();
}

class _BreathingFlowerGameState extends State<BreathingFlowerGame> with SingleTickerProviderStateMixin {
  late String _activeChildId;
  late bool _isUrdu;
  DateTime _startTime = DateTime.now();

  late AnimationController _breathController;
  BreathPhase _currentPhase = BreathPhase.inhale;
  int _completedBreaths = 0;
  bool _isTouching = false;
  bool _isCompleted = false;

  Timer? _phaseTimer;

  @override
  void initState() {
    super.initState();
    _activeChildId = widget.childId ?? 'child_demo_01';
    _isUrdu = widget.isUrdu ?? LocalizationService.instance.isUrdu;
    _startTime = DateTime.now();

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _startBreathingCycle();
    _loadChildDetails();
  }

  Future<void> _loadChildDetails() async {
    if (widget.childId == null) {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString('active_child_id') ?? prefs.getString('child_id');
      if (id != null && mounted) {
        setState(() => _activeChildId = id);
      }
    }
  }

  void _startBreathingCycle() {
    _runInhale();
  }

  void _runInhale() {
    if (!mounted || _isCompleted) return;

    setState(() {
      _currentPhase = BreathPhase.inhale;
    });

    _breathController.duration = const Duration(seconds: 4);
    _breathController.forward(from: 0.0);

    final speech = _isUrdu ? 'لمبی اور گہری سانس لیں...' : 'Breathe in slowly...';
    TtsService.instance.speak(speech, langCode: _isUrdu ? 'ur' : 'en');

    _phaseTimer?.cancel();
    _phaseTimer = Timer(const Duration(seconds: 4), _runHold);
  }

  void _runHold() {
    if (!mounted || _isCompleted) return;

    setState(() {
      _currentPhase = BreathPhase.hold;
    });

    HapticFeedback.lightImpact();

    final speech = _isUrdu ? 'تھوڑی دیر روکیں...' : 'Hold gently...';
    TtsService.instance.speak(speech, langCode: _isUrdu ? 'ur' : 'en');

    _phaseTimer?.cancel();
    _phaseTimer = Timer(const Duration(seconds: 2), _runExhale);
  }

  void _runExhale() {
    if (!mounted || _isCompleted) return;

    setState(() {
      _currentPhase = BreathPhase.exhale;
    });

    _breathController.duration = const Duration(seconds: 4);
    _breathController.reverse(from: 1.0);

    final speech = _isUrdu ? 'آہستہ سے سانس باہر چھوڑیں...' : 'Breathe out gently...';
    TtsService.instance.speak(speech, langCode: _isUrdu ? 'ur' : 'en');

    _phaseTimer?.cancel();
    _phaseTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted || _isCompleted) return;
      setState(() {
        _completedBreaths++;
      });
      _runInhale();
    });
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _breathController.dispose();
    super.dispose();
  }

  Future<void> _completeSession() async {
    _phaseTimer?.cancel();
    _breathController.stop();
    HapticFeedback.heavyImpact();

    setState(() {
      _isCompleted = true;
    });

    final duration = DateTime.now().difference(_startTime).inSeconds;

    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('children')
            .doc(_activeChildId)
            .collection('activity_logs')
            .add({
          'module_name': 'Breathing Flower',
          'interaction_type': 'calming_game',
          'completed_at': FieldValue.serverTimestamp(),
          'duration_seconds': math.max(1, duration),
        });
      }
    } catch (e) {
      debugPrint('BreathingFlowerGame activity log error: $e');
    }

    final cheer = _isUrdu
        ? 'بہت خوب! آپ نے بہت پرسکون اور گہری سانسیں لیں!'
        : 'Beautifully done! You are calm, relaxed, and centered!';
    await TtsService.instance.speak(cheer, langCode: _isUrdu ? 'ur' : 'en');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF2F8),
      body: Stack(
        children: [
          // Background Gradient Ambience
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFCE7F3),
                    Color(0xFFFDF2F8),
                    Color(0xFFF0FDF4),
                  ],
                ),
              ),
            ),
          ),

          // Interactive Touch Screen for Ripple Waves
          GestureDetector(
            key: const Key('breathing_touch_surface'),
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => setState(() => _isTouching = true),
            onTapUp: (_) => setState(() => _isTouching = false),
            onTapCancel: () => setState(() => _isTouching = false),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 8),
                  _buildBreathsCounter(),
                  const Spacer(),

                  // Center Vector Lotus Flower with Petals
                  Center(
                    child: _buildLotusFlowerScene(),
                  ),

                  const Spacer(),

                  // Phase Indicator & Guidance Pill
                  _buildPhaseGuidancePill(),
                  const SizedBox(height: 16),

                  // Exit Button
                  _buildDoneButton(),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),

          // Celebration Overlay
          if (_isCompleted)
            CelebrationOverlay(
              moduleTitle: _isUrdu ? 'پھول سانس کی مشق' : 'Breathing Flower Meditation',
              starsEarned: 50,
              onContinue: () => Navigator.of(context).pop(true),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            key: const Key('breathing_flower_back_btn'),
            icon: const Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFDB2777).withOpacity(0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.spa_rounded, color: Color(0xFFDB2777), size: 22),
                const SizedBox(width: 8),
                Text(
                  _isUrdu ? 'پھول سے سانس لینا' : 'Breathing Flower',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.volume_up_rounded, color: Color(0xFFDB2777)),
            onPressed: () {
              final text = _isUrdu
                  ? 'پھول کے ساتھ لمبی سانس لیں اور پرسکون محسوس کریں'
                  : 'Breathe in and out slowly with the blooming flower';
              TtsService.instance.speak(text, langCode: _isUrdu ? 'ur' : 'en');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBreathsCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFBCFE8), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite_rounded, color: Color(0xFFDB2777), size: 18),
          const SizedBox(width: 8),
          Text(
            _isUrdu ? 'پرسکون سانسیں: $_completedBreaths' : 'Calm Breaths: $_completedBreaths',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLotusFlowerScene() {
    return AnimatedBuilder(
      animation: _breathController,
      builder: (context, child) {
        final animVal = _breathController.value;
        final scale = 0.65 + (animVal * 0.55); // Scales from 0.65 to 1.20

        return Stack(
          alignment: Alignment.center,
          children: [
            // Soft Radial Glow Aura behind flower
            Container(
              width: 250 * scale,
              height: 250 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFF472B6).withOpacity(_currentPhase == BreathPhase.hold ? 0.38 : 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // Pulsating Ripple Waves if child is touching
            if (_isTouching)
              CustomPaint(
                size: Size(260 * scale, 260 * scale),
                painter: _RipplePainter(animationValue: animVal),
              ),

            // Lotus Petals (8 radial petals around center)
            SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: List.generate(8, (i) {
                  final angle = (i * math.pi / 4);
                  return Transform.rotate(
                    angle: angle,
                    child: Transform.translate(
                      offset: Offset(0, -32.0 * animVal),
                      child: Container(
                        width: 44 + (animVal * 12),
                        height: 70 + (animVal * 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFFF472B6),
                              const Color(0xFFEC4899),
                              const Color(0xFFDB2777).withOpacity(0.85),
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(30),
                            bottom: Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFDB2777).withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Center Golden Lotus Core
            Container(
              width: 58 + (animVal * 10),
              height: 58 + (animVal * 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFDE047), Color(0xFFF59E0B)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Icon(
                  Icons.spa_rounded,
                  color: Colors.white,
                  size: 28 + (animVal * 4),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPhaseGuidancePill() {
    String phaseText;
    Color phaseColor;
    IconData phaseIcon;

    switch (_currentPhase) {
      case BreathPhase.inhale:
        phaseText = _isUrdu ? 'لمبی سانس لیں (Breathe In)' : 'Breathe In Slowly';
        phaseColor = const Color(0xFF0D9488);
        phaseIcon = Icons.arrow_upward_rounded;
        break;
      case BreathPhase.hold:
        phaseText = _isUrdu ? 'سانس روکیں (Hold)' : 'Hold Gently';
        phaseColor = const Color(0xFFD97706);
        phaseIcon = Icons.pause_rounded;
        break;
      case BreathPhase.exhale:
        phaseText = _isUrdu ? 'آہستہ چھوڑیں (Breathe Out)' : 'Breathe Out Gently';
        phaseColor = const Color(0xFF7C3AED);
        phaseIcon = Icons.arrow_downward_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: phaseColor.withOpacity(0.4), width: 2),
        boxShadow: [
          BoxShadow(
            color: phaseColor.withOpacity(0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(phaseIcon, color: phaseColor, size: 24),
          const SizedBox(width: 10),
          Text(
            phaseText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: phaseColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoneButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          key: const Key('breathing_done_btn'),
          onPressed: _completeSession,
          icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
          label: Text(
            _isUrdu ? 'میں پرسکون ہوں (مکمل)' : 'I Feel Peaceful (Complete)',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDB2777),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            elevation: 4,
          ),
        ),
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  final double animationValue;

  _RipplePainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF472B6).withOpacity((1.0 - animationValue).clamp(0.0, 0.4))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) * (0.5 + 0.5 * animationValue);

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
