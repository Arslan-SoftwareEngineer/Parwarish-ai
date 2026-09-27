import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parwarish_ai/screens/games/games_registry.dart';
import 'package:parwarish_ai/widgets/celebration_overlay.dart';
import 'package:parwarish_ai/services/localization_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'active_child_id': 'child_test_01',
    });
    await LocalizationService.instance.init();
  });

  group('Organization, Sorting & Merging Games Suite Tests', () {
    testWidgets('ToyChestCleanupGame sorts 6 items into 3 zones and celebrates',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));

      await tester.pumpWidget(
        const MaterialApp(
          home: ToyChestCleanupGame(childId: 'child_test_01', isUrdu: false),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Clean Up Room'), findsOneWidget);
      expect(find.text('Items Put Away: 0/6'), findsOneWidget);

      // Verify 3 Storage Zones exist
      final toyZone = find.byKey(const Key('storage_zone_toys'));
      final bookZone = find.byKey(const Key('storage_zone_books'));
      final clothesZone = find.byKey(const Key('storage_zone_clothes'));

      expect(toyZone, findsOneWidget);
      expect(bookZone, findsOneWidget);
      expect(clothesZone, findsOneWidget);

      // Verify all 6 items render on the floor
      expect(find.byKey(const Key('draggable_teddy_1')), findsOneWidget);
      expect(find.byKey(const Key('draggable_teddy_2')), findsOneWidget);
      expect(find.byKey(const Key('draggable_book_1')), findsOneWidget);
      expect(find.byKey(const Key('draggable_book_2')), findsOneWidget);
      expect(find.byKey(const Key('draggable_shirt_1')), findsOneWidget);
      expect(find.byKey(const Key('draggable_shirt_2')), findsOneWidget);

      // Test 1: Drop a toy (teddy_1) into clothes zone (invalid destination)
      final teddy1Finder = find.byKey(const Key('draggable_teddy_1'));
      await tester.drag(teddy1Finder, tester.getCenter(clothesZone) - tester.getCenter(teddy1Finder));
      await tester.pump(const Duration(milliseconds: 300));
      // Still 0/6 put away
      expect(find.text('Items Put Away: 0/6'), findsOneWidget);

      // Test 2: Sort teddy_1 into toys zone
      await tester.drag(teddy1Finder, tester.getCenter(toyZone) - tester.getCenter(teddy1Finder));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Items Put Away: 1/6'), findsOneWidget);

      // Test 3: Sort teddy_2 into toys zone
      final teddy2Finder = find.byKey(const Key('draggable_teddy_2'));
      await tester.drag(teddy2Finder, tester.getCenter(toyZone) - tester.getCenter(teddy2Finder));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Items Put Away: 2/6'), findsOneWidget);

      // Test 4: Sort book_1 into books zone
      final book1Finder = find.byKey(const Key('draggable_book_1'));
      await tester.drag(book1Finder, tester.getCenter(bookZone) - tester.getCenter(book1Finder));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Items Put Away: 3/6'), findsOneWidget);

      // Test 5: Sort book_2 into books zone
      final book2Finder = find.byKey(const Key('draggable_book_2'));
      await tester.drag(book2Finder, tester.getCenter(bookZone) - tester.getCenter(book2Finder));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Items Put Away: 4/6'), findsOneWidget);

      // Test 6: Sort shirt_1 into clothes zone
      final shirt1Finder = find.byKey(const Key('draggable_shirt_1'));
      await tester.drag(shirt1Finder, tester.getCenter(clothesZone) - tester.getCenter(shirt1Finder));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Items Put Away: 5/6'), findsOneWidget);

      // Test 7: Sort shirt_2 into clothes zone
      final shirt2Finder = find.byKey(const Key('draggable_shirt_2'));
      await tester.drag(shirt2Finder, tester.getCenter(clothesZone) - tester.getCenter(shirt2Finder));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 1200));

      // Verify completion
      expect(find.byType(CelebrationOverlay), findsOneWidget);
      expect(find.text('Toy Chest Cleanup'), findsOneWidget);
    });

    testWidgets('LaundrySortGame sorts clothes queue to blue and green baskets',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));

      await tester.pumpWidget(
        const MaterialApp(
          home: LaundrySortGame(childId: 'child_test_01', isUrdu: false),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Laundry Sort'), findsOneWidget);
      expect(find.text('Sorted: 0/6'), findsOneWidget);
      expect(find.byKey(const Key('basket_shirts_left')), findsOneWidget);
      expect(find.byKey(const Key('basket_socks_right')), findsOneWidget);

      // Queue:
      // 0: Blue Shirt (shirt)
      // 1: Orange Socks (sock)
      // 2: Pink Shirt (shirt)
      // 3: Teal Socks (sock)
      // 4: Yellow Shirt (shirt)
      // 5: Purple Socks (sock)

      // Test invalid sort: try to send Blue Shirt to Socks basket (right)
      await tester.tap(find.byKey(const Key('btn_swipe_sock')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Sorted: 0/6'), findsOneWidget);

      // 1. Blue Shirt -> Shirt
      await tester.tap(find.byKey(const Key('btn_swipe_shirt')));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Sorted: 1/6'), findsOneWidget);

      // 2. Orange Socks -> Sock
      await tester.tap(find.byKey(const Key('btn_swipe_sock')));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Sorted: 2/6'), findsOneWidget);

      // 3. Pink Shirt -> Shirt (via basket tap)
      await tester.tap(find.byKey(const Key('basket_shirts_left')));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Sorted: 3/6'), findsOneWidget);

      // 4. Teal Socks -> Sock (via basket tap)
      await tester.tap(find.byKey(const Key('basket_socks_right')));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Sorted: 4/6'), findsOneWidget);

      // 5. Yellow Shirt -> Shirt (via conveyor drag)
      final conveyorItem = find.byKey(const Key('active_conveyor_item'));
      await tester.drag(conveyorItem, const Offset(-60, 0));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Sorted: 5/6'), findsOneWidget);

      // 6. Purple Socks -> Sock
      await tester.tap(find.byKey(const Key('btn_swipe_sock')));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 1200));

      // Verify completion
      expect(find.byType(CelebrationOverlay), findsOneWidget);
      expect(find.text('Laundry Sort Routine'), findsOneWidget);
    });

    testWidgets('ShapeTowerGame enforces seriation order (Large->Med->Small)',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));

      await tester.pumpWidget(
        const MaterialApp(
          home: ShapeTowerGame(childId: 'child_test_01', isUrdu: false),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Shape Tower'), findsOneWidget);
      expect(find.byKey(const Key('wooden_peg_target')), findsOneWidget);

      // Verify 3 rings in tray
      final largeRing = find.byKey(const Key('draggable_ring_large'));
      final mediumRing = find.byKey(const Key('draggable_ring_medium'));
      final smallRing = find.byKey(const Key('draggable_ring_small'));

      expect(largeRing, findsOneWidget);
      expect(mediumRing, findsOneWidget);
      expect(smallRing, findsOneWidget);

      final pegTarget = find.byKey(const Key('wooden_peg_target'));

      // Test 1: Try placing Small Ring first (invalid order)
      await tester.tap(smallRing);
      await tester.pump(const Duration(milliseconds: 300));
      // Ring should still be in tray (not placed)
      expect(find.byKey(const Key('draggable_ring_small')), findsOneWidget);

      // Test 2: Try placing Medium Ring first (invalid order)
      await tester.drag(mediumRing, tester.getCenter(pegTarget) - tester.getCenter(mediumRing));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('draggable_ring_medium')), findsOneWidget);

      // Test 3: Place Large Ring (valid)
      await tester.drag(largeRing, tester.getCenter(pegTarget) - tester.getCenter(largeRing));
      await tester.pump(const Duration(milliseconds: 400));

      // Large ring should now be stacked
      expect(find.textContaining('(1/3)'), findsOneWidget);

      // Test 4: Place Medium Ring (valid)
      final remainingMedium = find.byKey(const Key('draggable_ring_medium'));
      await tester.tap(remainingMedium);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('(2/3)'), findsOneWidget);

      // Test 5: Place Small Ring (valid)
      final remainingSmall = find.byKey(const Key('draggable_ring_small'));
      await tester.tap(remainingSmall);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 1200));

      // Verify completion
      expect(find.byType(CelebrationOverlay), findsOneWidget);
      expect(find.text('Shape Tower Puzzle'), findsOneWidget);
    });

    testWidgets('FruitMergeGame merges Strawberries into Oranges and Oranges into Apple',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));

      await tester.pumpWidget(
        const MaterialApp(
          home: FruitMergeGame(childId: 'child_test_01', isUrdu: false),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Fruit Merge'), findsOneWidget);

      // Initial: 4 in tray + 1 in legend = 5
      expect(find.text('Strawberry'), findsNWidgets(5));

      // Merge Pair 1: Slot 0 (Strawberry) + Slot 1 (Strawberry) -> Orange
      await tester.tap(find.byKey(const Key('draggable_fruit_1')));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byKey(const Key('draggable_fruit_2')));
      await tester.pump(const Duration(milliseconds: 400));

      // Now 1 in tray + 1 in legend = 2 Oranges
      expect(find.text('Orange'), findsNWidgets(2));
      // 2 in tray + 1 in legend = 3 Strawberries
      expect(find.text('Strawberry'), findsNWidgets(3));

      // Merge Pair 2: Slot 2 (Strawberry) + Slot 3 (Strawberry) -> Orange
      await tester.tap(find.byKey(const Key('draggable_fruit_3')));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byKey(const Key('draggable_fruit_4')));
      await tester.pump(const Duration(milliseconds: 400));

      // Now 2 in tray + 1 in legend = 3 Oranges
      expect(find.text('Orange'), findsNWidgets(3));
      // 0 in tray + 1 in legend = 1 Strawberry
      expect(find.text('Strawberry'), findsOneWidget);

      // Final Merge: Orange (slot 1) + Orange (slot 3) -> Apple!
      await tester.tap(find.byKey(const Key('draggable_fruit_2')));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byKey(const Key('draggable_fruit_4')));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 1200));

      // 1 in tray + 1 in legend = 2 Apples
      expect(find.text('Apple'), findsNWidgets(2));
      expect(find.byType(CelebrationOverlay), findsOneWidget);
      expect(find.text('Fruit Merge Puzzle'), findsOneWidget);
    });

    test('GamesRegistry exposes all games including ADL and Sorting suites', () {
      expect(GamesRegistry.allGames.length, greaterThanOrEqualTo(7));

      // ADL Games
      expect(GamesRegistry.getGameById('wash_hands'), isNotNull);
      expect(GamesRegistry.getGameById('pack_bag'), isNotNull);
      expect(GamesRegistry.getGameById('brush_teeth'), isNotNull);

      // Sorting Games
      final toyChest = GamesRegistry.getGameById('toy_chest_cleanup');
      expect(toyChest, isNotNull);
      expect(toyChest!.titleEn, contains('Toy Chest'));
      expect(toyChest.category, equals('sorting'));

      final laundry = GamesRegistry.getGameById('laundry_sort');
      expect(laundry, isNotNull);
      expect(laundry!.titleEn, contains('Laundry'));
      expect(laundry.category, equals('sorting'));

      final shapeTower = GamesRegistry.getGameById('shape_tower');
      expect(shapeTower, isNotNull);
      expect(shapeTower!.titleEn, contains('Shape Tower'));
      expect(shapeTower.category, equals('sorting'));

      final fruitMerge = GamesRegistry.getGameById('fruit_merge');
      expect(fruitMerge, isNotNull);
      expect(fruitMerge!.titleEn, contains('Fruit Merge'));
      expect(fruitMerge.category, equals('sorting'));
    });
  });
}
