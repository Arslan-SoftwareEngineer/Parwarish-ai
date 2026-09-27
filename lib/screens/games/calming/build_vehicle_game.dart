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

enum VehiclePartType { chassis, wheels, cabin }

class VehiclePiece {
  final VehiclePartType type;
  final String id;
  final String titleEn;
  final String titleUr;
  final IconData icon;
  final Offset targetPosition; // Relative offset inside blueprint container
  final Size size;
  final Color primaryColor;
  final Color secondaryColor;

  const VehiclePiece({
    required this.type,
    required this.id,
    required this.titleEn,
    required this.titleUr,
    required this.icon,
    required this.targetPosition,
    required this.size,
    required this.primaryColor,
    required this.secondaryColor,
  });
}

class BuildVehicleGame extends StatefulWidget {
  final String? childId;
  final bool? isUrdu;

  const BuildVehicleGame({
    super.key,
    this.childId,
    this.isUrdu,
  });

  @override
  State<BuildVehicleGame> createState() => _BuildVehicleGameState();
}

class _BuildVehicleGameState extends State<BuildVehicleGame> with TickerProviderStateMixin {
  late String _activeChildId;
  late bool _isUrdu;
  DateTime _startTime = DateTime.now();

  final List<VehiclePiece> _pieces = const [
    VehiclePiece(
      type: VehiclePartType.chassis,
      id: 'part_chassis',
      titleEn: 'Car Body',
      titleUr: 'گاڑی کا فریم',
      icon: Icons.directions_car_filled_rounded,
      targetPosition: Offset(20, 100),
      size: Size(220, 70),
      primaryColor: Color(0xFF2563EB),
      secondaryColor: Color(0xFF60A5FA),
    ),
    VehiclePiece(
      type: VehiclePartType.cabin,
      id: 'part_cabin',
      titleEn: 'Roof & Windows',
      titleUr: 'چھت اور کھڑکیاں',
      icon: Icons.roofing_rounded,
      targetPosition: Offset(65, 40),
      size: Size(130, 65),
      primaryColor: Color(0xFF0284C7),
      secondaryColor: Color(0xFF38BDF8),
    ),
    VehiclePiece(
      type: VehiclePartType.wheels,
      id: 'part_wheels',
      titleEn: 'Round Wheels',
      titleUr: 'پہیے',
      icon: Icons.radio_button_checked_rounded,
      targetPosition: Offset(35, 155),
      size: Size(190, 50),
      primaryColor: Color(0xFF334155),
      secondaryColor: Color(0xFF64748B),
    ),
  ];

  final Set<VehiclePartType> _assembledParts = {};
  bool _headlightsOn = false;
  bool _isDrivingAway = false;
  bool _isCompleted = false;

  late AnimationController _driveController;
  late AnimationController _idleController;

  @override
  void initState() {
    super.initState();
    _activeChildId = widget.childId ?? 'child_demo_01';
    _isUrdu = widget.isUrdu ?? LocalizationService.instance.isUrdu;
    _startTime = DateTime.now();

    _driveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

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
    _driveController.dispose();
    _idleController.dispose();
    super.dispose();
  }

  Future<void> _speakInstruction() async {
    final text = _isUrdu
        ? 'گاڑی کے حصوں کو بلیو پرنٹ پر لگائیں اور مکمل کریں!'
        : 'Snap the vehicle parts onto the blueprint to build your car!';
    await TtsService.instance.speak(text, langCode: _isUrdu ? 'ur' : 'en');
  }

  void _snapPiece(VehiclePiece piece) {
    if (_assembledParts.contains(piece.type) || _isCompleted) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _assembledParts.add(piece.type);
    });

    final name = _isUrdu ? piece.titleUr : piece.titleEn;
    final speech = _isUrdu ? 'بہت اچھے! $name لگ گیا!' : 'Click! $name snapped into place!';
    TtsService.instance.speak(speech, langCode: _isUrdu ? 'ur' : 'en');

    if (_assembledParts.length == 3) {
      _triggerVehicleActivation();
    }
  }

  Future<void> _triggerVehicleActivation() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    // Headlights on
    HapticFeedback.heavyImpact();
    setState(() {
      _headlightsOn = true;
    });

    final honk = _isUrdu ? 'پو پو! گاڑی تیار ہے اور چل پڑی!' : 'Beep beep! Car is assembled and ready to roll!';
    TtsService.instance.speak(honk, langCode: _isUrdu ? 'ur' : 'en');

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    // Vehicle drives off
    setState(() {
      _isDrivingAway = true;
    });
    _driveController.forward();

    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

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
          'module_name': 'Build Vehicle',
          'interaction_type': 'assembly_game',
          'completed_at': FieldValue.serverTimestamp(),
          'duration_seconds': math.max(1, duration),
        });
      }
    } catch (e) {
      debugPrint('BuildVehicleGame activity log error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Technical Blueprint dark blue
      body: Stack(
        children: [
          // Blueprint Grid Pattern Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF1E293B),
                    Color(0xFF0F2A4A),
                  ],
                ),
              ),
              child: CustomPaint(
                painter: _BlueprintGridPainter(),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 6),
                _buildAssemblyProgressBadge(),
                const SizedBox(height: 12),

                // Blueprint Target Station
                Expanded(
                  child: Center(
                    child: _buildBlueprintVehicleStation(),
                  ),
                ),

                // Bottom Parts Tray
                _buildPartsTray(),
                const SizedBox(height: 18),
              ],
            ),
          ),

          // Completion Celebration Overlay
          if (_isCompleted)
            CelebrationOverlay(
              moduleTitle: _isUrdu ? 'گاڑی بنانے کا مشن' : 'Vehicle Assembly Mission',
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
            key: const Key('build_vehicle_back_btn'),
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0284C7).withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.build_rounded, color: Color(0xFF38BDF8), size: 20),
                const SizedBox(width: 8),
                Text(
                  _isUrdu ? 'گاڑی بنائیں' : 'Build Vehicle',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF38BDF8)),
            onPressed: _speakInstruction,
          ),
        ],
      ),
    );
  }

  Widget _buildAssemblyProgressBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0284C7).withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.precision_manufacturing_rounded, color: Color(0xFF38BDF8), size: 20),
          const SizedBox(width: 8),
          Text(
            _isUrdu
                ? 'جڑے ہوئے پرزے: ${_assembledParts.length}/3'
                : 'Parts Assembled: ${_assembledParts.length}/3',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlueprintVehicleStation() {
    return AnimatedBuilder(
      animation: Listenable.merge([_driveController, _idleController]),
      builder: (context, child) {
        // When driving away, slide X across screen
        final driveOffset = _isDrivingAway ? (_driveController.value * 500.0) : 0.0;
        final driveTilt = _isDrivingAway ? 0.04 : 0.0;
        final isAssembled = _assembledParts.length == 3;
        final engineBounce = (isAssembled && !_isDrivingAway)
            ? math.sin(_idleController.value * math.pi * 2) * 2.5
            : 0.0;

        return Transform.translate(
          offset: Offset(driveOffset, 0),
          child: Transform.rotate(
            angle: driveTilt,
            child: Container(
              width: 280,
              height: 240,
              decoration: BoxDecoration(
                color: const Color(0xFF0B1E38).withOpacity(0.75),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: const Color(0xFF38BDF8).withOpacity(0.6),
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Blueprint Ground Grid Line / Road
                  Positioned(
                    bottom: 30,
                    left: 10,
                    right: 10,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withOpacity(0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Dashed Silhouette Outlines of the Vehicle
                  CustomPaint(
                    size: const Size(280, 240),
                    painter: _VehicleSilhouettePainter(assembledParts: _assembledParts),
                  ),

                  // Animated Exhaust Smoke Clouds (when engine is alive)
                  if (_headlightsOn)
                    ..._buildExhaustPuffs(),

                  // Car Body Group with suspension idle bounce
                  Transform.translate(
                    offset: Offset(0, engineBounce),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Snapped Cabin Piece
                        if (_assembledParts.contains(VehiclePartType.cabin))
                          Positioned(
                            left: _pieces[1].targetPosition.dx + 5,
                            top: _pieces[1].targetPosition.dy + 8,
                            child: _buildCabinWidget(),
                          ),

                        // Snapped Chassis Piece
                        if (_assembledParts.contains(VehiclePartType.chassis))
                          Positioned(
                            left: _pieces[0].targetPosition.dx + 5,
                            top: _pieces[0].targetPosition.dy + 12,
                            child: _buildChassisWidget(),
                          ),

                        // Glowing Radiant Headlight Beam
                        if (_headlightsOn)
                          Positioned(
                            right: -58,
                            top: 114,
                            child: Container(
                              width: 70,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFFEF08A).withOpacity(0.9),
                                    const Color(0xFFFDE047).withOpacity(0.4),
                                    Colors.transparent,
                                  ],
                                ),
                                borderRadius: const BorderRadius.horizontal(right: Radius.circular(24)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Snapped Wheels Piece (Mounted on ground with spinning rims)
                  if (_assembledParts.contains(VehiclePartType.wheels))
                    Positioned(
                      left: _pieces[2].targetPosition.dx + 5,
                      top: _pieces[2].targetPosition.dy + 16,
                      child: _buildWheelsWidget(isSpinning: isAssembled),
                    ),

                  // DragTargets for each of the 3 pieces with magnetic snap
                  Positioned.fill(
                    child: DragTarget<VehiclePiece>(
                      key: const Key('blueprint_drag_target'),
                      onWillAcceptWithDetails: (details) => !_assembledParts.contains(details.data.type),
                      onAcceptWithDetails: (details) => _snapPiece(details.data),
                      builder: (context, candidateData, rejectedData) {
                        return const SizedBox.expand();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildExhaustPuffs() {
    final puffProgress = _idleController.value;
    return [
      Positioned(
        left: 20 - (puffProgress * 22),
        top: 155 - (puffProgress * 12),
        child: Opacity(
          opacity: (1.0 - puffProgress).clamp(0.0, 1.0),
          child: Container(
            width: 14 + (puffProgress * 14),
            height: 14 + (puffProgress * 14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.65),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.4),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
      ),
      Positioned(
        left: 12 - (puffProgress * 15),
        top: 160 - (puffProgress * 8),
        child: Opacity(
          opacity: (0.8 - puffProgress * 0.8).clamp(0.0, 1.0),
          child: Container(
            width: 10 + (puffProgress * 10),
            height: 10 + (puffProgress * 10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFBAE6FD).withOpacity(0.6),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildChassisWidget() {
    return SizedBox(
      width: 220,
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Aerodynamic Rear Wing / Spoiler
          Positioned(
            left: 2,
            top: 2,
            child: Container(
              width: 26,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFF1D4ED8),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 24,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF60A5FA),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),

          // Main Sleek Sports Roadster Chassis Body
          Positioned(
            top: 12,
            left: 10,
            child: Container(
              width: 204,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF60A5FA),
                    Color(0xFF2563EB),
                    Color(0xFF1D4ED8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(12),
                  topRight: Radius.circular(24),
                  bottomRight: Radius.circular(14),
                ),
                border: Border.all(color: Colors.white.withOpacity(0.85), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1D4ED8).withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Racing Stripe down the side
                  Positioned(
                    top: 16,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // Chrome Front Grille
                  Positioned(
                    right: 4,
                    top: 12,
                    bottom: 12,
                    child: Container(
                      width: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  // Headlight Glass Lens
                  Positioned(
                    right: 12,
                    top: 6,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFEF08A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Wheel Cutout Arches (Black inner recesses)
          Positioned(
            bottom: 4,
            left: 38,
            child: Container(
              width: 44,
              height: 22,
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            right: 28,
            child: Container(
              width: 44,
              height: 22,
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCabinWidget() {
    return Container(
      width: 130,
      height: 65,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF7DD3FC),
            Color(0xFF38BDF8),
            Color(0xFF0284C7),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(32),
        ),
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Roof Gloss Highlight
          Positioned(
            top: 4,
            left: 20,
            right: 20,
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Double Tinted Windows with smiling driver peek
          Positioned(
            top: 14,
            left: 12,
            right: 12,
            bottom: 8,
            child: Row(
              children: [
                // Front / Rear Windows
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Center(
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF0284C7), width: 2),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFBAE6FD),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.visibility_rounded,
                        color: const Color(0xFF0284C7).withOpacity(0.6),
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWheelsWidget({bool isSpinning = false}) {
    return SizedBox(
      width: 190,
      height: 52,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSingleCartoonWheel(isSpinning: isSpinning),
          _buildSingleCartoonWheel(isSpinning: isSpinning),
        ],
      ),
    );
  }

  Widget _buildSingleCartoonWheel({bool isSpinning = false}) {
    final spinAngle = isSpinning ? (_idleController.value * math.pi * 4) : 0.0;

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1E293B),
        border: Border.all(color: const Color(0xFF475569), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        // Outer Rubber Tread Ribs
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF334155),
            border: Border.all(color: const Color(0xFF64748B), width: 2),
          ),
          child: Center(
            // Spinning Star Spoke Hubcap
            child: Transform.rotate(
              angle: spinAngle,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0xFFF1F5F9),
                      Color(0xFF94A3B8),
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.stars_rounded,
                    color: Color(0xFF334155),
                    size: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPartsTray() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _isUrdu ? 'پرزوں کو گھسیٹیں یا چھو کر جوڑیں' : 'Drag or tap parts to snap into the blueprint',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _pieces.map((piece) {
              final isSnapped = _assembledParts.contains(piece.type);

              if (isSnapped) {
                return SizedBox(
                  width: 82,
                  height: 72,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.mintGreen.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: AppTheme.mintGreen,
                        size: 28,
                      ),
                    ),
                  ),
                );
              }

              final card = _buildPieceCard(piece);

              return Draggable<VehiclePiece>(
                key: Key('draggable_${piece.id}'),
                data: piece,
                feedback: Material(
                  color: Colors.transparent,
                  child: Transform.scale(
                    scale: 1.15,
                    child: card,
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.25,
                  child: card,
                ),
                child: GestureDetector(
                  onTap: () => _snapPiece(piece),
                  child: card,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPieceCard(VehiclePiece piece) {
    return Container(
      width: 84,
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: _buildTrayPieceCartoonGraphic(piece.type),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _isUrdu ? piece.titleUr : piece.titleEn,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 9,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrayPieceCartoonGraphic(VehiclePartType type) {
    switch (type) {
      case VehiclePartType.chassis:
        return Container(
          width: 54,
          height: 24,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      case VehiclePartType.cabin:
        return Container(
          width: 42,
          height: 26,
          decoration: BoxDecoration(
            color: const Color(0xFF38BDF8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: Center(
            child: Container(
              width: 24,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        );
      case VehiclePartType.wheels:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMiniTrayWheel(),
            const SizedBox(width: 4),
            _buildMiniTrayWheel(),
          ],
        );
    }
  }

  Widget _buildMiniTrayWheel() {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF334155),
        border: Border.all(color: const Color(0xFF94A3B8), width: 2),
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFF1F5F9),
          ),
        ),
      ),
    );
  }
}

class _BlueprintGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0284C7).withOpacity(0.08)
      ..strokeWidth = 1.0;

    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _VehicleSilhouettePainter extends CustomPainter {
  final Set<VehiclePartType> assembledParts;

  _VehicleSilhouettePainter({required this.assembledParts});

  @override
  void paint(Canvas canvas, Size size) {
    final dashPaint = Paint()
      ..color = const Color(0xFF38BDF8).withOpacity(0.45)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Chassis Box Outline
    if (!assembledParts.contains(VehiclePartType.chassis)) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(20, 100, 220, 60),
          const Radius.circular(16),
        ),
        dashPaint,
      );
    }

    // Cabin Box Outline
    if (!assembledParts.contains(VehiclePartType.cabin)) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(65, 40, 130, 65),
          const Radius.circular(20),
        ),
        dashPaint,
      );
    }

    // Wheels Outlines
    if (!assembledParts.contains(VehiclePartType.wheels)) {
      canvas.drawCircle(const Offset(59, 180), 24, dashPaint);
      canvas.drawCircle(const Offset(201, 180), 24, dashPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _VehicleSilhouettePainter oldDelegate) {
    return oldDelegate.assembledParts != assembledParts;
  }
}
