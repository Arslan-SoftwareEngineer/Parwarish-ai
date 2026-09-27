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

enum CleanupCategory { toys, books, clothes }

class CleanupItem {
  final String id;
  final String titleEn;
  final String titleUr;
  final CleanupCategory category;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;

  const CleanupItem({
    required this.id,
    required this.titleEn,
    required this.titleUr,
    required this.category,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
  });
}

class StorageZone {
  final CleanupCategory category;
  final String titleEn;
  final String titleUr;
  final IconData icon;
  final Color baseColor;
  final Color accentColor;

  const StorageZone({
    required this.category,
    required this.titleEn,
    required this.titleUr,
    required this.icon,
    required this.baseColor,
    required this.accentColor,
  });
}

class ToyChestCleanupGame extends StatefulWidget {
  final String? childId;
  final bool? isUrdu;

  const ToyChestCleanupGame({
    super.key,
    this.childId,
    this.isUrdu,
  });

  @override
  State<ToyChestCleanupGame> createState() => _ToyChestCleanupGameState();
}

class _ToyChestCleanupGameState extends State<ToyChestCleanupGame> {
  late String _activeChildId;
  late bool _isUrdu;
  DateTime _startTime = DateTime.now();

  final List<StorageZone> _zones = const [
    StorageZone(
      category: CleanupCategory.toys,
      titleEn: 'Toy Chest',
      titleUr: 'کھلونوں کا باکس',
      icon: Icons.inventory_2_rounded,
      baseColor: Color(0xFFF59E0B),
      accentColor: Color(0xFFFCD34D),
    ),
    StorageZone(
      category: CleanupCategory.books,
      titleEn: 'Bookshelf',
      titleUr: 'کتابوں کا شیلف',
      icon: Icons.auto_stories_rounded,
      baseColor: Color(0xFF3B82F6),
      accentColor: Color(0xFF93C5FD),
    ),
    StorageZone(
      category: CleanupCategory.clothes,
      titleEn: 'Laundry Basket',
      titleUr: 'کپڑوں کی ٹوکری',
      icon: Icons.shopping_basket_rounded,
      baseColor: Color(0xFF8B5CF6),
      accentColor: Color(0xFFC4B5FD),
    ),
  ];

  final List<CleanupItem> _allItems = const [
    CleanupItem(
      id: 'teddy_1',
      titleEn: 'Brown Bear',
      titleUr: 'بھورا بھالو',
      category: CleanupCategory.toys,
      icon: Icons.cruelty_free_rounded,
      primaryColor: Color(0xFFB45309),
      secondaryColor: Color(0xFFD97706),
    ),
    CleanupItem(
      id: 'teddy_2',
      titleEn: 'Fluffy Bear',
      titleUr: 'نرم بھالو',
      category: CleanupCategory.toys,
      icon: Icons.smart_toy_rounded,
      primaryColor: Color(0xFFEA580C),
      secondaryColor: Color(0xFFF97316),
    ),
    CleanupItem(
      id: 'book_1',
      titleEn: 'Storybook',
      titleUr: 'کہانی کی کتاب',
      category: CleanupCategory.books,
      icon: Icons.menu_book_rounded,
      primaryColor: Color(0xFF2563EB),
      secondaryColor: Color(0xFF60A5FA),
    ),
    CleanupItem(
      id: 'book_2',
      titleEn: 'Picture Book',
      titleUr: 'تصویر والی کتاب',
      category: CleanupCategory.books,
      icon: Icons.import_contacts_rounded,
      primaryColor: Color(0xFF0284C7),
      secondaryColor: Color(0xFF38BDF8),
    ),
    CleanupItem(
      id: 'shirt_1',
      titleEn: 'T-Shirt',
      titleUr: 'ٹی شرٹ',
      category: CleanupCategory.clothes,
      icon: Icons.checkroom_rounded,
      primaryColor: Color(0xFF7C3AED),
      secondaryColor: Color(0xFFA78BFA),
    ),
    CleanupItem(
      id: 'shirt_2',
      titleEn: 'Polo Shirt',
      titleUr: 'کالر والی شرٹ',
      category: CleanupCategory.clothes,
      icon: Icons.dry_cleaning_rounded,
      primaryColor: Color(0xFF6D28D9),
      secondaryColor: Color(0xFF8B5CF6),
    ),
  ];

  final Set<String> _sortedItemIds = {};
  String? _recentlyBouncedItemId;
  CleanupCategory? _hoveredZoneCategory;
  bool _isCompleted = false;

  Timer? _bounceTimer;

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
    _bounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _speakInstruction() async {
    final text = _isUrdu
        ? 'کھلونے باکس میں، کتابیں شیلف پر اور کپڑے ٹوکری میں رکھیں!'
        : 'Sort toys into the chest, books onto the shelf, and clothes into the basket!';
    await TtsService.instance.speak(text, langCode: _isUrdu ? 'ur' : 'en');
  }

  void _onItemDropped(CleanupItem item, CleanupCategory destinationCategory) {
    if (item.category == destinationCategory) {
      HapticFeedback.mediumImpact();
      setState(() {
        _sortedItemIds.add(item.id);
        _recentlyBouncedItemId = null;
        _hoveredZoneCategory = null;
      });

      final itemName = _isUrdu ? item.titleUr : item.titleEn;
      final praise = _isUrdu ? 'شاباش! $itemName بالکل صحیح جگہ پر ہے!' : 'Great job! $itemName is put away!';
      TtsService.instance.speak(praise, langCode: _isUrdu ? 'ur' : 'en');

      if (_sortedItemIds.length >= _allItems.length) {
        _triggerCompletion();
      }
    } else {
      // Gentle bounce back without jarring error sound
      HapticFeedback.lightImpact();
      setState(() {
        _recentlyBouncedItemId = item.id;
        _hoveredZoneCategory = null;
      });

      final hint = _isUrdu
          ? '${item.titleUr} یہاں نہیں آتا، صحیح جگہ ڈھونڈیں!'
          : 'That goes in a different spot. Try again!';
      TtsService.instance.speak(hint, langCode: _isUrdu ? 'ur' : 'en');

      _bounceTimer?.cancel();
      _bounceTimer = Timer(const Duration(milliseconds: 900), () {
        if (mounted && _recentlyBouncedItemId == item.id) {
          setState(() => _recentlyBouncedItemId = null);
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
          'module_name': 'Toy Chest Cleanup',
          'interaction_type': 'sorting_game',
          'completed_at': FieldValue.serverTimestamp(),
          'duration_seconds': math.max(1, duration),
        });
      }
    } catch (e) {
      debugPrint('ToyChestCleanupGame activity log error: $e');
    }

    final cheer = _isUrdu
        ? 'بہت خوب! کمرہ بالکل صاف اور منظم ہو گیا ہے!'
        : 'Fantastic! The room is completely clean and organized!';
    await TtsService.instance.speak(cheer, langCode: _isUrdu ? 'ur' : 'en');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      body: Stack(
        children: [
          // Gentle Pastel Bedroom Floor Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFEF9C3),
                    Color(0xFFFDFBF7),
                    Color(0xFFF3E8FF),
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
                _buildProgressCounter(),
                const SizedBox(height: 12),

                // Top 3 Storage Zones (DragTargets)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _zones.map((zone) => _buildStorageZoneWidget(zone)).toList(),
                  ),
                ),

                const Spacer(),

                // Bottom Scattered Floor Items Area (Draggables)
                _buildFloorItemsTray(),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Celebration Overlay
          if (_isCompleted)
            CelebrationOverlay(
              moduleTitle: _isUrdu ? 'کمرے کی صفائی مشن' : 'Toy Chest Cleanup',
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
            key: const Key('toy_cleanup_back_btn'),
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
                  color: const Color(0xFFF59E0B).withOpacity(0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cleaning_services_rounded, color: Color(0xFFD97706), size: 22),
                const SizedBox(width: 8),
                Text(
                  _isUrdu ? 'کمرے کی صفائی' : 'Clean Up Room',
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

  Widget _buildProgressCounter() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars_rounded, color: Color(0xFFF59E0B), size: 22),
          const SizedBox(width: 8),
          Text(
            _isUrdu ? 'صاف شدہ اشیاء: ${_sortedItemIds.length}/6' : 'Items Put Away: ${_sortedItemIds.length}/6',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageZoneWidget(StorageZone zone) {
    return DragTarget<CleanupItem>(
      key: Key('storage_zone_${zone.category.name}'),
      onWillAcceptWithDetails: (details) {
        setState(() => _hoveredZoneCategory = zone.category);
        return true;
      },
      onLeave: (data) {
        setState(() {
          if (_hoveredZoneCategory == zone.category) {
            _hoveredZoneCategory = null;
          }
        });
      },
      onAcceptWithDetails: (details) => _onItemDropped(details.data, zone.category),
      builder: (context, candidateData, rejectedData) {
        final isHovered = _hoveredZoneCategory == zone.category;
        final sortedInThisZone = _allItems
            .where((item) => item.category == zone.category && _sortedItemIds.contains(item.id))
            .length;

        Widget containerGraphic;
        switch (zone.category) {
          case CleanupCategory.toys:
            // Realistic 3D cartoon Wooden Toy Chest with open lid (Req 11)
            containerGraphic = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Open Wooden Lid
                Transform(
                  alignment: Alignment.bottomCenter,
                  transform: Matrix4.rotationX(-0.35),
                  child: Container(
                    width: 90,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD97706), Color(0xFFB45309)],
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
                    ),
                    child: Center(
                      child: Container(
                        width: 16,
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
                // Wooden Chest Box Body with brass slats
                Container(
                  width: 96,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFF59E0B), Color(0xFFB45309), Color(0xFF78350F)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFDE68A), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Planks lines
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Divider(color: Colors.black.withOpacity(0.2), height: 1, thickness: 1.5),
                          Divider(color: Colors.black.withOpacity(0.2), height: 1, thickness: 1.5),
                        ],
                      ),
                      // Golden Clasp / Lock
                      Container(
                        width: 18,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDE047),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: const Color(0xFFCA8A04), width: 1),
                        ),
                        child: const Icon(Icons.lock_rounded, size: 12, color: Color(0xFF854D0E)),
                      ),
                    ],
                  ),
                ),
              ],
            );
            break;

          case CleanupCategory.books:
            // Realistic 3D cartoon Wooden Bookshelf (Req 11)
            containerGraphic = Container(
              width: 96,
              height: 104,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF60A5FA), Color(0xFF2563EB), Color(0xFF1D4ED8)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBFDBFE), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1D4ED8).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Top shelf with mini books
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(width: 10, height: 32, color: const Color(0xFFEF4444)),
                        Container(width: 12, height: 38, color: const Color(0xFFFBBF24)),
                        Container(width: 9, height: 30, color: const Color(0xFF10B981)),
                        Container(width: 11, height: 35, color: const Color(0xFFEC4899)),
                      ],
                    ),
                  ),
                  // Middle Wooden Shelf Divider
                  Container(height: 5, color: const Color(0xFF1E3A8A)),
                  // Lower Shelf bay ready for books
                  Expanded(
                    child: Center(
                      child: Icon(Icons.auto_stories_rounded, color: Colors.white.withOpacity(0.7), size: 24),
                    ),
                  ),
                ],
              ),
            );
            break;

          case CleanupCategory.clothes:
            // Realistic 3D cartoon Wicker Laundry Basket (Req 11)
            containerGraphic = Container(
              width: 96,
              height: 104,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFA78BFA), Color(0xFF7C3AED), Color(0xFF5B21B6)],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                  bottom: Radius.circular(26),
                ),
                border: Border.all(color: const Color(0xFFDDD6FE), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5B21B6).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // White linen folded cloth draped over rim
                  Positioned(
                    top: 0,
                    left: 10,
                    right: 10,
                    height: 18,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  // Wicker woven crosshatch lines
                  Center(
                    child: Icon(
                      Icons.grid_view_rounded,
                      color: Colors.white.withOpacity(0.25),
                      size: 42,
                    ),
                  ),
                  // Clothes emblem
                  const Center(
                    child: Icon(Icons.checkroom_rounded, color: Colors.white, size: 28),
                  ),
                ],
              ),
            );
            break;
        }

        return AnimatedScale(
          duration: const Duration(milliseconds: 200),
          scale: isHovered ? 1.08 : 1.0,
          curve: Curves.easeOutBack,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              containerGraphic,
              const SizedBox(height: 6),
              Text(
                _isUrdu ? zone.titleUr : zone.titleEn,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: zone.baseColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$sortedInThisZone/2',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: zone.baseColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloorItemsTray() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: const Color(0xFFF3E8FF), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _isUrdu ? 'کھلونے باکس میں، کتابیں شیلف پر اور کپڑے ٹوکری میں ڈالیں' : 'Drag items into their 3D containers!',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _allItems.map((item) {
              final isSorted = _sortedItemIds.contains(item.id);
              final isBounced = _recentlyBouncedItemId == item.id;

              if (isSorted) {
                return SizedBox(
                  width: 68,
                  height: 68,
                  child: Center(
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: AppTheme.mintGreen.withOpacity(0.4),
                      size: 32,
                    ),
                  ),
                );
              }

              final card = _buildDraggableCard(item);

              return Draggable<CleanupItem>(
                key: Key('draggable_${item.id}'),
                data: item,
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
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.elasticOut,
                  transform: Matrix4.translationValues(0, isBounced ? -12 : 0, 0),
                  child: card,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Builds realistic recognizable cartoon items instead of flat tiles (Req 11)
  Widget _buildDraggableCard(CleanupItem item) {
    Widget cartoonGraphic;

    switch (item.category) {
      case CleanupCategory.toys:
        // Realistic cartoon fluffy Teddy Bear
        final isFluffy = item.id == 'teddy_2';
        final bearColor = isFluffy ? const Color(0xFFEA580C) : const Color(0xFFB45309);
        final snoutColor = isFluffy ? const Color(0xFFFDBA74) : const Color(0xFFFDE68A);

        cartoonGraphic = SizedBox(
          width: 58,
          height: 58,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Teddy Ears
              Positioned(
                top: 2,
                left: 6,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(color: bearColor, shape: BoxShape.circle),
                ),
              ),
              Positioned(
                top: 2,
                right: 6,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(color: bearColor, shape: BoxShape.circle),
                ),
              ),
              // Teddy Head
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bearColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: bearColor.withOpacity(0.35), blurRadius: 6),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Eyes
                    const Positioned(
                      top: 14,
                      left: 12,
                      child: CircleAvatar(radius: 2.5, backgroundColor: Colors.black87),
                    ),
                    const Positioned(
                      top: 14,
                      right: 12,
                      child: CircleAvatar(radius: 2.5, backgroundColor: Colors.black87),
                    ),
                    // Cute Snout & Nose
                    Positioned(
                      bottom: 8,
                      child: Container(
                        width: 20,
                        height: 14,
                        decoration: BoxDecoration(
                          color: snoutColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: CircleAvatar(radius: 2, backgroundColor: Colors.brown),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
        break;

      case CleanupCategory.books:
        // Realistic cartoon Storybook with spine and cover
        final bookColor = item.id == 'book_1' ? const Color(0xFF2563EB) : const Color(0xFF0284C7);

        cartoonGraphic = Container(
          width: 52,
          height: 60,
          decoration: BoxDecoration(
            color: bookColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(color: bookColor.withOpacity(0.35), blurRadius: 6, offset: const Offset(0, 3)),
            ],
          ),
          child: Row(
            children: [
              // Book spine
              Container(
                width: 8,
                decoration: BoxDecoration(
                  color: bookColor.withOpacity(0.7),
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                ),
              ),
              // Cover design
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.id == 'book_1' ? Icons.menu_book_rounded : Icons.auto_stories_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                    const SizedBox(height: 2),
                    Container(width: 22, height: 2, color: Colors.white70),
                  ],
                ),
              ),
            ],
          ),
        );
        break;

      case CleanupCategory.clothes:
        // Realistic cartoon folded T-Shirt
        final shirtColor = item.id == 'shirt_1' ? const Color(0xFF7C3AED) : const Color(0xFF9333EA);

        cartoonGraphic = Container(
          width: 54,
          height: 56,
          decoration: BoxDecoration(
            color: shirtColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: shirtColor.withOpacity(0.35), blurRadius: 6, offset: const Offset(0, 3)),
            ],
          ),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              // Collar cut
              Positioned(
                top: 0,
                child: Container(
                  width: 18,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
                  ),
                ),
              ),
              // Folded sleeves lines & center emblem
              Center(
                child: Icon(Icons.checkroom_rounded, color: Colors.white.withOpacity(0.85), size: 28),
              ),
            ],
          ),
        );
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        cartoonGraphic,
        const SizedBox(height: 3),
        Text(
          _isUrdu ? item.titleUr : item.titleEn,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
