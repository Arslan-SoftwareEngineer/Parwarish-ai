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

class ToothQuadrant {
  final int id;
  final String labelEn;
  final String labelUr;
  final bool isUpper;
  int scrubPasses;
  bool isClean;

  ToothQuadrant({
    required this.id,
    required this.labelEn,
    required this.labelUr,
    required this.isUpper,
    this.scrubPasses = 0,
    this.isClean = false,
  });
}

class BrushTeethGame extends StatefulWidget {
  final String? childId;
  final bool? isUrdu;

  const BrushTeethGame({
    super.key,
    this.childId,
    this.isUrdu,
  });

  @override
  State<BrushTeethGame> createState() => _BrushTeethGameState();
}

class _BrushTeethGameState extends State<BrushTeethGame> with TickerProviderStateMixin {
  late String _activeChildId;
  late bool _isUrdu;
  DateTime _startTime = DateTime.now();

  // 6 Prominent teeth: 3 upper, 3 lower
  late List<ToothQuadrant> _teeth;

  // Toothbrush coordinates
  Offset _brushPosition = const Offset(160, 260);

  bool _isCompleted = false;

  late AnimationController _sparkleController;
  late AnimationController _zoomController;
  late Animation<double> _zoomAnimation;

  @override
  void initState() {
    super.initState();
    _activeChildId = widget.childId ?? 'child_demo_01';
    _isUrdu = widget.isUrdu ?? LocalizationService.instance.isUrdu;
    _startTime = DateTime.now();

    _teeth = [
      ToothQuadrant(id: 0, labelEn: 'Top Left', labelUr: 'اوپر بائیں', isUpper: true),
      ToothQuadrant(id: 1, labelEn: 'Top Front', labelUr: 'اوپر سامنے', isUpper: true),
      ToothQuadrant(id: 2, labelEn: 'Top Right', labelUr: 'اوپر دائیں', isUpper: true),
      ToothQuadrant(id: 3, labelEn: 'Bottom Left', labelUr: 'نیچے بائیں', isUpper: false),
      ToothQuadrant(id: 4, labelEn: 'Bottom Front', labelUr: 'نیچے سامنے', isUpper: false),
      ToothQuadrant(id: 5, labelEn: 'Bottom Right', labelUr: 'نیچے دائیں', isUpper: false),
    ];

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Camera zooms into mouth first, zooms out to happy celebrating face at end (Req 10)
    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _zoomAnimation = CurvedAnimation(
      parent: _zoomController,
      curve: Curves.easeInOutCubic,
    );

    // Start with quick face view then zoom into mouth
    _zoomController.forward();

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
    _sparkleController.dispose();
    _zoomController.dispose();
    super.dispose();
  }

  Future<void> _speakInstruction() async {
    final text = _isUrdu
        ? 'ٹوتھ برش کو دانتوں پر گھمائیں تاکہ تمام میل صاف ہو جائے!'
        : 'Move the toothbrush back and forth over each tooth to make them sparkle!';
    await TtsService.instance.speak(text, langCode: _isUrdu ? 'ur' : 'en');
  }

  void _updateBrushPosition(Offset localPosition, Size mouthSize) {
    if (_isCompleted) return;

    final boundedX = localPosition.dx.clamp(40.0, mouthSize.width - 40.0);
    final boundedY = localPosition.dy.clamp(50.0, mouthSize.height - 50.0);

    setState(() {
      _brushPosition = Offset(boundedX, boundedY);
    });

    _checkToothCollision(boundedX, boundedY, mouthSize);
  }

  void _scrubTooth(ToothQuadrant tooth) {
    if (tooth.isClean || _isCompleted) return;
    HapticFeedback.selectionClick();
    setState(() {
      tooth.scrubPasses++;
      if (tooth.scrubPasses >= 3) {
        tooth.isClean = true;
        HapticFeedback.mediumImpact();
        if (!_sparkleController.isAnimating) {
          _sparkleController.repeat(reverse: true);
        }
      }
    });

    // Check if all 6 teeth are clean
    if (_teeth.every((t) => t.isClean)) {
      _triggerCelebration();
    }
  }

  void _checkToothCollision(double x, double y, Size mouthSize) {
    // Determine which tooth quadrant the brush head covers
    final relX = x / mouthSize.width;
    final relY = y / mouthSize.height;

    int col = 1;
    if (relX < 0.40) {
      col = 0;
    } else if (relX > 0.60) {
      col = 2;
    }

    int row = (relY < 0.52) ? 0 : 1;
    int toothIndex = row * 3 + col;

    if (toothIndex >= 0 && toothIndex < _teeth.length) {
      _scrubTooth(_teeth[toothIndex]);
    }
  }

  Future<void> _triggerCelebration() async {
    // Zoom out camera to full celebrating child face (Req 10)
    _zoomController.reverse();
    _sparkleController.repeat(reverse: true);
    HapticFeedback.heavyImpact();
    setState(() {
      _isCompleted = true;
    });

    final duration = DateTime.now().difference(_startTime).inSeconds;

    // Log to Firestore
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('children')
            .doc(_activeChildId)
            .collection('activity_logs')
            .add({
          'module_name': 'Brush Teeth Routine',
          'interaction_type': 'touch_game',
          'completed_at': FieldValue.serverTimestamp(),
          'duration_seconds': math.max(1, duration),
        });
      }
    } catch (e) {
      debugPrint('BrushTeethGame activity log error: $e');
    }

    final praise = _isUrdu
        ? 'شاباش! دانت موتیوں کی طرح چمک رہے ہیں!'
        : 'Brilliant! All teeth are sparkling pearly white!';
    await TtsService.instance.speak(praise, langCode: _isUrdu ? 'ur' : 'en');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
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
                    Color(0xFFDCFCE7),
                    Color(0xFFF0FDF4),
                    Color(0xFFBBF7D0),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 8),
                _buildTeethProgressCard(),
                Expanded(
                  child: Center(
                    child: _buildMouthInteractiveScene(),
                  ),
                ),
                _buildBrushGuideIndicator(),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Completion Celebration Overlay
          if (_isCompleted)
            CelebrationOverlay(
              moduleTitle: _isUrdu ? 'دانت صاف کرنے کا مشن' : 'Brush Teeth Routine',
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
            key: const Key('brush_teeth_back_btn'),
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
                  color: const Color(0xFF10B981).withOpacity(0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sentiment_very_satisfied_rounded, color: Color(0xFF059669), size: 22),
                const SizedBox(width: 8),
                Text(
                  _isUrdu ? 'دانت صاف کرنا' : 'Brush Teeth',
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
            icon: const Icon(
              Icons.volume_up_rounded,
              color: Color(0xFF059669),
            ),
            onPressed: _speakInstruction,
          ),
        ],
      ),
    );
  }

  Widget _buildTeethProgressCard() {
    final cleanCount = _teeth.where((t) => t.isClean).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFA7F3D0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Color(0xFF059669), size: 24),
              const SizedBox(width: 8),
              Text(
                _isUrdu ? 'صاف دانت: $cleanCount/6' : 'Clean Teeth: $cleanCount/6',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF065F46),
                ),
              ),
            ],
          ),
          // Progress stars
          Row(
            children: List.generate(6, (idx) {
              final isDone = idx < cleanCount;
              return Icon(
                Icons.star_rounded,
                color: isDone ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
                size: 20,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMouthInteractiveScene() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sceneWidth = math.min(constraints.maxWidth * 0.92, 380.0);
        final sceneHeight = 360.0;
        final mouthSize = Size(sceneWidth, sceneHeight);

        return GestureDetector(
          key: const Key('mouth_interactive_pan'),
          onPanStart: (details) => _updateBrushPosition(details.localPosition, mouthSize),
          onPanUpdate: (details) => _updateBrushPosition(details.localPosition, mouthSize),
          onTapDown: (details) => _updateBrushPosition(details.localPosition, mouthSize),
          child: AnimatedBuilder(
            animation: _zoomAnimation,
            builder: (context, child) {
              final zoomScale = 0.72 + 0.28 * _zoomAnimation.value;

              return Transform.scale(
                scale: zoomScale,
                child: Container(
                  width: sceneWidth,
                  height: sceneHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(36),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFFBEB),
                        Color(0xFFFEF3C7),
                        Color(0xFFFDE68A),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD97706).withOpacity(0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 14),
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Cartoon Kid Face (Hair, Eyes, Cheeks, Ears) - Visible when zoomed out
                      _buildCartoonKidFace(sceneWidth, sceneHeight),

                      // Cheerful Cartoon Mouth with Pink Gums & Deep Cavity
                      Positioned(
                        top: 100,
                        left: sceneWidth * 0.08,
                        right: sceneWidth * 0.08,
                        height: 210,
                        child: _buildMouthWithGums(sceneWidth),
                      ),

                      // Pan-Controlled Toothbrush
                      Positioned(
                        left: _brushPosition.dx - 24,
                        top: _brushPosition.dy - 30,
                        child: _buildToothbrushWidget(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCartoonKidFace(double sceneWidth, double sceneHeight) {
    return Positioned.fill(
      child: Stack(
        children: [
          // Hair Locks on top
          Positioned(
            top: 0,
            left: 20,
            right: 20,
            height: 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (i) {
                return Container(
                  width: 55,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF78350F),
                    borderRadius: BorderRadius.circular(30),
                  ),
                );
              }),
            ),
          ),
          // Big Cartoon Eyes with happy eyebrows
          Positioned(
            top: 55,
            left: sceneWidth * 0.22,
            child: _buildCartoonEye(isLeft: true),
          ),
          Positioned(
            top: 55,
            right: sceneWidth * 0.22,
            child: _buildCartoonEye(isLeft: false),
          ),
          // Cute Rosy Cheeks
          Positioned(
            top: 155,
            left: 18,
            child: Container(
              width: 38,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFFFDA4AF).withOpacity(0.65),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            top: 155,
            right: 18,
            child: Container(
              width: 38,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFFFDA4AF).withOpacity(0.65),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartoonEye({required bool isLeft}) {
    return Column(
      children: [
        // Happy Eyebrow
        Container(
          width: 34,
          height: 6,
          decoration: BoxDecoration(
            color: const Color(0xFF78350F),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        // Sparkling Eye
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 4),
            ],
          ),
          child: Center(
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                shape: BoxShape.circle,
              ),
              child: Align(
                alignment: Alignment.topLeft,
                child: Container(
                  margin: const EdgeInsets.all(4),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMouthWithGums(double sceneWidth) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE11D48), // Outer lips
        borderRadius: BorderRadius.circular(105),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9F1239).withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: const Color(0xFFFDA4AF), width: 6),
      ),
      child: Center(
        // Oral Cavity
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF881337), // Deep mouth interior
            borderRadius: BorderRadius.circular(95),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Tongue at bottom
              Positioned(
                bottom: 8,
                child: Container(
                  width: 140,
                  height: 45,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFB7185),
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              // Upper Gums pink scalloped band
              Positioned(
                top: 8,
                child: Container(
                  width: 220,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDA4AF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              // Lower Gums pink scalloped band
              Positioned(
                bottom: 8,
                child: Container(
                  width: 220,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDA4AF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              // Teeth Grid
              _buildTeethGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeethGrid() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Upper Teeth Row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildToothWidget(_teeth[0]),
            const SizedBox(width: 8),
            _buildToothWidget(_teeth[1]),
            const SizedBox(width: 8),
            _buildToothWidget(_teeth[2]),
          ],
        ),
        const SizedBox(height: 10),
        // Lower Teeth Row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildToothWidget(_teeth[3]),
            const SizedBox(width: 8),
            _buildToothWidget(_teeth[4]),
            const SizedBox(width: 8),
            _buildToothWidget(_teeth[5]),
          ],
        ),
      ],
    );
  }

  Widget _buildToothWidget(ToothQuadrant tooth) {
    final isClean = tooth.isClean;

    return GestureDetector(
      key: Key('tooth_${tooth.id}'),
      onTap: () {
        final double x = (tooth.id % 3 == 0) ? 120.0 : (tooth.id % 3 == 1 ? 190.0 : 260.0);
        final double y = tooth.isUpper ? 140.0 : 220.0;
        setState(() {
          _brushPosition = Offset(x, y);
        });
        _scrubTooth(tooth);
      },
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // The Tooth itself - Unmistakable cartoon tooth with enamel shine
          Container(
            width: 58,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isClean
                    ? [Colors.white, const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)]
                    : [const Color(0xFFFEF3C7), const Color(0xFFFDE68A), const Color(0xFFF59E0B)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(tooth.isUpper ? 16 : 8),
                topRight: Radius.circular(tooth.isUpper ? 16 : 8),
                bottomLeft: Radius.circular(tooth.isUpper ? 8 : 16),
                bottomRight: Radius.circular(tooth.isUpper ? 8 : 16),
              ),
              border: Border.all(
                color: isClean ? Colors.white : const Color(0xFFFCD34D),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isClean ? Colors.white.withOpacity(0.8) : Colors.black26,
                  blurRadius: isClean ? 12 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Enamel Gloss Highlight Strip
                Positioned(
                  top: 6,
                  left: 8,
                  child: Container(
                    width: 14,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),

                // If dirty, show yellow/brown plaque with remaining passes
                if (!isClean)
                  Opacity(
                    opacity: (1.0 - (tooth.scrubPasses / 3)).clamp(0.2, 1.0),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFD97706).withOpacity(0.75),
                      ),
                      child: Center(
                        child: Text(
                          '${3 - tooth.scrubPasses}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Foamy lather bubbles when scrubbing
                if (tooth.scrubPasses > 0 && !isClean)
                  Positioned(
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('🫧', style: TextStyle(fontSize: 12)),
                    ),
                  ),
              ],
            ),
          ),

          // White Sparkle Star ABOVE clean teeth (Req 9)
          if (isClean)
            Positioned(
              top: tooth.isUpper ? -14 : null,
              bottom: tooth.isUpper ? null : -14,
              child: AnimatedBuilder(
                animation: _sparkleController,
                builder: (context, _) {
                  final scale = 0.8 + 0.4 * _sparkleController.value;
                  return Transform.scale(
                    scale: scale,
                    child: const Icon(
                      Icons.star_rounded,
                      color: Colors.white,
                      size: 24,
                      shadows: [
                        Shadow(color: Color(0xFF38BDF8), blurRadius: 10),
                        Shadow(color: Colors.white, blurRadius: 6),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToothbrushWidget() {
    return IgnorePointer(
      child: Transform.rotate(
        angle: -math.pi / 5,
        child: SizedBox(
          width: 70,
          height: 120,
          child: Column(
            children: [
              // Brush Head with Soft White Bristles & Mint Foam
              Container(
                width: 32,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF38BDF8), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF38BDF8).withOpacity(0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(3, (i) {
                    return Container(
                      width: 22,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF67E8F9),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
              ),
              // Toothbrush Handle (Ergonomic Teal)
              Container(
                width: 14,
                height: 65,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(2, 4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrushGuideIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          const Icon(Icons.touch_app_rounded, color: Color(0xFF059669), size: 20),
          const SizedBox(width: 8),
          Text(
            _isUrdu ? 'برش کو انگلی سے دانتوں پر رگڑیں' : 'Drag brush over each tooth 3 times',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
