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

class FloatingBubble {
  final String id;
  double x;
  double y;
  final double radius;
  final Color baseColor;
  final double speed;
  bool isPopping;

  FloatingBubble({
    required this.id,
    required this.x,
    required this.y,
    required this.radius,
    required this.baseColor,
    required this.speed,
    this.isPopping = false,
  });
}

class PopBubblesGame extends StatefulWidget {
  final String? childId;
  final bool? isUrdu;

  const PopBubblesGame({
    super.key,
    this.childId,
    this.isUrdu,
  });

  @override
  State<PopBubblesGame> createState() => _PopBubblesGameState();
}

class _PopBubblesGameState extends State<PopBubblesGame> with SingleTickerProviderStateMixin {
  late String _activeChildId;
  late bool _isUrdu;
  DateTime _startTime = DateTime.now();

  final List<FloatingBubble> _bubbles = [];
  int _poppedCount = 0;
  bool _isCompleted = false;

  final math.Random _random = math.Random();
  Timer? _floatTimer;

  // Soft pastel bubble palette
  final List<Color> _bubbleColors = const [
    Color(0xFF38BDF8), // Sky
    Color(0xFFA78BFA), // Lavender
    Color(0xFF34D399), // Mint
    Color(0xFFF472B6), // Rose
    Color(0xFFFCD34D), // Sun
    Color(0xFF818CF8), // Periwinkle
  ];

  @override
  void initState() {
    super.initState();
    _activeChildId = widget.childId ?? 'child_demo_01';
    _isUrdu = widget.isUrdu ?? LocalizationService.instance.isUrdu;
    _startTime = DateTime.now();

    _initializeBubbles();
    _startFloatLoop();

    _loadChildDetails();
    _speakInstruction();
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

  void _initializeBubbles() {
    for (int i = 0; i < 7; i++) {
      _bubbles.add(_createRandomBubble('bubble_$i', initialY: 0.15 + (i * 0.11)));
    }
  }

  FloatingBubble _createRandomBubble(String id, {double? initialY}) {
    return FloatingBubble(
      id: id,
      x: 0.12 + (_random.nextDouble() * 0.76),
      y: initialY ?? (1.05 + (_random.nextDouble() * 0.2)),
      radius: 32.0 + (_random.nextDouble() * 26.0),
      baseColor: _bubbleColors[_random.nextInt(_bubbleColors.length)],
      speed: 0.0035 + (_random.nextDouble() * 0.003),
    );
  }

  void _startFloatLoop() {
    _floatTimer = Timer.periodic(const Duration(milliseconds: 32), (timer) {
      if (!mounted || _isCompleted) return;

      setState(() {
        for (int i = 0; i < _bubbles.length; i++) {
          final bubble = _bubbles[i];
          if (!bubble.isPopping) {
            bubble.y -= bubble.speed;
            // Float off top: recycle from bottom
            if (bubble.y < -0.15) {
              _bubbles[i] = _createRandomBubble('bubble_${DateTime.now().microsecondsSinceEpoch}_$i');
            }
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _floatTimer?.cancel();
    super.dispose();
  }

  Future<void> _speakInstruction() async {
    final text = _isUrdu
        ? 'بلبلوں کو چھو کر پھوڑیں اور پرسکون محسوس کریں۔ جب چاہیں مکمل کریں!'
        : 'Pop the floating bubbles gently to relax. Tap Done whenever you feel calm!';
    await TtsService.instance.speak(text, langCode: _isUrdu ? 'ur' : 'en');
  }

  void _popBubble(FloatingBubble bubble) {
    if (bubble.isPopping || _isCompleted) return;

    HapticFeedback.lightImpact();

    setState(() {
      bubble.isPopping = true;
      _poppedCount++;
    });

    // Replace after pop animation
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() {
        final index = _bubbles.indexOf(bubble);
        if (index != -1) {
          _bubbles[index] = _createRandomBubble('bubble_${DateTime.now().microsecondsSinceEpoch}');
        }
      });
    });
  }

  void _handleTouch(Offset localPos, Size areaSize) {
    for (final bubble in _bubbles) {
      if (bubble.isPopping) continue;
      final center = Offset(bubble.x * areaSize.width, bubble.y * areaSize.height);
      final dist = (center - localPos).distance;
      if (dist <= bubble.radius + 18.0) {
        _popBubble(bubble);
        break;
      }
    }
  }

  Future<void> _completeSession() async {
    _floatTimer?.cancel();
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
          'module_name': 'Bubble Pop Calm',
          'interaction_type': 'calming_game',
          'completed_at': FieldValue.serverTimestamp(),
          'duration_seconds': math.max(1, duration),
        });
      }
    } catch (e) {
      debugPrint('PopBubblesGame activity log error: $e');
    }

    final cheer = _isUrdu
        ? 'شاباش! آپ نے بہت پرسکون وقت گزارا!'
        : 'Wonderful! You took a calm and peaceful sensory moment!';
    await TtsService.instance.speak(cheer, langCode: _isUrdu ? 'ur' : 'en');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F2FE),
      body: Stack(
        children: [
          // Pastel Ocean Ambience Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFBAE6FD),
                    Color(0xFFE0F2FE),
                    Color(0xFFEDE9FE),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 6),
                _buildPoppedBadge(),

                // Interactive Bubble Pond
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final areaSize = Size(constraints.maxWidth, constraints.maxHeight);

                      return GestureDetector(
                        key: const Key('bubbles_touch_canvas'),
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (details) => _handleTouch(details.localPosition, areaSize),
                        onPanUpdate: (details) => _handleTouch(details.localPosition, areaSize),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: _bubbles.map((b) => _buildBubbleWidget(b, areaSize)).toList(),
                        ),
                      );
                    },
                  ),
                ),

                // Prominent Done Button
                _buildDoneButton(),
                const SizedBox(height: 18),
              ],
            ),
          ),

          // Completion Celebration Overlay
          if (_isCompleted)
            CelebrationOverlay(
              moduleTitle: _isUrdu ? 'بلبلوں کا پرسکون مشن' : 'Bubble Pop Calm',
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
            key: const Key('pop_bubbles_back_btn'),
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
                  color: const Color(0xFF0284C7).withOpacity(0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bubble_chart_rounded, color: Color(0xFF0284C7), size: 22),
                const SizedBox(width: 8),
                Text(
                  _isUrdu ? 'بلبلے پھوڑیں' : 'Pop Bubbles',
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
            icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF0284C7)),
            onPressed: _speakInstruction,
          ),
        ],
      ),
    );
  }

  Widget _buildPoppedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.spa_rounded, color: Color(0xFF0284C7), size: 18),
          const SizedBox(width: 8),
          Text(
            _isUrdu ? 'پھوڑے گئے بلبلے: $_poppedCount' : 'Bubbles Popped: $_poppedCount',
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

  Widget _buildBubbleWidget(FloatingBubble bubble, Size areaSize) {
    final posX = bubble.x * areaSize.width - bubble.radius;
    final posY = bubble.y * areaSize.height - bubble.radius;

    return Positioned(
      left: posX,
      top: posY,
      child: GestureDetector(
        key: Key('bubble_${bubble.id}'),
        onTap: () => _popBubble(bubble),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 200),
          scale: bubble.isPopping ? 1.4 : 1.0,
          curve: Curves.easeOutBack,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: bubble.isPopping ? 0.0 : 0.85,
            child: Container(
              width: bubble.radius * 2,
              height: bubble.radius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.3),
                  radius: 0.85,
                  colors: [
                    Colors.white.withOpacity(0.9),
                    bubble.baseColor.withOpacity(0.65),
                    bubble.baseColor.withOpacity(0.35),
                  ],
                ),
                border: Border.all(color: Colors.white.withOpacity(0.85), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: bubble.baseColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Little specular gleam highlight
                  Positioned(
                    top: bubble.radius * 0.35,
                    left: bubble.radius * 0.35,
                    child: Container(
                      width: bubble.radius * 0.35,
                      height: bubble.radius * 0.35,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.75),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
          key: const Key('pop_bubbles_done_btn'),
          onPressed: _completeSession,
          icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
          label: Text(
            _isUrdu ? 'میں پرسکون ہوں (مکمل)' : 'I Feel Calm (Complete)',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0284C7),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            elevation: 4,
          ),
        ),
      ),
    );
  }
}
