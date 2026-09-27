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

enum FruitTier { strawberry, orange, apple }

class FruitTile {
  final String id;
  FruitTier tier;

  FruitTile({
    required this.id,
    required this.tier,
  });

  String get titleEn {
    switch (tier) {
      case FruitTier.strawberry:
        return 'Strawberry';
      case FruitTier.orange:
        return 'Orange';
      case FruitTier.apple:
        return 'Apple';
    }
  }

  String get titleUr {
    switch (tier) {
      case FruitTier.strawberry:
        return 'سٹرابیری';
      case FruitTier.orange:
        return 'مالٹا';
      case FruitTier.apple:
        return 'سیب';
    }
  }

  IconData get icon {
    switch (tier) {
      case FruitTier.strawberry:
        return Icons.eco_rounded;
      case FruitTier.orange:
        return Icons.circle_rounded;
      case FruitTier.apple:
        return Icons.spa_rounded;
    }
  }

  Color get primaryColor {
    switch (tier) {
      case FruitTier.strawberry:
        return const Color(0xFFEF4444);
      case FruitTier.orange:
        return const Color(0xFFEA580C);
      case FruitTier.apple:
        return const Color(0xFF10B981);
    }
  }

  Color get secondaryColor {
    switch (tier) {
      case FruitTier.strawberry:
        return const Color(0xFFF87171);
      case FruitTier.orange:
        return const Color(0xFFFB923C);
      case FruitTier.apple:
        return const Color(0xFF34D399);
    }
  }
}

class FruitMergeGame extends StatefulWidget {
  final String? childId;
  final bool? isUrdu;

  const FruitMergeGame({
    super.key,
    this.childId,
    this.isUrdu,
  });

  @override
  State<FruitMergeGame> createState() => _FruitMergeGameState();
}

class _FruitMergeGameState extends State<FruitMergeGame> {
  late String _activeChildId;
  late bool _isUrdu;
  DateTime _startTime = DateTime.now();

  // Initial tray: 4 Strawberries (2 pairs)
  late List<FruitTile?> _slots;
  String? _selectedTileId;
  String? _recentlyMergedTileId;
  bool _isCompleted = false;

  Timer? _squishTimer;

  @override
  void initState() {
    super.initState();
    _activeChildId = widget.childId ?? 'child_demo_01';
    _isUrdu = widget.isUrdu ?? LocalizationService.instance.isUrdu;
    _startTime = DateTime.now();

    // 6 Tray slots: 4 filled with Strawberries, 2 empty
    _slots = [
      FruitTile(id: 'fruit_1', tier: FruitTier.strawberry),
      FruitTile(id: 'fruit_2', tier: FruitTier.strawberry),
      FruitTile(id: 'fruit_3', tier: FruitTier.strawberry),
      FruitTile(id: 'fruit_4', tier: FruitTier.strawberry),
      null,
      null,
    ];

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
    _squishTimer?.cancel();
    super.dispose();
  }

  Future<void> _speakInstruction() async {
    final text = _isUrdu
        ? 'ایک جیسے پھلوں کو ایک دوسرے پر لائیں تاکہ نیا مزیدار پھل بنے!'
        : 'Drag or tap two identical fruits together to merge them into a bigger fruit!';
    await TtsService.instance.speak(text, langCode: _isUrdu ? 'ur' : 'en');
  }

  void _onTileTapped(int slotIndex) {
    final tile = _slots[slotIndex];
    if (tile == null || _isCompleted) return;

    if (_selectedTileId == null) {
      // First selection
      HapticFeedback.selectionClick();
      setState(() {
        _selectedTileId = tile.id;
      });
    } else if (_selectedTileId == tile.id) {
      // Deselect
      setState(() {
        _selectedTileId = null;
      });
    } else {
      // Second selection: check if match
      final firstIndex = _slots.indexWhere((s) => s?.id == _selectedTileId);
      if (firstIndex != -1) {
        final firstTile = _slots[firstIndex]!;
        if (firstTile.tier == tile.tier && firstTile.tier != FruitTier.apple) {
          _executeMerge(sourceIndex: firstIndex, targetIndex: slotIndex);
        } else {
          HapticFeedback.lightImpact();
          setState(() {
            _selectedTileId = tile.id;
          });
        }
      }
    }
  }

  void _onTileDroppedOnTarget({required FruitTile source, required int targetIndex}) {
    final target = _slots[targetIndex];
    if (target == null || target.id == source.id || _isCompleted) return;

    if (source.tier == target.tier && source.tier != FruitTier.apple) {
      final sourceIndex = _slots.indexWhere((s) => s?.id == source.id);
      if (sourceIndex != -1) {
        _executeMerge(sourceIndex: sourceIndex, targetIndex: targetIndex);
      }
    } else {
      // Non-matching drop: gentle haptic feedback
      HapticFeedback.lightImpact();
    }
  }

  void _executeMerge({required int sourceIndex, required int targetIndex}) {
    HapticFeedback.mediumImpact();

    final target = _slots[targetIndex]!;
    FruitTier nextTier;
    String speech;

    if (target.tier == FruitTier.strawberry) {
      nextTier = FruitTier.orange;
      speech = _isUrdu
          ? 'شاباش! دو سٹرابیری مل کر مالٹا بن گئیں!'
          : 'Squish! Two Strawberries merged into a sweet Orange!';
    } else {
      nextTier = FruitTier.apple;
      speech = _isUrdu
          ? 'واہ! دو مالٹے مل کر سنہرا سیب بن گئے!'
          : 'Amazing! Two Oranges merged into a crisp Apple!';
    }

    setState(() {
      _slots[sourceIndex] = null;
      target.tier = nextTier;
      _selectedTileId = null;
      _recentlyMergedTileId = target.id;
    });

    TtsService.instance.speak(speech, langCode: _isUrdu ? 'ur' : 'en');

    _squishTimer?.cancel();
    _squishTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _recentlyMergedTileId = null);
      }
    });

    // If target is now Apple, trigger celebration!
    if (nextTier == FruitTier.apple) {
      _triggerCompletion();
    }
  }

  Future<void> _triggerCompletion() async {
    await Future.delayed(const Duration(milliseconds: 500));
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
          'module_name': 'Fruit Merge',
          'interaction_type': 'sorting_game',
          'completed_at': FieldValue.serverTimestamp(),
          'duration_seconds': math.max(1, duration),
        });
      }
    } catch (e) {
      debugPrint('FruitMergeGame activity log error: $e');
    }

    final cheer = _isUrdu
        ? 'شاباش! آپ نے کامیابی سے سیب بنا لیا!'
        : 'Delicious! You created the magical Apple!';
    await TtsService.instance.speak(cheer, langCode: _isUrdu ? 'ur' : 'en');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7ED),
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
                    Color(0xFFFFF7ED),
                    Color(0xFFDCFCE7),
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
                _buildMergeRuleLegend(),
                const SizedBox(height: 12),

                // Main Wooden Fruit Tray
                Expanded(
                  child: Center(
                    child: _buildWoodenFruitTray(),
                  ),
                ),

                // Instructions / Guide Footnote
                _buildGuideFootnote(),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Completion Celebration Overlay
          if (_isCompleted)
            CelebrationOverlay(
              moduleTitle: _isUrdu ? 'پھل ملانے کا مشن' : 'Fruit Merge Puzzle',
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
            key: const Key('fruit_merge_back_btn'),
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
                  color: const Color(0xFFEA580C).withOpacity(0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_fix_high_rounded, color: Color(0xFFEA580C), size: 22),
                const SizedBox(width: 8),
                Text(
                  _isUrdu ? 'پھلوں کا ملاپ' : 'Fruit Merge',
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
            icon: const Icon(Icons.volume_up_rounded, color: Color(0xFFEA580C)),
            onPressed: _speakInstruction,
          ),
        ],
      ),
    );
  }

  Widget _buildMergeRuleLegend() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: const Color(0xFFFED7AA), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem(Icons.eco_rounded, const Color(0xFFEF4444), _isUrdu ? 'سٹرابیری' : 'Strawberry'),
          const Icon(Icons.arrow_forward_rounded, size: 16, color: AppTheme.textSecondary),
          _buildLegendItem(Icons.circle_rounded, const Color(0xFFEA580C), _isUrdu ? 'مالٹا' : 'Orange'),
          const Icon(Icons.arrow_forward_rounded, size: 16, color: AppTheme.textSecondary),
          _buildLegendItem(Icons.spa_rounded, const Color(0xFF10B981), _isUrdu ? 'سیب' : 'Apple'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 14),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildWoodenFruitTray() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trayWidth = math.min(constraints.maxWidth * 0.92, 360.0);

        return Container(
          width: trayWidth,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFDE68A),
                Color(0xFFFBBF24),
                Color(0xFFD97706),
              ],
            ),
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB45309).withOpacity(0.35),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
            border: Border.all(color: const Color(0xFFFFFBEB), width: 3),
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _slots.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              return _buildSlotWidget(index);
            },
          ),
        );
      },
    );
  }

  Widget _buildSlotWidget(int index) {
    final tile = _slots[index];

    return DragTarget<FruitTile>(
      key: Key('fruit_slot_$index'),
      onWillAcceptWithDetails: (details) => tile != null && tile.id != details.data.id,
      onAcceptWithDetails: (details) => _onTileDroppedOnTarget(source: details.data, targetIndex: index),
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        if (tile == null) {
          // Empty Tray Indentation
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFFB45309).withOpacity(0.18),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
            ),
          );
        }

        final isSelected = _selectedTileId == tile.id;
        final isSquished = _recentlyMergedTileId == tile.id;

        final card = _buildFruitTileCard(tile, isSelected, isSquished || isHovered);

        return Draggable<FruitTile>(
          key: Key('draggable_${tile.id}'),
          data: tile,
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
            onTap: () => _onTileTapped(index),
            child: card,
          ),
        );
      },
    );
  }

  Widget _buildFruitTileCard(FruitTile tile, bool isSelected, bool isSquished) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 220),
      scale: isSquished ? 1.15 : (isSelected ? 1.08 : 1.0),
      curve: Curves.elasticOut,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7).withOpacity(0.5),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? const Color(0xFFEA580C) : Colors.white.withOpacity(0.6),
            width: isSelected ? 3.0 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFEA580C).withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Cartoon Fruit Illustration
            Expanded(
              child: Center(
                child: _buildCartoonFruitGraphic(tile),
              ),
            ),
            // Clean Floating Name Tag
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                _isUrdu ? tile.titleUr : tile.titleEn,
                style: TextStyle(
                  color: tile.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartoonFruitGraphic(FruitTile tile) {
    switch (tile.tier) {
      case FruitTier.strawberry:
        return _buildCartoonStrawberry();
      case FruitTier.orange:
        return _buildCartoonOrange();
      case FruitTier.apple:
        return _buildCartoonApple();
    }
  }

  Widget _buildCartoonStrawberry() {
    return SizedBox(
      width: 54,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Red Berry Heart Body
          Positioned(
            top: 10,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const RadialGradient(
                  center: Alignment(-0.3, -0.3),
                  radius: 0.85,
                  colors: [
                    Color(0xFFF87171),
                    Color(0xFFEF4444),
                    Color(0xFFDC2626),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(22),
                  bottomRight: Radius.circular(22),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDC2626).withOpacity(0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Little Yellow Seeds
                  _buildSeed(10, 10),
                  _buildSeed(22, 8),
                  _buildSeed(32, 12),
                  _buildSeed(14, 20),
                  _buildSeed(26, 22),
                  _buildSeed(20, 32),
                ],
              ),
            ),
          ),

          // Green Calyx Leaves & Stem on top
          Positioned(
            top: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLeaf(-0.3),
                _buildLeaf(0.0),
                _buildLeaf(0.3),
              ],
            ),
          ),
          // Curved Little Stem
          Positioned(
            top: 0,
            child: Container(
              width: 4,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF15803D),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeed(double left, double top) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: 3,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFFEF08A),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildLeaf(double angle) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: 10,
        height: 12,
        decoration: const BoxDecoration(
          color: Color(0xFF22C55E),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildCartoonOrange() {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Spherical Citrus Body
          Positioned(
            top: 6,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  center: Alignment(-0.3, -0.4),
                  radius: 0.9,
                  colors: [
                    Color(0xFFFDBA74),
                    Color(0xFFFB923C),
                    Color(0xFFEA580C),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEA580C).withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Glossy light crescent reflection
                  Positioned(
                    left: 6,
                    top: 6,
                    child: Container(
                      width: 14,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  // Dimple dots for citrus peel
                  Positioned(
                    right: 10,
                    bottom: 12,
                    child: Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFC2410C).withOpacity(0.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Green Citrus Leaf on Top
          Positioned(
            top: 2,
            right: 14,
            child: Transform.rotate(
              angle: 0.5,
              child: Container(
                width: 14,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),

          // Tiny brown stem
          Positioned(
            top: 2,
            child: Container(
              width: 3,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFF78350F),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartoonApple() {
    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Crisp Apple Body with cleft
          Positioned(
            top: 8,
            child: Container(
              width: 50,
              height: 48,
              decoration: BoxDecoration(
                gradient: const RadialGradient(
                  center: Alignment(-0.3, -0.4),
                  radius: 0.9,
                  colors: [
                    Color(0xFF6EE7B7),
                    Color(0xFF34D399),
                    Color(0xFF059669),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF059669).withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Glossy curved highlight
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      width: 14,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  // Sparkle Star (top tier magical fruit!)
                  const Positioned(
                    right: 6,
                    top: 6,
                    child: Icon(
                      Icons.auto_awesome,
                      color: Color(0xFFFEF08A),
                      size: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Curved Wood Stem
          Positioned(
            top: 2,
            child: Container(
              width: 4,
              height: 9,
              decoration: BoxDecoration(
                color: const Color(0xFF78350F),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Bright Leaf
          Positioned(
            top: 3,
            right: 14,
            child: Transform.rotate(
              angle: 0.4,
              child: Container(
                width: 12,
                height: 7,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideFootnote() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.touch_app_rounded, color: Color(0xFFEA580C), size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _isUrdu ? 'پھلوں کو ملائیں تاکہ سیب بنے!' : 'Drag or tap two of the same fruit to merge!',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
