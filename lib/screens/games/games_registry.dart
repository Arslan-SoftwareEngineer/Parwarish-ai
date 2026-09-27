import 'package:flutter/material.dart';
import 'adl/wash_hands_game.dart';
import 'adl/pack_bag_game.dart';
import 'adl/brush_teeth_game.dart';
import 'sorting/toy_chest_cleanup_game.dart';
import 'sorting/laundry_sort_game.dart';
import 'sorting/shape_tower_game.dart';
import 'sorting/fruit_merge_game.dart';
import 'calming/pop_bubbles_game.dart';
import 'calming/breathing_flower_game.dart';
import 'calming/build_vehicle_game.dart';
import 'calming/shadow_match_game.dart';

export 'adl/wash_hands_game.dart';
export 'adl/pack_bag_game.dart';
export 'adl/brush_teeth_game.dart';
export 'sorting/toy_chest_cleanup_game.dart';
export 'sorting/laundry_sort_game.dart';
export 'sorting/shape_tower_game.dart';
export 'sorting/fruit_merge_game.dart';
export 'calming/pop_bubbles_game.dart';
export 'calming/breathing_flower_game.dart';
export 'calming/build_vehicle_game.dart';
export 'calming/shadow_match_game.dart';

class GameMetadata {
  final String id;
  final String titleEn;
  final String titleUr;
  final String descriptionEn;
  final String descriptionUr;
  final IconData icon;
  final Color themeColor;
  final String category; // 'adl', 'sorting', 'calming'
  final Widget Function(BuildContext context, {String? childId, bool? isUrdu}) builder;

  const GameMetadata({
    required this.id,
    required this.titleEn,
    required this.titleUr,
    required this.descriptionEn,
    required this.descriptionUr,
    required this.icon,
    required this.themeColor,
    required this.category,
    required this.builder,
  });
}

class GamesRegistry {
  GamesRegistry._();

  static final List<GameMetadata> allGames = [
    // ADL Games
    GameMetadata(
      id: 'wash_hands',
      titleEn: 'Wash Hands Routine',
      titleUr: 'ہاتھ دھونے کی روٹین',
      descriptionEn: 'Soap, scrub, rinse and dry hands in a 2.5D interactive sink!',
      descriptionUr: 'صابن لگائیں، رگڑیں اور تولیہ سے خشک کریں!',
      icon: Icons.clean_hands_rounded,
      themeColor: const Color(0xFF3B82F6),
      category: 'adl',
      builder: (context, {childId, isUrdu}) => WashHandsGame(
        childId: childId,
        isUrdu: isUrdu,
      ),
    ),
    GameMetadata(
      id: 'pack_bag',
      titleEn: 'Pack Backpack Routine',
      titleUr: 'سکول بیگ پیک کرنا',
      descriptionEn: 'Sort essential school supplies and zip up your backpack!',
      descriptionUr: 'سکول کا سامان درست طریقے سے بیگ میں پیک کریں!',
      icon: Icons.backpack_rounded,
      themeColor: const Color(0xFFF59E0B),
      category: 'adl',
      builder: (context, {childId, isUrdu}) => PackBagGame(
        childId: childId,
        isUrdu: isUrdu,
      ),
    ),
    GameMetadata(
      id: 'brush_teeth',
      titleEn: 'Brush Teeth Routine',
      titleUr: 'دانت صاف کرنا',
      descriptionEn: 'Scrub teeth quadrants clean until every tooth sparkles bright!',
      descriptionUr: 'ٹوتھ برش سے دانتوں کو موتیوں کی طرح چمکائیں!',
      icon: Icons.sentiment_very_satisfied_rounded,
      themeColor: const Color(0xFF10B981),
      category: 'adl',
      builder: (context, {childId, isUrdu}) => BrushTeethGame(
        childId: childId,
        isUrdu: isUrdu,
      ),
    ),

    // Organization & Sorting Games
    GameMetadata(
      id: 'toy_chest_cleanup',
      titleEn: 'Toy Chest Cleanup',
      titleUr: 'کمرے کی صفائی',
      descriptionEn: 'Sort toys, books, and clothes into their proper storage bins!',
      descriptionUr: 'کھلونے، کتابیں اور کپڑے ان کی صحیح جگہوں پر رکھیں!',
      icon: Icons.cleaning_services_rounded,
      themeColor: const Color(0xFFF59E0B),
      category: 'sorting',
      builder: (context, {childId, isUrdu}) => ToyChestCleanupGame(
        childId: childId,
        isUrdu: isUrdu,
      ),
    ),
    GameMetadata(
      id: 'laundry_sort',
      titleEn: 'Laundry Sort',
      titleUr: 'کپڑے چھانٹنا',
      descriptionEn: 'Swipe shirts to the blue basket and socks to the green basket!',
      descriptionUr: 'شرٹس نیلے باکس میں اور جرابیں سبز باکس میں ڈالیں!',
      icon: Icons.local_laundry_service_rounded,
      themeColor: const Color(0xFF0284C7),
      category: 'sorting',
      builder: (context, {childId, isUrdu}) => LaundrySortGame(
        childId: childId,
        isUrdu: isUrdu,
      ),
    ),
    GameMetadata(
      id: 'shape_tower',
      titleEn: 'Shape Tower',
      titleUr: 'شکلوں کا ٹاور',
      descriptionEn: 'Stack colorful rings onto the peg from largest to smallest!',
      descriptionUr: 'چھلوں کو بڑے سے چھوٹے کی ترتیب میں کھمبے پر سجائیں!',
      icon: Icons.layers_rounded,
      themeColor: const Color(0xFF8B5CF6),
      category: 'sorting',
      builder: (context, {childId, isUrdu}) => ShapeTowerGame(
        childId: childId,
        isUrdu: isUrdu,
      ),
    ),
    GameMetadata(
      id: 'fruit_merge',
      titleEn: 'Fruit Merge',
      titleUr: 'پھلوں کا ملاپ',
      descriptionEn: 'Drag identical fruits together to merge them into bigger fruit!',
      descriptionUr: 'ایک جیسے پھل ملا کر نیا مزیدار پھل بنائیں!',
      icon: Icons.auto_fix_high_rounded,
      themeColor: const Color(0xFFEA580C),
      category: 'sorting',
      builder: (context, {childId, isUrdu}) => FruitMergeGame(
        childId: childId,
        isUrdu: isUrdu,
      ),
    ),

    // Sensory Calming & Fine Motor Assembly Games
    GameMetadata(
      id: 'pop_bubbles',
      titleEn: 'Pop Bubbles',
      titleUr: 'پاپ بلبلے',
      descriptionEn: 'Pop floating ocean bubbles with gentle musical chimes!',
      descriptionUr: 'خوبصورت بلبلے پھوڑیں اور سریلی آوازیں سنیں!',
      icon: Icons.bubble_chart_rounded,
      themeColor: const Color(0xFF06B6D4),
      category: 'calming',
      builder: (context, {childId, isUrdu}) => PopBubblesGame(
        childId: childId,
        isUrdu: isUrdu,
      ),
    ),
    GameMetadata(
      id: 'breathing_flower',
      titleEn: 'Breathing Flower',
      titleUr: 'کھلتا پھول',
      descriptionEn: 'Follow the blooming lotus flower to breathe calmly and deeply!',
      descriptionUr: 'پھول کے ساتھ لمبی اور پرسکون سانس لیں اور چھوڑیں!',
      icon: Icons.spa_rounded,
      themeColor: const Color(0xFF10B981),
      category: 'calming',
      builder: (context, {childId, isUrdu}) => BreathingFlowerGame(
        childId: childId,
        isUrdu: isUrdu,
      ),
    ),
    GameMetadata(
      id: 'build_vehicle',
      titleEn: 'Build a Vehicle',
      titleUr: 'گاڑی بنائیں',
      descriptionEn: 'Assemble vehicle parts on the blueprint and drive away!',
      descriptionUr: 'گاڑی کے حصے جوڑیں اور گاڑی چلائیں!',
      icon: Icons.directions_car_rounded,
      themeColor: const Color(0xFF3B82F6),
      category: 'calming',
      builder: (context, {childId, isUrdu}) => BuildVehicleGame(
        childId: childId,
        isUrdu: isUrdu,
      ),
    ),
    GameMetadata(
      id: 'shadow_match',
      titleEn: 'Shadow Match',
      titleUr: 'سائے کی پہچان',
      descriptionEn: 'Match everyday objects with their mysterious shadow silhouettes!',
      descriptionUr: 'چیزوں کو ان کے اصل سائے کے ساتھ ملائیں!',
      icon: Icons.auto_awesome_rounded,
      themeColor: const Color(0xFF8B5CF6),
      category: 'calming',
      builder: (context, {childId, isUrdu}) => ShadowMatchGame(
        childId: childId,
        isUrdu: isUrdu,
      ),
    ),
  ];

  static GameMetadata? getGameById(String gameId) {
    try {
      return allGames.firstWhere((game) => game.id == gameId);
    } catch (_) {
      return null;
    }
  }

  static Future<bool?> openGame(
    BuildContext context,
    String gameId, {
    String? childId,
    bool? isUrdu,
  }) async {
    final game = getGameById(gameId);
    if (game == null) return false;

    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (ctx) => game.builder(ctx, childId: childId, isUrdu: isUrdu),
      ),
    );
  }
}
