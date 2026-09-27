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

class ShadowMatchItem {
  final String id;
  final String titleEn;
  final String titleUr;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;

  const ShadowMatchItem({
    required this.id,
    required this.titleEn,
    required this.titleUr,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
  });
}

class ShadowMatchGame extends StatefulWidget {
  final String? childId;
  final bool? isUrdu;

  const ShadowMatchGame({
    super.key,
    this.childId,
    this.isUrdu,
  });

  @override
  State<ShadowMatchGame> createState() => _ShadowMatchGameState();
}

class _ShadowMatchGameState extends State<ShadowMatchGame> {
  late String _activeChildId;
  late bool _isUrdu;
  DateTime _startTime = DateTime.now();

  static const List<List<ShadowMatchItem>> _allRounds = [
    // Round 1: Everyday items
    [
      ShadowMatchItem(
        id: 'cup',
        titleEn: 'Cup',
        titleUr: 'پیالی',
        icon: Icons.local_cafe_rounded,
        primaryColor: Color(0xFFEF4444),
        secondaryColor: Color(0xFFF87171),
      ),
      ShadowMatchItem(
        id: 'shoe',
        titleEn: 'Shoe',
        titleUr: 'جوتا',
        icon: Icons.roller_skating_rounded,
        primaryColor: Color(0xFF2563EB),
        secondaryColor: Color(0xFF60A5FA),
      ),
      ShadowMatchItem(
        id: 'banana',
        titleEn: 'Banana',
        titleUr: 'کیلا',
        icon: Icons.wb_sunny_rounded,
        primaryColor: Color(0xFFEAB308),
        secondaryColor: Color(0xFFFDE047),
      ),
    ],
    // Round 2: Fun & Wonder
    [
      ShadowMatchItem(
        id: 'car',
        titleEn: 'Car',
        titleUr: 'گاڑی',
        icon: Icons.directions_car_rounded,
        primaryColor: Color(0xFF10B981),
        secondaryColor: Color(0xFF34D399),
      ),
      ShadowMatchItem(
        id: 'star',
        titleEn: 'Star',
        titleUr: 'ستارہ',
        icon: Icons.star_rounded,
        primaryColor: Color(0xFFF59E0B),
        secondaryColor: Color(0xFFFCD34D),
      ),
      ShadowMatchItem(
        id: 'butterfly',
        titleEn: 'Butterfly',
        titleUr: 'تتلی',
        icon: Icons.flutter_dash_rounded,
        primaryColor: Color(0xFF8B5CF6),
        secondaryColor: Color(0xFFA78BFA),
      ),
    ],
    // Round 3: Sky & Play
    [
      ShadowMatchItem(
        id: 'airplane',
        titleEn: 'Airplane',
        titleUr: 'ہوائی جہاز',
        icon: Icons.airplanemode_active_rounded,
        primaryColor: Color(0xFF0284C7),
        secondaryColor: Color(0xFF38BDF8),
      ),
      ShadowMatchItem(
        id: 'apple',
        titleEn: 'Apple',
        titleUr: 'سیب',
        icon: Icons.apple_rounded,
        primaryColor: Color(0xFFDC2626),
        secondaryColor: Color(0xFFEF4444),
      ),
      ShadowMatchItem(
        id: 'teddy',
        titleEn: 'Teddy',
        titleUr: 'ٹیڈی بیئر',
        icon: Icons.pets_rounded,
        primaryColor: Color(0xFFD97706),
        secondaryColor: Color(0xFFFBBF24),
      ),
    ],
  ];

  int _currentRound = 0; // 0, 1, 2
  List<ShadowMatchItem> get _items => _allRounds[_currentRound];

  // Scramble shadows so they are never directly opposite matching item
  List<ShadowMatchItem> get _shuffledShadows {
    if (_items.length < 3) return _items;
    return [_items[2], _items[0], _items[1]];
  }

  final Set<String> _matchedIds = {};
  String? _selectedSourceId;
  String? _wobbleId;
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
        ? 'چیزوں کو ان کے کالے سائے سے ملائیں!'
        : 'Drag or tap each item to match its dark shadow!';
    await TtsService.instance.speak(text, langCode: _isUrdu ? 'ur' : 'en');
  }

  void _onMatch(ShadowMatchItem source, ShadowMatchItem target) {
    if (_matchedIds.contains(source.id) || _isCompleted) return;

    if (source.id == target.id) {
      HapticFeedback.mediumImpact();
      setState(() {
        _matchedIds.add(source.id);
        _selectedSourceId = null;
        _wobbleId = null;
      });

      final itemName = _isUrdu ? source.titleUr : source.titleEn;
      final praise = _isUrdu ? 'شاباش! $itemName کا سایہ مل گیا!' : 'Matched! You found the shadow for $itemName!';
      TtsService.instance.speak(praise, langCode: _isUrdu ? 'ur' : 'en');

      if (_matchedIds.length >= _items.length) {
        _triggerCompletion();
      }
    } else {
      HapticFeedback.lightImpact();
      setState(() {
        _wobbleId = source.id;
      });

      final hint = _isUrdu ? 'یہ صحیح سایہ نہیں ہے، دوبارہ کوشش کریں!' : 'Not quite this shadow. Try another!';
      TtsService.instance.speak(hint, langCode: _isUrdu ? 'ur' : 'en');

      _wobbleTimer?.cancel();
      _wobbleTimer = Timer(const Duration(milliseconds: 700), () {
        if (mounted && _wobbleId == source.id) {
          setState(() => _wobbleId = null);
        }
      });
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
          'module_name': 'Shadow Match',
          'interaction_type': 'visual_puzzle',
          'completed_at': FieldValue.serverTimestamp(),
          'duration_seconds': math.max(1, duration),
          'round': _currentRound + 1,
        });
      }
    } catch (e) {
      debugPrint('ShadowMatchGame activity log error: $e');
    }

    final cheer = _isUrdu
        ? 'بہت شاندار! تمام سائے رنگین ہو گئے!'
        : 'All shadows matched and brought to life in vibrant color!';
    await TtsService.instance.speak(cheer, langCode: _isUrdu ? 'ur' : 'en');
  }

  void _onContinueRound() {
    if (_currentRound < _allRounds.length - 1) {
      setState(() {
        _currentRound++;
        _matchedIds.clear();
        _selectedSourceId = null;
        _wobbleId = null;
        _isCompleted = false;
      });
      final prompt = _isUrdu
          ? 'راؤنڈ ${_currentRound + 1}! نئے سائے تلاش کریں!'
          : 'Round ${_currentRound + 1}! Find the matching dark shadows!';
      TtsService.instance.speak(prompt, langCode: _isUrdu ? 'ur' : 'en');
    } else {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF5FF),
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
                    Color(0xFFF3E8FF),
                    Color(0xFFFAF5FF),
                    Color(0xFFE0E7FF),
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
                _buildScoreBadge(),
                const SizedBox(height: 16),

                // Main Matching Stage: Left = Colorful Items, Right = Mixed Shadow Targets
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Left Column: Items to Drag
                        _buildItemsColumn(),

                        // Center Connecting Divider
                        Container(
                          width: 2,
                          height: 280,
                          decoration: BoxDecoration(
                            color: const Color(0xFFA855F7).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),

                        // Right Column: Mixed Dark Shadow Targets
                        _buildShadowsColumn(),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),
              ],
            ),
          ),

          // Completion Celebration Overlay
          if (_isCompleted)
            CelebrationOverlay(
              moduleTitle: _isUrdu ? 'سائے ملانے کا مشن' : 'Shadow Match Puzzle',
              starsEarned: 50,
              onContinue: _onContinueRound,
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
            key: const Key('shadow_match_back_btn'),
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
                  color: const Color(0xFFA855F7).withOpacity(0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.contrast_rounded, color: Color(0xFFA855F7), size: 22),
                const SizedBox(width: 8),
                Text(
                  _isUrdu ? 'سائے ملائیں' : 'Shadow Match',
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
            icon: const Icon(Icons.volume_up_rounded, color: Color(0xFFA855F7)),
            onPressed: _speakInstruction,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8B4FE), width: 1.5),
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
          // Round indicator badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFA855F7).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _isUrdu ? 'راؤنڈ ${_currentRound + 1}/3' : 'Round ${_currentRound + 1}/3',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFFA855F7),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _isUrdu ? 'ملائے گئے سائے: ${_matchedIds.length}/3' : 'Shadows Matched: ${_matchedIds.length}/3',
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

  Widget _buildItemsColumn() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _items.map((item) {
        final isMatched = _matchedIds.contains(item.id);
        final isSelected = _selectedSourceId == item.id;
        final isWobbling = _wobbleId == item.id;

        if (isMatched) {
          return SizedBox(
            width: 86,
            height: 94,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.mintGreen.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppTheme.mintGreen,
                  size: 32,
                ),
              ),
            ),
          );
        }

        final card = _buildColorItemCard(item, isSelected);

        return Draggable<ShadowMatchItem>(
          key: Key('draggable_${item.id}'),
          data: item,
          feedback: Material(
            color: Colors.transparent,
            child: Transform.scale(scale: 1.15, child: card),
          ),
          childWhenDragging: Opacity(opacity: 0.25, child: card),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedSourceId = (_selectedSourceId == item.id) ? null : item.id;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.elasticOut,
              transform: Matrix4.translationValues(
                isWobbling ? (math.sin(DateTime.now().millisecondsSinceEpoch) * 10) : 0,
                0,
                0,
              ),
              child: card,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildShadowsColumn() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _shuffledShadows.map((item) {
        final isMatched = _matchedIds.contains(item.id);

        return DragTarget<ShadowMatchItem>(
          key: Key('shadow_target_${item.id}'),
          onWillAcceptWithDetails: (details) => !isMatched,
          onAcceptWithDetails: (details) => _onMatch(details.data, item),
          builder: (context, candidateData, rejectedData) {
            final isHovered = candidateData.isNotEmpty;

            return GestureDetector(
              onTap: () {
                if (_selectedSourceId != null && !isMatched) {
                  final source = _items.firstWhere((i) => i.id == _selectedSourceId);
                  _onMatch(source, item);
                }
              },
              child: AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: isHovered ? 1.08 : 1.0,
                child: _buildShadowSilhouetteCard(item, isMatched),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildColorItemCard(ShadowMatchItem item, bool isSelected) {
    return Container(
      width: 86,
      height: 94,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isSelected ? item.primaryColor : const Color(0xFFE9D5FF),
          width: isSelected ? 3.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: item.primaryColor.withOpacity(isSelected ? 0.35 : 0.12),
            blurRadius: isSelected ? 12 : 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: _buildItemCartoonGraphic(item.id, isShadow: false),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _isUrdu ? item.titleUr : item.titleEn,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: item.primaryColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildShadowSilhouetteCard(ShadowMatchItem item, bool isMatched) {
    if (isMatched) {
      // Bursts into full vibrant color upon match
      return Container(
        width: 86,
        height: 94,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: item.primaryColor.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: item.primaryColor, width: 2.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: _buildItemCartoonGraphic(item.id, isShadow: false, isMatched: true),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _isUrdu ? item.titleUr : item.titleEn,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: item.primaryColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    // Dark mysterious silhouette outline
    return Container(
      width: 86,
      height: 94,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B4B), // Midnight deep space
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFA855F7).withOpacity(0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA855F7).withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: _buildItemCartoonGraphic(item.id, isShadow: true),
      ),
    );
  }

  Widget _buildItemCartoonGraphic(String id, {required bool isShadow, bool isMatched = false}) {
    final shadowColor = const Color(0xFF0F172A);

    switch (id) {
      case 'cup':
        return _buildCartoonCup(isShadow: isShadow, shadowColor: shadowColor);
      case 'shoe':
        return _buildCartoonShoe(isShadow: isShadow, shadowColor: shadowColor);
      case 'banana':
        return _buildCartoonBanana(isShadow: isShadow, shadowColor: shadowColor);
      case 'car':
        return _buildCartoonCar(isShadow: isShadow, shadowColor: shadowColor);
      case 'star':
        return _buildCartoonStar(isShadow: isShadow, shadowColor: shadowColor);
      case 'butterfly':
        return _buildCartoonButterfly(isShadow: isShadow, shadowColor: shadowColor);
      case 'airplane':
        return _buildCartoonAirplane(isShadow: isShadow, shadowColor: shadowColor);
      case 'apple':
        return _buildCartoonApple(isShadow: isShadow, shadowColor: shadowColor);
      case 'teddy':
        return _buildCartoonTeddy(isShadow: isShadow, shadowColor: shadowColor);
      default:
        return Icon(
          Icons.help_outline,
          color: isShadow ? shadowColor : Colors.purple,
          size: 36,
        );
    }
  }

  // --- Cartoon Illustrators ---

  Widget _buildCartoonCup({required bool isShadow, required Color shadowColor}) {
    if (isShadow) {
      return SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Mug Body & Handle Silhouette
            Positioned(
              top: 14,
              child: Container(
                width: 32,
                height: 28,
                decoration: BoxDecoration(
                  color: shadowColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 2,
              top: 18,
              child: Container(
                width: 14,
                height: 18,
                decoration: BoxDecoration(
                  border: Border.all(color: shadowColor, width: 4),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            // Rising Steam Silhouette
            Positioned(
              top: 2,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 3, height: 8, color: shadowColor),
                  const SizedBox(width: 4),
                  Container(width: 3, height: 10, color: shadowColor),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ceramic Red Mug Body
          Positioned(
            top: 14,
            child: Container(
              width: 32,
              height: 28,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF87171), Color(0xFFEF4444)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: const Center(
                child: Icon(Icons.favorite_rounded, color: Colors.white, size: 12),
              ),
            ),
          ),
          // Mug Handle
          Positioned(
            right: 2,
            top: 18,
            child: Container(
              width: 14,
              height: 18,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFEF4444), width: 3.5),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          // Rising Steam
          Positioned(
            top: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.waves_rounded, color: Colors.orange.withOpacity(0.7), size: 10),
                const SizedBox(width: 2),
                Icon(Icons.waves_rounded, color: Colors.orange.withOpacity(0.7), size: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartoonShoe({required bool isShadow, required Color shadowColor}) {
    if (isShadow) {
      return SizedBox(
        width: 52,
        height: 38,
        child: Stack(
          children: [
            // Sneaker Body Silhouette
            Positioned(
              left: 6,
              top: 4,
              child: Container(
                width: 34,
                height: 22,
                decoration: BoxDecoration(
                  color: shadowColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(8),
                  ),
                ),
              ),
            ),
            // Sneaker Toe & Sole
            Positioned(
              bottom: 2,
              left: 2,
              right: 2,
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  color: shadowColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: 52,
      height: 38,
      child: Stack(
        children: [
          // Blue Sneaker Body
          Positioned(
            left: 8,
            top: 4,
            child: Container(
              width: 32,
              height: 20,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 6,
                  height: 14,
                  margin: const EdgeInsets.only(left: 4),
                  color: const Color(0xFFFEF08A), // Shoelaces
                ),
              ),
            ),
          ),
          // White Rubber Sole & Toe Cap
          Positioned(
            bottom: 2,
            left: 2,
            right: 2,
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(5)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartoonBanana({required bool isShadow, required Color shadowColor}) {
    if (isShadow) {
      return SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: Transform.rotate(
            angle: -0.4,
            child: Container(
              width: 40,
              height: 22,
              decoration: BoxDecoration(
                color: shadowColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomRight: Radius.circular(22),
                  bottomLeft: Radius.circular(10),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: 48,
      height: 48,
      child: Center(
        child: Transform.rotate(
          angle: -0.4,
          child: Container(
            width: 40,
            height: 22,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.2, -0.4),
                colors: [Color(0xFFFEF08A), Color(0xFFEAB308), Color(0xFFCA8A04)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomRight: Radius.circular(22),
                bottomLeft: Radius.circular(10),
              ),
            ),
            child: Stack(
              children: [
                // Brown Stem Tip
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF78350F),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // Glossy Streak
                Positioned(
                  left: 8,
                  top: 4,
                  child: Container(
                    width: 20,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCartoonCar({required bool isShadow, required Color shadowColor}) {
    if (isShadow) {
      return Icon(Icons.directions_car_rounded, color: shadowColor, size: 40);
    }
    return const Icon(Icons.directions_car_rounded, color: Color(0xFF10B981), size: 40);
  }

  Widget _buildCartoonStar({required bool isShadow, required Color shadowColor}) {
    if (isShadow) {
      return Icon(Icons.star_rounded, color: shadowColor, size: 42);
    }
    return const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 42);
  }

  Widget _buildCartoonButterfly({required bool isShadow, required Color shadowColor}) {
    if (isShadow) {
      return Icon(Icons.flutter_dash_rounded, color: shadowColor, size: 40);
    }
    return const Icon(Icons.flutter_dash_rounded, color: Color(0xFF8B5CF6), size: 40);
  }

  Widget _buildCartoonAirplane({required bool isShadow, required Color shadowColor}) {
    if (isShadow) {
      return Icon(Icons.airplanemode_active_rounded, color: shadowColor, size: 40);
    }
    return const Icon(Icons.airplanemode_active_rounded, color: Color(0xFF0284C7), size: 40);
  }

  Widget _buildCartoonApple({required bool isShadow, required Color shadowColor}) {
    if (isShadow) {
      return Icon(Icons.apple_rounded, color: shadowColor, size: 40);
    }
    return const Icon(Icons.apple_rounded, color: Color(0xFFDC2626), size: 40);
  }

  Widget _buildCartoonTeddy({required bool isShadow, required Color shadowColor}) {
    if (isShadow) {
      return Icon(Icons.pets_rounded, color: shadowColor, size: 38);
    }
    return const Icon(Icons.pets_rounded, color: Color(0xFFD97706), size: 38);
  }
}
