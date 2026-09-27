import 'dart:async';
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

class ShapeRing {
  final int sizeOrder; // 3 = Large, 2 = Medium, 1 = Small
  final String id;
  final String titleEn;
  final String titleUr;
  final double ringWidth;
  final double ringHeight;
  final Color primaryColor;
  final Color secondaryColor;

  const ShapeRing({
    required this.sizeOrder,
    required this.id,
    required this.titleEn,
    required this.titleUr,
    required this.ringWidth,
    required this.ringHeight,
    required this.primaryColor,
    required this.secondaryColor,
  });
}

class ShapeTowerGame extends StatefulWidget {
  final String? childId;
  final bool? isUrdu;

  const ShapeTowerGame({
    super.key,
    this.childId,
    this.isUrdu,
  });

  @override
  State<ShapeTowerGame> createState() => _ShapeTowerGameState();
}

class _ShapeTowerGameState extends State<ShapeTowerGame> {
  late String _activeChildId;
  late bool _isUrdu;
  DateTime _startTime = DateTime.now();

  final List<ShapeRing> _allRings = const [
    ShapeRing(
      sizeOrder: 3,
      id: 'ring_large',
      titleEn: 'Big Ring',
      titleUr: 'بڑا چھلا',
      ringWidth: 180,
      ringHeight: 44,
      primaryColor: Color(0xFFEF4444),
      secondaryColor: Color(0xFFF87171),
    ),
    ShapeRing(
      sizeOrder: 2,
      id: 'ring_medium',
      titleEn: 'Medium Ring',
      titleUr: 'درمیانہ چھلا',
      ringWidth: 135,
      ringHeight: 40,
      primaryColor: Color(0xFFF59E0B),
      secondaryColor: Color(0xFFFCD34D),
    ),
    ShapeRing(
      sizeOrder: 1,
      id: 'ring_small',
      titleEn: 'Small Ring',
      titleUr: 'چھوٹا چھلا',
      ringWidth: 90,
      ringHeight: 36,
      primaryColor: Color(0xFF10B981),
      secondaryColor: Color(0xFF34D399),
    ),
  ];

  final List<ShapeRing> _stackedRings = [];
  String? _wobblingRingId;
  bool _isCompleted = false;

  Timer? _wobbleTimer;

  @override
  void initState() {
    super.initState();
    _activeChildId = widget.childId ?? 'child_demo_01';
    _isUrdu = widget.isUrdu ?? LocalizationService.instance.isUrdu;
    _startTime = DateTime.now();

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

  @override
  void dispose() {
    _wobbleTimer?.cancel();
    super.dispose();
  }

  Future<void> _speakInstruction() async {
    final text = _isUrdu
        ? 'سب سے پہلے سب سے بڑا چھلا کھمبے پر رکھیں، پھر درمیانہ اور آخر میں سب سے چھوٹا!'
        : 'Stack the rings on the wooden peg from largest on the bottom to smallest on top!';
    await TtsService.instance.speak(text, langCode: _isUrdu ? 'ur' : 'en');
  }

  int get _expectedNextSize {
    if (_stackedRings.isEmpty) return 3; // Needs Large (3)
    if (_stackedRings.length == 1) return 2; // Needs Medium (2)
    if (_stackedRings.length == 2) return 1; // Needs Small (1)
    return 0;
  }

  void _onRingPlaced(ShapeRing ring) {
    if (_stackedRings.any((r) => r.id == ring.id) || _isCompleted) return;

    if (ring.sizeOrder == _expectedNextSize) {
      HapticFeedback.mediumImpact();
      setState(() {
        _stackedRings.add(ring);
        _wobblingRingId = null;
      });

      final itemName = _isUrdu ? ring.titleUr : ring.titleEn;
      final praise = _isUrdu ? 'شاباش! $itemName بالکل صحیح بیٹھ گیا!' : 'Perfect! $itemName placed on the peg!';
      TtsService.instance.speak(praise, langCode: _isUrdu ? 'ur' : 'en');

      if (_stackedRings.length == 3) {
        _triggerCompletion();
      }
    } else {
      // Invalid order: ring wobbles horizontally and bounces back to tray
      HapticFeedback.lightImpact();
      setState(() {
        _wobblingRingId = ring.id;
      });

      final hint = _stackedRings.isEmpty
          ? (_isUrdu ? 'سب سے پہلے سب سے بڑا لال چھلا رکھیں!' : 'Place the largest red ring first!')
          : (_isUrdu ? 'چھوٹا چھلا بڑے کے اوپر آتا ہے، صحیح ترتیب دیکھیں!' : 'Look for the next smaller ring to stack!');
      TtsService.instance.speak(hint, langCode: _isUrdu ? 'ur' : 'en');

      _wobbleTimer?.cancel();
      _wobbleTimer = Timer(const Duration(milliseconds: 700), () {
        if (mounted && _wobblingRingId == ring.id) {
          setState(() => _wobblingRingId = null);
        }
      });
    }
  }

  Future<void> _triggerCompletion() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

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
          'module_name': 'Shape Tower',
          'interaction_type': 'sorting_game',
          'completed_at': FieldValue.serverTimestamp(),
          'duration_seconds': math.max(1, duration),
        });
      }
    } catch (e) {
      debugPrint('ShapeTowerGame activity log error: $e');
    }

    final cheer = _isUrdu
        ? 'لاجواب! آپ نے رنگین ٹاور بالکل درست بنا لیا!'
        : 'Marvelous! Your colorful shape tower is complete and sturdy!';
    await TtsService.instance.speak(cheer, langCode: _isUrdu ? 'ur' : 'en');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBEB),
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
                    Color(0xFFFEF3C7),
                    Color(0xFFFFFBEB),
                    Color(0xFFFDE68A),
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
                _buildStepGuideBanner(),
                const SizedBox(height: 10),

                // Center Vertical Wooden Peg Scene
                Expanded(
                  child: Center(
                    child: _buildPegInteractiveScene(),
                  ),
                ),

                // Bottom Ring Tray
                _buildRingsTray(),
                const SizedBox(height: 18),
              ],
            ),
          ),

          // Completion Celebration Overlay
          if (_isCompleted)
            CelebrationOverlay(
              moduleTitle: _isUrdu ? 'شکلوں کا ٹاور مشن' : 'Shape Tower Puzzle',
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
            key: const Key('shape_tower_back_btn'),
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
                  color: const Color(0xFFD97706).withOpacity(0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.layers_rounded, color: Color(0xFFD97706), size: 22),
                const SizedBox(width: 8),
                Text(
                  _isUrdu ? 'شکلوں کا ٹاور' : 'Shape Tower',
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
            icon: const Icon(Icons.volume_up_rounded, color: Color(0xFFD97706)),
            onPressed: _speakInstruction,
          ),
        ],
      ),
    );
  }

  Widget _buildStepGuideBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.swap_vert_rounded, color: Color(0xFFD97706), size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _isUrdu
                  ? 'چھلے ٹاور پر ترتیب سے رکھیں (${_stackedRings.length}/3)'
                  : 'Stack in order: Big -> Medium -> Small (${_stackedRings.length}/3)',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPegInteractiveScene() {
    return DragTarget<ShapeRing>(
      key: const Key('wooden_peg_target'),
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) => _onRingPlaced(details.data),
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return AnimatedScale(
          duration: const Duration(milliseconds: 200),
          scale: isHovered ? 1.04 : 1.0,
          curve: Curves.easeOutBack,
          child: SizedBox(
            width: 260,
            height: 340,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // 1. Wooden Base Plinth (Clean 3D beveled round stand with wood grain and soft shadow)
                Positioned(
                  bottom: 12,
                  child: Container(
                    width: 220,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFFDE68A),
                          Color(0xFFD97706),
                          Color(0xFF92400E),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(21),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF78350F).withOpacity(0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFFEF3C7), width: 2.5),
                    ),
                    child: Center(
                      child: Container(
                        width: 180,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF78350F).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. Centered Smooth Wooden Peg Pole (single continuous wooden cylinder with round wooden ball cap)
                Positioned(
                  bottom: 38,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Wooden Ball Cap on top of peg
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            center: Alignment(-0.3, -0.4),
                            colors: [
                              Color(0xFFFFFBEB),
                              Color(0xFFFBBF24),
                              Color(0xFFB45309),
                            ],
                          ),
                        ),
                      ),
                      // Smooth Wooden Dowel
                      Container(
                        width: 22,
                        height: 210,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color(0xFFFEF3C7),
                              Color(0xFFFBBF24),
                              Color(0xFF92400E),
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(6),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 4,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Stacked Rings on the Peg (Bottom to Top)
                Positioned(
                  bottom: 42,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    verticalDirection: VerticalDirection.up, // Stacks 3 (bottom), then 2, then 1 (top)
                    children: [
                      // Large Ring (Bottom)
                      if (_stackedRings.any((r) => r.sizeOrder == 3))
                        _buildCartoonStackedRing(_allRings.firstWhere((r) => r.sizeOrder == 3)),
                      // Medium Ring (Middle)
                      if (_stackedRings.any((r) => r.sizeOrder == 2))
                        _buildCartoonStackedRing(_allRings.firstWhere((r) => r.sizeOrder == 2)),
                      // Small Ring (Top)
                      if (_stackedRings.any((r) => r.sizeOrder == 1))
                        _buildCartoonStackedRing(_allRings.firstWhere((r) => r.sizeOrder == 1)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCartoonStackedRing(ShapeRing ring) {
    return Container(
      width: ring.ringWidth,
      height: ring.ringHeight,
      margin: const EdgeInsets.only(bottom: 2),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 3D Cartoon Ring Body with bevel highlights
          Container(
            width: ring.ringWidth,
            height: ring.ringHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  ring.secondaryColor,
                  ring.primaryColor,
                  HSLColor.fromColor(ring.primaryColor).withLightness(0.35).toColor(),
                ],
              ),
              borderRadius: BorderRadius.circular(ring.ringHeight / 2),
              border: Border.all(color: Colors.white.withOpacity(0.9), width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: ring.primaryColor.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
          ),

          // Upper glossy rim highlight
          Positioned(
            top: 4,
            child: Container(
              width: ring.ringWidth * 0.72,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.55),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Clear center hole showing the continuous wooden peg inside
          Container(
            width: 26,
            height: ring.ringHeight - 8,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFFFEF3C7),
                  Color(0xFFFBBF24),
                  Color(0xFFB45309),
                ],
              ),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: HSLColor.fromColor(ring.primaryColor).withLightness(0.3).toColor(),
                width: 2,
              ),
            ),
          ),

          // Embossed Shape Pattern Badge
          Positioned(
            right: 18,
            child: Icon(
              ring.sizeOrder == 3
                  ? Icons.star_rounded
                  : (ring.sizeOrder == 2 ? Icons.circle : Icons.favorite_rounded),
              color: Colors.white.withOpacity(0.85),
              size: ring.ringHeight * 0.42,
            ),
          ),
          Positioned(
            left: 18,
            child: Icon(
              ring.sizeOrder == 3
                  ? Icons.star_rounded
                  : (ring.sizeOrder == 2 ? Icons.circle : Icons.favorite_rounded),
              color: Colors.white.withOpacity(0.85),
              size: ring.ringHeight * 0.42,
            ),
          ),
        ],
      ),
    )
        .animate()
        .scale(curve: Curves.easeOutBack, duration: 320.ms)
        .slideY(begin: -0.5, end: 0);
  }

  Widget _buildRingsTray() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFFDE68A), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _isUrdu ? 'چھلوں کو کھینچ کر کھمبے پر رکھیں' : 'Drag or tap rings to stack by size',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: _allRings.map((ring) {
              final isStacked = _stackedRings.any((r) => r.id == ring.id);
              final isWobbling = _wobblingRingId == ring.id;

              if (isStacked) {
                return SizedBox(
                  width: ring.ringWidth * 0.52,
                  height: 60,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.mintGreen.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: AppTheme.mintGreen,
                        size: 24,
                      ),
                    ),
                  ),
                );
              }

              final ringVisual = _buildCartoonTrayRing(ring);

              return Draggable<ShapeRing>(
                key: Key('draggable_${ring.id}'),
                data: ring,
                feedback: Material(
                  color: Colors.transparent,
                  child: Transform.scale(
                    scale: 1.12,
                    child: ringVisual,
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.25,
                  child: ringVisual,
                ),
                child: GestureDetector(
                  onTap: () => _onRingPlaced(ring),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.elasticOut,
                    transform: Matrix4.translationValues(
                      isWobbling ? (math.sin(DateTime.now().millisecondsSinceEpoch) * 12) : 0,
                      0,
                      0,
                    ),
                    child: ringVisual,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCartoonTrayRing(ShapeRing ring) {
    // Proportional real ring in tray with donut hole, 3D highlights and shape symbols
    final displayWidth = ring.ringWidth * 0.52;
    final displayHeight = ring.ringHeight * 1.1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: displayWidth,
          height: displayHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Toroidal 3D ring body
              Container(
                width: displayWidth,
                height: displayHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      ring.secondaryColor,
                      ring.primaryColor,
                      HSLColor.fromColor(ring.primaryColor).withLightness(0.35).toColor(),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(displayHeight / 2),
                  boxShadow: [
                    BoxShadow(
                      color: ring.primaryColor.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),

              // Glossy reflection line
              Positioned(
                top: 4,
                child: Container(
                  width: displayWidth * 0.65,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Donut center hole
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFFBEB),
                  border: Border.all(
                    color: HSLColor.fromColor(ring.primaryColor).withLightness(0.35).toColor(),
                    width: 2,
                  ),
                ),
              ),

              // Embossed shape icon
              Positioned(
                right: 8,
                child: Icon(
                  ring.sizeOrder == 3
                      ? Icons.star_rounded
                      : (ring.sizeOrder == 2 ? Icons.circle : Icons.favorite_rounded),
                  color: Colors.white.withOpacity(0.9),
                  size: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _isUrdu ? ring.titleUr : ring.titleEn,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
