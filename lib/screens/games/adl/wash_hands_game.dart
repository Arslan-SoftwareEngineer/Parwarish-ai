import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/tts_service.dart';
import '../../../services/localization_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/celebration_overlay.dart';

class WashHandsGame extends StatefulWidget {
  final String? childId;
  final bool? isUrdu;

  const WashHandsGame({
    super.key,
    this.childId,
    this.isUrdu,
  });

  @override
  State<WashHandsGame> createState() => _WashHandsGameState();
}

class _WashHandsGameState extends State<WashHandsGame> with TickerProviderStateMixin {
  late String _activeChildId;
  late bool _isUrdu;
  DateTime _startTime = DateTime.now();

  // Stage 0: Soap (tap dispenser 2x)
  // Stage 1: Rub & Scrub (pan over hands to scrub away dirt)
  // Stage 2: Rinse (turn on water, drag hands under stream)
  // Stage 3: Dry (drag towel horizontally across hands)
  // Stage 4: Completed
  int _currentStage = 0;

  // Soap Stage State
  int _soapPumps = 0;
  bool _isPumpPressed = false;
  final List<Offset> _soapBubbles = [];

  // Scrub Stage State
  double _scrubProgress = 0.0; // 0.0 to 1.0
  final double _targetScrubDistance = 600.0;
  double _accumulatedScrubDistance = 0.0;

  // Rinse Stage State
  bool _isWaterRunning = false;
  double _rinseProgress = 0.0; // 0.0 to 1.0
  double _handsOffsetUnderWater = 0.0;

  // Dry Stage State - Freely movable in 2D across hands (Req 6)
  double _towelX = 60.0;
  double _towelY = 140.0;
  double _towelTilt = 0.0;
  double _dryProgress = 0.0; // 0.0 to 1.0

  bool _isCompleted = false;

  late AnimationController _waterFlowController;
  late AnimationController _towelFloatController;
  late AnimationController _soapDispenseController;

  @override
  void initState() {
    super.initState();
    _activeChildId = widget.childId ?? 'child_demo_01';
    _isUrdu = widget.isUrdu ?? LocalizationService.instance.isUrdu;
    _startTime = DateTime.now();

    _waterFlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _towelFloatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _soapDispenseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _loadChildDetails();
    _speakCurrentInstruction();
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

  @override
  void dispose() {
    _waterFlowController.dispose();
    _towelFloatController.dispose();
    _soapDispenseController.dispose();
    super.dispose();
  }

  Future<void> _speakCurrentInstruction() async {
    String text;
    if (_currentStage == 0) {
      text = _isUrdu
          ? 'صابن لگانے کے لیے ڈسپنسر کو دو بار دبائیں'
          : 'Tap the soap dispenser 2 times to get rich foam!';
    } else if (_currentStage == 1) {
      text = _isUrdu
          ? 'ہاتھوں کو اچھی طرح رگڑیں تاکہ جھاگ بن جائے'
          : 'Rub and scrub your hands to wash away the germs!';
    } else if (_currentStage == 2) {
      text = _isUrdu
          ? 'نل کا ہینڈل کھولیں اور پانی سے ہاتھ دھوئیں'
          : 'Turn on the tap and rinse off the soap bubbles!';
    } else {
      text = _isUrdu
          ? 'تولیہ سے ہاتھ اچھی طرح خشک کریں'
          : 'Drag the soft towel across your hands to dry them!';
    }
    await TtsService.instance.speak(text, langCode: _isUrdu ? 'ur' : 'en');
  }

  void _handleDispenserTap() {
    if (_currentStage != 0 || _soapPumps >= 2) return;

    HapticFeedback.lightImpact();
    _soapDispenseController.forward(from: 0.0);

    setState(() {
      _isPumpPressed = true;
      _soapPumps++;

      // Generate soft foam bubbles onto hands
      final random = math.Random();
      for (int i = 0; i < 6; i++) {
        _soapBubbles.add(Offset(
          -40 + random.nextDouble() * 80,
          -30 + random.nextDouble() * 60,
        ));
      }
    });

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() => _isPumpPressed = false);
      }
    });

    if (_soapPumps >= 2) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _currentStage = 1;
          });
          _speakCurrentInstruction();
        }
      });
    }
  }

  void _handleScrubPan(DragUpdateDetails details) {
    if (_currentStage != 1) return;

    final delta = details.delta.distance;
    _accumulatedScrubDistance += delta;

    if (math.Random().nextInt(8) == 0) {
      HapticFeedback.selectionClick();
    }

    setState(() {
      _scrubProgress = (_accumulatedScrubDistance / _targetScrubDistance).clamp(0.0, 1.0);
    });

    if (_scrubProgress >= 1.0) {
      HapticFeedback.mediumImpact();
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          setState(() {
            _currentStage = 2;
          });
          _speakCurrentInstruction();
        }
      });
    }
  }

  void _toggleWater() {
    if (_currentStage != 2) return;
    HapticFeedback.lightImpact();
    setState(() {
      _isWaterRunning = !_isWaterRunning;
      if (_isWaterRunning) {
        _waterFlowController.repeat();
      } else {
        _waterFlowController.stop();
      }
    });
  }

  void _handleRinsePan(DragUpdateDetails details) {
    if (_currentStage != 2 || !_isWaterRunning) return;

    final dy = details.delta.dy.abs();
    final dx = details.delta.dx.abs();
    _handsOffsetUnderWater = (_handsOffsetUnderWater + (dx + dy) * 0.005).clamp(0.0, 1.0);

    setState(() {
      _rinseProgress = (_rinseProgress + (dx + dy) * 0.003).clamp(0.0, 1.0);
    });

    if (_rinseProgress >= 1.0) {
      HapticFeedback.mediumImpact();
      _waterFlowController.stop();
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          setState(() {
            _currentStage = 3;
            _isWaterRunning = false;
          });
          _towelFloatController.repeat(reverse: true);
          _speakCurrentInstruction();
        }
      });
    }
  }

  void _handleTowelPan(DragUpdateDetails details) {
    if (_currentStage != 3) return;

    setState(() {
      _towelX = (_towelX + details.delta.dx).clamp(20.0, 260.0);
      _towelY = (_towelY + details.delta.dy).clamp(80.0, 310.0);
      _towelTilt = (details.delta.dx * 0.04).clamp(-0.25, 0.25);
      final dist = math.sqrt(details.delta.dx * details.delta.dx + details.delta.dy * details.delta.dy);
      _dryProgress = (_dryProgress + (dist > 0 ? dist : details.delta.dx.abs()) * 0.015).clamp(0.0, 1.0);
    });

    if (_dryProgress >= 1.0 && !_isCompleted) {
      _completeGame();
    }
  }

  Future<void> _completeGame() async {
    _towelFloatController.stop();
    _waterFlowController.stop();
    setState(() {
      _isCompleted = true;
    });

    HapticFeedback.heavyImpact();
    final duration = DateTime.now().difference(_startTime).inSeconds;

    // Log activity to Firestore
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('children')
            .doc(_activeChildId)
            .collection('activity_logs')
            .add({
          'module_name': 'Wash Hands Routine',
          'interaction_type': 'touch_game',
          'completed_at': FieldValue.serverTimestamp(),
          'duration_seconds': math.max(1, duration),
        });
      }
    } catch (e) {
      debugPrint('WashHandsGame activity log error: $e');
    }

    // TTS Celebration praise
    final praise = _isUrdu ? 'ہاتھ بالکل صاف ہو گئے!' : 'Hands are fresh and clean!';
    await TtsService.instance.speak(praise, langCode: _isUrdu ? 'ur' : 'en');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF),
      body: Stack(
        children: [
          // Background Gradient & Subtle Ambient Bubbles
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFDBEAFE),
                    Color(0xFFEFF6FF),
                    Color(0xFFE0F2FE),
                  ],
                ),
              ),
            ),
          ),

          // Main Interactive 2.5D Bathroom Basin
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 8),
                _buildInstructionCard(),
                Expanded(
                  child: Center(
                    child: _buildBathroomSinkScene(),
                  ),
                ),
                _buildStageProgressBar(),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Celebration Overlay upon completion
          if (_isCompleted)
            CelebrationOverlay(
              moduleTitle: _isUrdu ? 'ہاتھ دھونے کا مشن' : 'Wash Hands Routine',
              starsEarned: 50,
              onContinue: () {
                Navigator.of(context).pop(true);
              },
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
            key: const Key('wash_hands_back_btn'),
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
                  color: const Color(0xFF3B82F6).withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.clean_hands_rounded, color: Color(0xFF3B82F6), size: 22),
                const SizedBox(width: 8),
                Text(
                  _isUrdu ? 'ہاتھ دھونا' : 'Wash Hands',
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
            icon: Icon(
              Icons.volume_up_rounded,
              color: const Color(0xFF3B82F6),
            ),
            onPressed: _speakCurrentInstruction,
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionCard() {
    String text;
    IconData icon;
    if (_currentStage == 0) {
      text = _isUrdu ? 'صابن کے لیے ڈسپنسر پر ۲ بار ٹیپ کریں' : 'Tap soap dispenser 2 times';
      icon = Icons.soap_rounded;
    } else if (_currentStage == 1) {
      text = _isUrdu ? 'ہاتھوں کو اچھی طرح رگڑیں (Scrub)' : 'Rub hands together to make foam';
      icon = Icons.waves_rounded;
    } else if (_currentStage == 2) {
      text = _isUrdu ? 'نل کھولیں اور پانی سے دھوئیں' : 'Turn tap on and rinse bubbles';
      icon = Icons.water_drop_rounded;
    } else {
      text = _isUrdu ? 'تولیہ ہلا کر ہاتھ خشک کریں' : 'Wipe with soft towel to dry';
      icon = Icons.dry_cleaning_rounded;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF2563EB), size: 26),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E3A8A),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    ).animate(key: ValueKey(_currentStage)).fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildBathroomSinkScene() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sceneWidth = math.min(constraints.maxWidth * 0.92, 380.0);
        final sceneHeight = 440.0;

        return Container(
          width: sceneWidth,
          height: sceneHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFFFFF),
                Color(0xFFF8FAFC),
                Color(0xFFF1F5F9),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF64748B).withOpacity(0.2),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: const Color(0xFF94A3B8).withOpacity(0.12),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 2.5D Ceramic Basin Interior with Inset Depth
              Positioned(
                top: 70,
                left: 24,
                right: 24,
                bottom: 30,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFCBD5E1),
                        Color(0xFFE2E8F0),
                        Color(0xFFF1F5F9),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                        blurStyle: BlurStyle.inner,
                      ),
                    ],
                  ),
                  child: Center(
                    // Drain ring
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF94A3B8),
                        border: Border.all(color: const Color(0xFF64748B), width: 3),
                      ),
                    ),
                  ),
                ),
              ),

              // Chrome Faucet with tap handle (Center Top)
              Positioned(
                top: 18,
                left: sceneWidth / 2 - 28,
                child: _buildChromeFaucet(),
              ),

              // Animated Water Stream if tap is running
              if (_isWaterRunning)
                Positioned(
                  top: 72,
                  left: sceneWidth / 2 - 12,
                  child: _buildWaterStream(),
                ),

              // Soap Dispenser (Top Left)
              Positioned(
                top: 20,
                left: 36,
                child: _buildSoapDispenser(),
              ),

              // Towel Rack & Cloth (Top Right - active in Dry stage)
              if (_currentStage < 3)
                Positioned(
                  top: 16,
                  right: 30,
                  child: _buildTowelRack(),
                )
              else
                Positioned(
                  top: _towelY,
                  left: _towelX,
                  child: Transform.rotate(
                    angle: _towelTilt,
                    child: _buildInteractiveTowel(),
                  ),
                ),

              // Two Child Hands inside Basin
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: Center(
                  child: _buildHandsWidget(),
                ),
              ),

              // Animated Water Splashes and Ripples over Hands (Req 6)
              if (_isWaterRunning)
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _buildWaterSplashesOverHands(),
                  ),
                ),

              // Animated Soap Flying Splats from Dispenser to Hands (Req 6)
              _buildFlyingSoapAnimation(sceneWidth),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFlyingSoapAnimation(double sceneWidth) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _soapDispenseController,
        builder: (context, _) {
          if (!_soapDispenseController.isAnimating) return const SizedBox.shrink();
          final t = _soapDispenseController.value;
          return Stack(
            children: List.generate(4, (idx) {
            final startX = 60.0;
            final startY = 80.0;
            final targetX = (sceneWidth / 2 - 40) + idx * 25.0;
            final targetY = 270.0 + (idx % 2) * 20.0;
            final curX = startX + (targetX - startX) * t;
            final curY = startY + (targetY - startY) * t - 30 * math.sin(t * math.pi);
            final scale = 0.5 + 0.8 * t;

            return Positioned(
              left: curX,
              top: curY,
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.95),
                    border: Border.all(color: const Color(0xFF93C5FD), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF38BDF8).withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    ));
  }

  Widget _buildWaterSplashesOverHands() {
    return AnimatedBuilder(
      animation: _waterFlowController,
      builder: (context, _) {
        final val = _waterFlowController.value;
        return IgnorePointer(
          child: SizedBox(
            width: 200,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Expanding water ripple rings
                ...List.generate(3, (i) {
                  final phase = (val + i * 0.33) % 1.0;
                  final rWidth = 70.0 + phase * 90.0;
                  final rHeight = 35.0 + phase * 45.0;
                  return Opacity(
                    opacity: (1.0 - phase).clamp(0.0, 0.7),
                    child: Container(
                      width: rWidth,
                      height: rHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: const Color(0xFF60A5FA), width: 2),
                      ),
                    ),
                  );
                }),
                // Splashing water droplets around hands
                ...List.generate(6, (i) {
                  final angle = i * (math.pi / 3);
                  final dist = 35.0 + 20.0 * math.sin((val + i * 0.15) * 2 * math.pi);
                  return Transform.translate(
                    offset: Offset(math.cos(angle) * dist, math.sin(angle) * (dist * 0.5)),
                    child: Container(
                      width: 8,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChromeFaucet() {
    return GestureDetector(
      key: const Key('faucet_handle'),
      onTap: _toggleWater,
      child: Column(
        children: [
          // Tap Handle Valve
          Container(
            width: 56,
            height: 14,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE2E8F0), Color(0xFF94A3B8), Color(0xFFCBD5E1)],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ),
          ),
          // Neck Spout
          Container(
            width: 22,
            height: 42,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFCBD5E1), Color(0xFF94A3B8)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterStream() {
    return AnimatedBuilder(
      animation: _waterFlowController,
      builder: (context, child) {
        return Container(
          width: 24,
          height: 190,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF60A5FA).withOpacity(0.7),
                const Color(0xFF38BDF8).withOpacity(0.85),
                const Color(0xFF93C5FD).withOpacity(0.6),
              ],
              stops: [
                0.0,
                0.5 + 0.2 * math.sin(_waterFlowController.value * 2 * math.pi),
                1.0,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }

  Widget _buildSoapDispenser() {
    return GestureDetector(
      key: const Key('soap_dispenser'),
      onTap: _handleDispenserTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pump Nozzle
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            transform: Matrix4.translationValues(0, _isPumpPressed ? 8 : 0, 0),
            child: Container(
              width: 32,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFF475569),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          // Dispenser Body Bottle
          Container(
            width: 46,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF472B6), Color(0xFFEC4899), Color(0xFFDB2777)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFDB2777).withOpacity(0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$_soapPumps/2',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTowelRack() {
    return Container(
      width: 44,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFFEF08A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFDE047), width: 2),
      ),
      child: const Icon(Icons.dry_cleaning_rounded, color: Color(0xFFCA8A04), size: 28),
    );
  }

  Widget _buildInteractiveTowel() {
    return GestureDetector(
      key: const Key('towel_drag_target'),
      onPanUpdate: _handleTowelPan,
      child: Container(
        width: 80,
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFFFEF08A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFACC15), width: 3),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFCA8A04).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.dry_cleaning_rounded, color: Color(0xFF854D0E), size: 36),
            const SizedBox(height: 4),
            Text(
              _isUrdu ? 'تولیہ' : 'Towel',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF854D0E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandsWidget() {
    return GestureDetector(
      key: const Key('hands_interactive_area'),
      onPanUpdate: (details) {
        if (_currentStage == 1) {
          _handleScrubPan(details);
        } else if (_currentStage == 2) {
          _handleRinsePan(details);
        }
      },
      child: Container(
        width: 220,
        height: 140,
        color: Colors.transparent, // Hit test target
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Left Hand
            Positioned(
              left: 20,
              child: _buildHandShape(isLeft: true),
            ),
            // Right Hand
            Positioned(
              right: 20,
              child: _buildHandShape(isLeft: false),
            ),

            // Germs / Dirt Patches (Fade out during Stage 1)
            if (_currentStage <= 1)
              Opacity(
                opacity: (1.0 - _scrubProgress).clamp(0.0, 1.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildDirtSpot(size: 14),
                    const SizedBox(width: 40),
                    _buildDirtSpot(size: 18),
                    const SizedBox(width: 30),
                    _buildDirtSpot(size: 12),
                  ],
                ),
              ),

            // Soap Foam Bubbles (Appear in Stage 0 & 1, wash off in Stage 2)
            if (_soapPumps > 0 && _rinseProgress < 1.0)
              Opacity(
                opacity: (1.0 - _rinseProgress).clamp(0.0, 1.0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: List.generate(math.min(18, _soapPumps * 8), (index) {
                    final size = 16.0 + (index % 4) * 4.0;
                    return Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.85),
                        border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF38BDF8).withOpacity(0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),

            // Water Droplets in Dry stage (Stage 3)
            if (_currentStage == 3)
              Opacity(
                opacity: (1.0 - _dryProgress).clamp(0.0, 1.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (index) {
                    return const Icon(
                      Icons.water_drop_rounded,
                      color: Color(0xFF38BDF8),
                      size: 20,
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandShape({required bool isLeft}) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.rotationZ(isLeft ? -0.15 : 0.15),
      child: Container(
        width: 80,
        height: 110,
        decoration: BoxDecoration(
          color: const Color(0xFFFFD1BA),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isLeft ? 32 : 16),
            topRight: Radius.circular(isLeft ? 16 : 32),
            bottomLeft: const Radius.circular(24),
            bottomRight: const Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Fingers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (i) {
                return Container(
                  width: 12,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC09F),
                    borderRadius: BorderRadius.circular(6),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirtSpot({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF78350F).withOpacity(0.7),
      ),
    );
  }

  Widget _buildStageProgressBar() {
    final stages = [
      {'label': _isUrdu ? 'صابن' : 'Soap', 'icon': Icons.soap_rounded},
      {'label': _isUrdu ? 'رگڑنا' : 'Scrub', 'icon': Icons.waves_rounded},
      {'label': _isUrdu ? 'دھونا' : 'Rinse', 'icon': Icons.water_drop_rounded},
      {'label': _isUrdu ? 'خشک' : 'Dry', 'icon': Icons.dry_cleaning_rounded},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(stages.length, (idx) {
          final isDone = idx < _currentStage;
          final isCurrent = idx == _currentStage;
          final color = isDone
              ? AppTheme.mintGreen
              : (isCurrent ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1));

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCurrent
                      ? color
                      : (isDone ? color.withOpacity(0.2) : Colors.transparent),
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(
                  isDone ? Icons.check_rounded : stages[idx]['icon'] as IconData,
                  color: isCurrent ? Colors.white : color,
                  size: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                stages[idx]['label'] as String,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  color: isCurrent ? const Color(0xFF1E3A8A) : AppTheme.textSecondary,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
