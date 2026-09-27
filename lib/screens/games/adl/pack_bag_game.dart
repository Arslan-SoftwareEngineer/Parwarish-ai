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

class DeskItem {
  final String id;
  final String titleEn;
  final String titleUr;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isRequired;

  const DeskItem({
    required this.id,
    required this.titleEn,
    required this.titleUr,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    required this.isRequired,
  });
}

class PackBagGame extends StatefulWidget {
  final String? childId;
  final bool? isUrdu;

  const PackBagGame({
    super.key,
    this.childId,
    this.isUrdu,
  });

  @override
  State<PackBagGame> createState() => _PackBagGameState();
}

class _PackBagGameState extends State<PackBagGame> with SingleTickerProviderStateMixin {
  late String _activeChildId;
  late bool _isUrdu;
  DateTime _startTime = DateTime.now();

  // 3 required items, 2 non-checklist playful items
  final List<DeskItem> _allItems = const [
    DeskItem(
      id: 'notebook',
      titleEn: 'Notebook',
      titleUr: 'کاپی',
      icon: Icons.menu_book_rounded,
      primaryColor: Color(0xFF3B82F6),
      secondaryColor: Color(0xFF60A5FA),
      isRequired: true,
    ),
    DeskItem(
      id: 'pencil_box',
      titleEn: 'Pencil Box',
      titleUr: 'پنسل باکس',
      icon: Icons.edit_note_rounded,
      primaryColor: Color(0xFFF59E0B),
      secondaryColor: Color(0xFFFCD34D),
      isRequired: true,
    ),
    DeskItem(
      id: 'water_bottle',
      titleEn: 'Water Bottle',
      titleUr: 'پانی کی بوتل',
      icon: Icons.local_drink_rounded,
      primaryColor: Color(0xFF06B6D4),
      secondaryColor: Color(0xFF67E8F9),
      isRequired: true,
    ),
    DeskItem(
      id: 'toy_dino',
      titleEn: 'Toy Dino',
      titleUr: 'کھلونا ڈائناسور',
      icon: Icons.cruelty_free_rounded,
      primaryColor: Color(0xFF10B981),
      secondaryColor: Color(0xFF6EE7B7),
      isRequired: false,
    ),
    DeskItem(
      id: 'lunchbox',
      titleEn: 'Lunchbox',
      titleUr: 'لنچ باکس',
      icon: Icons.lunch_dining_rounded,
      primaryColor: Color(0xFFEC4899),
      secondaryColor: Color(0xFFF472B6),
      isRequired: false,
    ),
  ];

  final Set<String> _packedItemIds = {};
  String? _recentlyBouncedItemId;
  bool _isBagZipped = false;
  bool _isCompleted = false;

  Timer? _bounceTimer;
  late AnimationController _zipperController;

  @override
  void initState() {
    super.initState();
    _activeChildId = widget.childId ?? 'child_demo_01';
    _isUrdu = widget.isUrdu ?? LocalizationService.instance.isUrdu;
    _startTime = DateTime.now();

    _zipperController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

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
    _zipperController.dispose();
    super.dispose();
  }

  Future<void> _speakInstruction() async {
    final text = _isUrdu
        ? 'سکول بیگ میں کاپی، پنسل باکس اور بوتل پیک کریں'
        : 'Drag the Notebook, Pencil Box, and Water Bottle into the backpack!';
    await TtsService.instance.speak(text, langCode: _isUrdu ? 'ur' : 'en');
  }

  void _onItemDropped(DeskItem item) {
    if (item.isRequired) {
      HapticFeedback.mediumImpact();
      setState(() {
        _packedItemIds.add(item.id);
        _recentlyBouncedItemId = null;
      });

      final itemName = _isUrdu ? item.titleUr : item.titleEn;
      final speech = _isUrdu ? '$itemName بیگ میں آ گیا!' : 'Good job! $itemName is packed!';
      TtsService.instance.speak(speech, langCode: _isUrdu ? 'ur' : 'en');

      // Check if all 3 required items packed
      if (_packedItemIds.length >= 3) {
        _triggerBagZipAndCompletion();
      }
    } else {
      // Non-checklist item gently bounces back with zero error sound
      HapticFeedback.lightImpact();
      setState(() {
        _recentlyBouncedItemId = item.id;
      });

      final gentleMessage = _isUrdu
          ? '${item.titleUr} میز پر رہنے دیں، بعد میں کھیلیں گے!'
          : 'Leave the ${item.titleEn} on the desk for playtime later!';
      TtsService.instance.speak(gentleMessage, langCode: _isUrdu ? 'ur' : 'en');

      _bounceTimer?.cancel();
      _bounceTimer = Timer(const Duration(milliseconds: 1000), () {
        if (mounted && _recentlyBouncedItemId == item.id) {
          setState(() => _recentlyBouncedItemId = null);
        }
      });
    }
  }

  Future<void> _triggerBagZipAndCompletion() async {
    _bounceTimer?.cancel();
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    setState(() {
      _isBagZipped = true;
    });
    _zipperController.forward();

    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() {
      _isCompleted = true;
    });

    final duration = DateTime.now().difference(_startTime).inSeconds;

    // Log to Firestore activity_logs
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('children')
            .doc(_activeChildId)
            .collection('activity_logs')
            .add({
          'module_name': 'Pack Bag Routine',
          'interaction_type': 'touch_game',
          'completed_at': FieldValue.serverTimestamp(),
          'duration_seconds': math.max(1, duration),
        });
      }
    } catch (e) {
      debugPrint('PackBagGame activity log error: $e');
    }

    final praise = _isUrdu
        ? 'شاباش! سکول بیگ بالکل تیار ہے!'
        : 'All set! Your backpack is packed and ready for school!';
    await TtsService.instance.speak(praise, langCode: _isUrdu ? 'ur' : 'en');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBEB),
      body: Stack(
        children: [
          // Background Gradient Room Ambience
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
                _buildTargetChecklistBanner(),
                const SizedBox(height: 10),

                // Main Isometric Study Desk & Center Backpack
                Expanded(
                  child: Center(
                    child: _buildIsometricDeskScene(),
                  ),
                ),

                // Bottom Desk Items Shelf (Draggables)
                _buildDeskItemsTray(),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Completion Overlay
          if (_isCompleted)
            CelebrationOverlay(
              moduleTitle: _isUrdu ? 'سکول بیگ پیکنگ مشن' : 'Pack Bag Routine',
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
            key: const Key('pack_bag_back_btn'),
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
                const Icon(Icons.backpack_rounded, color: Color(0xFFD97706), size: 22),
                const SizedBox(width: 8),
                Text(
                  _isUrdu ? 'بیگ پیک کرنا' : 'Pack Backpack',
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
              color: Color(0xFFD97706),
            ),
            onPressed: _speakInstruction,
          ),
        ],
      ),
    );
  }

  Widget _buildTargetChecklistBanner() {
    final requiredItems = _allItems.where((i) => i.isRequired).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFCD34D), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: requiredItems.map((item) {
          final isPacked = _packedItemIds.contains(item.id);
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isPacked ? const Color(0xFFF0FDF4) : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isPacked ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPacked ? AppTheme.mintGreen : const Color(0xFFF59E0B),
                    ),
                    child: Icon(
                      isPacked ? Icons.check_rounded : item.icon,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _isUrdu ? item.titleUr : item.titleEn,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isPacked ? FontWeight.bold : FontWeight.w700,
                        color: isPacked ? const Color(0xFF166534) : const Color(0xFF92400E),
                        decoration: isPacked ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildIsometricDeskScene() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deskWidth = math.min(constraints.maxWidth * 0.92, 380.0);
        final deskHeight = 360.0;

        return Container(
          width: deskWidth,
          height: deskHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFDE68A),
                Color(0xFFFBBF24),
                Color(0xFFD97706),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB45309).withOpacity(0.35),
                blurRadius: 24,
                offset: const Offset(0, 16),
              ),
            ],
            border: Border.all(color: const Color(0xFFFFFBEB), width: 3),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Isometric Wooden Desk Grain Lines
              Positioned.fill(
                child: CustomPaint(
                  painter: _DeskWoodGrainPainter(),
                ),
              ),

              // Open School Backpack (DragTarget in Center)
              _buildBackpackDragTarget(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackpackDragTarget() {
    return DragTarget<DeskItem>(
      key: const Key('backpack_drag_target'),
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) => _onItemDropped(details.data),
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return AnimatedScale(
          duration: const Duration(milliseconds: 250),
          scale: isHovered ? 1.08 : 1.0,
          curve: Curves.easeOutBack,
          child: Container(
            width: 200,
            height: 240,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(36),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _isBagZipped
                    ? [const Color(0xFF1E40AF), const Color(0xFF1D4ED8), const Color(0xFF1E3A8A)]
                    : (isHovered
                        ? [const Color(0xFF2563EB), const Color(0xFF1D4ED8)]
                        : [const Color(0xFF3B82F6), const Color(0xFF1E40AF)]),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: isHovered ? const Color(0xFF93C5FD) : Colors.white.withOpacity(0.6),
                width: isHovered ? 3.5 : 2.5,
              ),
            ),
            child: Stack(
              children: [
                // Bag Front Pocket
                Positioned(
                  bottom: 16,
                  left: 20,
                  right: 20,
                  child: Container(
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D4ED8).withOpacity(0.7),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        _isBagZipped ? 'PARWARISH' : '${_packedItemIds.length}/3',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),

                // Main Interior Compartment
                Positioned(
                  top: 20,
                  left: 20,
                  right: 20,
                  child: _isBagZipped
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 24),
                              const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 36),
                              const SizedBox(height: 6),
                              Text(
                                _isUrdu ? 'بیگ بند ہو گیا' : 'Zipped & Ready!',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ).animate().scale(curve: Curves.elasticOut, duration: 600.ms),
                        )
                      : Column(
                          children: [
                            Text(
                              _isUrdu ? 'یہاں سامان رکھیں' : 'Drop Here',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Silhouettes of packed / remaining items
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              children: _allItems.where((i) => i.isRequired).map((item) {
                                final isPacked = _packedItemIds.contains(item.id);
                                return Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isPacked
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: isPacked
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.15),
                                              blurRadius: 6,
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: Icon(
                                    item.icon,
                                    color: isPacked ? item.primaryColor : Colors.white.withOpacity(0.5),
                                    size: 24,
                                  ),
                                ).animate(target: isPacked ? 1 : 0).scale(
                                      curve: Curves.easeOutBack,
                                      duration: 400.ms,
                                    );
                              }).toList(),
                            ),
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

  int _focusedItemIndex = 0;

  Widget _buildDeskItemsTray() {
    final unpackedItems = _allItems.where((i) => !_packedItemIds.contains(i.id)).toList();
    if (unpackedItems.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Center(
          child: Text(
            _isUrdu ? '🎉 تمام اشیاء پیک ہو گئیں!' : '🎉 All items are packed!',
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.mintGreen, fontSize: 16),
          ),
        ),
      );
    }

    final safeIndex = _focusedItemIndex.clamp(0, unpackedItems.length - 1);
    final focusedItem = unpackedItems[safeIndex];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header showing focus step
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
                onPressed: () {
                  setState(() {
                    _focusedItemIndex = (_focusedItemIndex - 1 + unpackedItems.length) % unpackedItems.length;
                  });
                },
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isUrdu ? 'اگلی چیز پیک کریں (1 بائے 1)' : 'Focus: Drag this item into bag',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
                  ),
                  Text(
                    _isUrdu ? focusedItem.titleUr : focusedItem.titleEn,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                onPressed: () {
                  setState(() {
                    _focusedItemIndex = (_focusedItemIndex + 1) % unpackedItems.length;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Shelf area with focused prominent item and testable draggables
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _allItems.map((item) {
              final isPacked = _packedItemIds.contains(item.id);
              final isFocused = item.id == focusedItem.id;
              final isBounced = _recentlyBouncedItemId == item.id;

              if (isPacked) {
                return SizedBox(
                  width: 50,
                  height: 65,
                  child: Center(
                    child: Icon(Icons.check_circle_rounded, color: AppTheme.mintGreen.withOpacity(0.4), size: 26),
                  ),
                );
              }

              final widgetCard = _buildRealisticCartoonItem(item, isFocused: isFocused);

              return Draggable<DeskItem>(
                key: Key('draggable_${item.id}'),
                data: item,
                feedback: Material(
                  color: Colors.transparent,
                  child: Transform.scale(
                    scale: 1.2,
                    child: _buildRealisticCartoonItem(item, isFocused: true),
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.25,
                  child: widgetCard,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.elasticOut,
                  transform: Matrix4.translationValues(0, isBounced ? -14 : 0, 0),
                  child: InkWell(
                    onTap: () {
                      final idx = unpackedItems.indexWhere((i) => i.id == item.id);
                      if (idx != -1) setState(() => _focusedItemIndex = idx);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: isFocused
                            ? Border.all(color: const Color(0xFFF59E0B), width: 2)
                            : null,
                      ),
                      child: widgetCard,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Builds realistic, recognizable cartoon objects instead of simple square tiles (Req 7)
  Widget _buildRealisticCartoonItem(DeskItem item, {required bool isFocused}) {
    final double scale = isFocused ? 1.05 : 0.9;

    Widget illustration;
    switch (item.id) {
      case 'pencil_box':
        // Real cartoon pencil with eraser, ferrule, and sharp lead
        illustration = Container(
          width: 52,
          height: 62,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pink rubber eraser
              Container(
                width: 14,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFF472B6),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ),
              // Silver metallic ferrule band
              Container(
                width: 15,
                height: 5,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFCBD5E1), Color(0xFF94A3B8), Color(0xFFE2E8F0)],
                  ),
                  border: Border.all(color: const Color(0xFF64748B), width: 0.5),
                ),
              ),
              // Yellow wooden hexagonal shaft
              Container(
                width: 14,
                height: 30,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                ),
              ),
              // Sharpened cone wood
              CustomPaint(
                size: const Size(14, 10),
                painter: _PencilTipPainter(),
              ),
            ],
          ),
        );
        break;

      case 'notebook':
        // Real cartoon school notebook with spiral binding and cover star
        illustration = Container(
          width: 50,
          height: 62,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1D4ED8).withOpacity(0.35),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Spiral coil binding on left
              Container(
                width: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF1E40AF),
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(6)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (i) {
                    return Container(
                      width: 8,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white70,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
              ),
              // Notebook cover with center star emblem
              Expanded(
                child: Center(
                  child: Icon(Icons.star_rounded, color: const Color(0xFFFDE047), size: isFocused ? 24 : 20),
                ),
              ),
            ],
          ),
        );
        break;

      case 'water_bottle':
        // Real cartoon sports bottle with water level and flip lid
        illustration = Container(
          width: 48,
          height: 62,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Dark blue flip cap with spout
              Container(
                width: 18,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF0369A1),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ),
              // Translucent cyan bottle body with water fill
              Container(
                width: 32,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFBAE6FD), Color(0xFF38BDF8), Color(0xFF0284C7)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF0284C7), width: 1.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 14, height: 2, color: Colors.white70),
                    const SizedBox(height: 4),
                    Container(width: 18, height: 2, color: Colors.white70),
                  ],
                ),
              ),
            ],
          ),
        );
        break;

      case 'toy_dino':
        // Real cartoon green dinosaur
        illustration = Container(
          width: 50,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFF10B981),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: const Color(0xFF059669).withOpacity(0.35), blurRadius: 6),
            ],
          ),
          child: const Center(
            child: Icon(Icons.cruelty_free_rounded, color: Colors.white, size: 30),
          ),
        );
        break;

      case 'lunchbox':
      default:
        // Real cartoon bento lunchbox
        illustration = Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF472B6), Color(0xFFEC4899)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(color: const Color(0xFFEC4899).withOpacity(0.35), blurRadius: 6),
            ],
          ),
          child: const Center(
            child: Icon(Icons.lunch_dining_rounded, color: Colors.white, size: 28),
          ),
        );
        break;
    }

    return Transform.scale(
      scale: scale,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          illustration,
          const SizedBox(height: 3),
          Text(
            _isUrdu ? item.titleUr : item.titleEn,
            style: TextStyle(
              fontSize: isFocused ? 11 : 10,
              fontWeight: isFocused ? FontWeight.w900 : FontWeight.w700,
              color: isFocused ? AppTheme.textPrimary : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PencilTipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final woodPaint = Paint()
      ..color = const Color(0xFFFDE68A)
      ..style = PaintingStyle.fill;

    final leadPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.fill;

    // Wood cone
    final woodPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(woodPath, woodPaint);

    // Dark graphite tip
    final leadPath = Path()
      ..moveTo(size.width * 0.35, size.height * 0.6)
      ..lineTo(size.width * 0.65, size.height * 0.6)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(leadPath, leadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DeskWoodGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB45309).withOpacity(0.1)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (double i = 20; i < size.height; i += 40) {
      final path = Path();
      path.moveTo(0, i);
      path.quadraticBezierTo(size.width * 0.5, i + 15, size.width, i - 5);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
