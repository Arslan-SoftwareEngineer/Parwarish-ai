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

  group('Activities of Daily Living (ADL) Interactive Games Suite Tests', () {
    testWidgets('WashHandsGame renders sink, handles 4-stage progression, and celebrates',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));

      await tester.pumpWidget(
        const MaterialApp(
          home: WashHandsGame(childId: 'child_test_01', isUrdu: false),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Initial Header & Soap Stage
      expect(find.text('Wash Hands'), findsOneWidget);
      expect(find.byKey(const Key('soap_dispenser')), findsOneWidget);
      expect(find.byKey(const Key('faucet_handle')), findsOneWidget);
      expect(find.text('0/2'), findsOneWidget);

      // Stage 1: Tap dispenser twice
      await tester.tap(find.byKey(const Key('soap_dispenser')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('1/2'), findsOneWidget);

      await tester.tap(find.byKey(const Key('soap_dispenser')));
      await tester.pump(const Duration(milliseconds: 800));

      // Verify transitioned to Scrub Stage
      expect(find.text('Rub hands together to make foam'), findsOneWidget);

      // Scrub hands with drag gestures
      final handsFinder = find.byKey(const Key('hands_interactive_area'));
      expect(handsFinder, findsOneWidget);

      for (int i = 0; i < 8; i++) {
        await tester.drag(handsFinder, const Offset(60, 40));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.drag(handsFinder, const Offset(-60, -40));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(milliseconds: 600));

      // Verify transitioned to Rinse Stage
      expect(find.text('Turn tap on and rinse bubbles'), findsOneWidget);

      // Turn on tap
      await tester.tap(find.byKey(const Key('faucet_handle')));
      await tester.pump(const Duration(milliseconds: 200));

      // Drag hands under water stream
      for (int i = 0; i < 8; i++) {
        await tester.drag(handsFinder, const Offset(50, 50));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(milliseconds: 600));

      // Verify transitioned to Dry Stage
      expect(find.text('Wipe with soft towel to dry'), findsOneWidget);
      final towelFinder = find.byKey(const Key('towel_drag_target'));
      expect(towelFinder, findsOneWidget);

      // Drag towel across hands to complete drying
      for (int i = 0; i < 8; i++) {
        await tester.drag(towelFinder, const Offset(50, 0), warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.drag(towelFinder, const Offset(-50, 0), warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(milliseconds: 500));

      // Verify Completion & Celebration Overlay
      expect(find.byType(CelebrationOverlay), findsOneWidget);
      expect(find.text('Wash Hands Routine'), findsOneWidget);
    });

    testWidgets('PackBagGame drag-drop checklist items and soft distractor bounce',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));

      await tester.pumpWidget(
        const MaterialApp(
          home: PackBagGame(childId: 'child_test_01', isUrdu: false),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Pack Backpack'), findsOneWidget);
      expect(find.byKey(const Key('backpack_drag_target')), findsOneWidget);

      // Verify desk items render
      expect(find.byKey(const Key('draggable_notebook')), findsOneWidget);
      expect(find.byKey(const Key('draggable_pencil_box')), findsOneWidget);
      expect(find.byKey(const Key('draggable_water_bottle')), findsOneWidget);
      expect(find.byKey(const Key('draggable_toy_dino')), findsOneWidget);
      expect(find.byKey(const Key('draggable_lunchbox')), findsOneWidget);

      final bagTarget = find.byKey(const Key('backpack_drag_target'));

      // Test 1: Drag non-checklist item (Toy Dino) - soft bounce back without error
      final dinoFinder = find.byKey(const Key('draggable_toy_dino'));
      await tester.drag(dinoFinder, tester.getCenter(bagTarget) - tester.getCenter(dinoFinder));
      await tester.pump(const Duration(milliseconds: 500));

      // Dino should still be on desk (not packed)
      expect(find.byKey(const Key('draggable_toy_dino')), findsOneWidget);
      expect(find.text('0/3'), findsOneWidget);

      // Test 2: Pack required checklist item 1 (Notebook)
      final notebookFinder = find.byKey(const Key('draggable_notebook'));
      await tester.drag(notebookFinder, tester.getCenter(bagTarget) - tester.getCenter(notebookFinder));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('1/3'), findsOneWidget);

      // Test 3: Pack required checklist item 2 (Pencil Box)
      final pencilFinder = find.byKey(const Key('draggable_pencil_box'));
      await tester.drag(pencilFinder, tester.getCenter(bagTarget) - tester.getCenter(pencilFinder));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('2/3'), findsOneWidget);

      // Test 4: Pack required checklist item 3 (Water Bottle)
      final bottleFinder = find.byKey(const Key('draggable_water_bottle'));
      await tester.drag(bottleFinder, tester.getCenter(bagTarget) - tester.getCenter(bottleFinder));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 1500));

      // Verify bag zips shut & celebration overlay triggers
      expect(find.byType(CelebrationOverlay), findsOneWidget);
      expect(find.text('Pack Bag Routine'), findsOneWidget);
    });

    testWidgets('BrushTeethGame scrubs 6 teeth quadrants clean and celebrates',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));

      await tester.pumpWidget(
        const MaterialApp(
          home: BrushTeethGame(childId: 'child_test_01', isUrdu: false),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Brush Teeth'), findsOneWidget);
      expect(find.text('Clean Teeth: 0/6'), findsOneWidget);

      final mouthFinder = find.byKey(const Key('mouth_interactive_pan'));
      expect(mouthFinder, findsOneWidget);

      // 1. Test pan drag across mouth area
      await tester.drag(mouthFinder, const Offset(-50, -40));
      await tester.pump(const Duration(milliseconds: 100));

      // 2. Scrub all 6 teeth quadrants to clean them
      for (int t = 0; t < 6; t++) {
        final toothFinder = find.byKey(Key('tooth_$t'));
        expect(toothFinder, findsOneWidget);
        for (int p = 0; p < 3; p++) {
          await tester.tap(toothFinder);
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 1200));

      // Verify celebration overlay
      expect(find.byType(CelebrationOverlay), findsOneWidget);
      expect(find.text('Brush Teeth Routine'), findsOneWidget);
      expect(find.text('Clean Teeth: 6/6'), findsOneWidget);
    });

    test('GamesRegistry exposes all 3 ADL games and supports ID lookups', () {
      final adlGames = GamesRegistry.allGames.where((g) => g.category == 'adl').toList();
      expect(adlGames.length, equals(3));

      final washHands = GamesRegistry.getGameById('wash_hands');
      expect(washHands, isNotNull);
      expect(washHands!.titleEn, contains('Wash Hands'));
      expect(washHands.category, equals('adl'));

      final packBag = GamesRegistry.getGameById('pack_bag');
      expect(packBag, isNotNull);
      expect(packBag!.titleEn, contains('Pack Backpack'));

      final brushTeeth = GamesRegistry.getGameById('brush_teeth');
      expect(brushTeeth, isNotNull);
      expect(brushTeeth!.titleEn, contains('Brush Teeth'));

      final invalidGame = GamesRegistry.getGameById('unknown_game');
      expect(invalidGame, isNull);
    });
  });
}
