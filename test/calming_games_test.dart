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

  group('Sensory Calming & Fine Motor Assembly Games Suite Tests', () {
    testWidgets('PopBubblesGame renders floating bubbles, canvas pops, and completes session',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));

      await tester.pumpWidget(
        const MaterialApp(
          home: PopBubblesGame(childId: 'child_test_01', isUrdu: false),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Verify header & counter
      expect(find.text('Pop Bubbles'), findsOneWidget);
      expect(find.text('Bubbles Popped: 0'), findsOneWidget);

      // Verify canvas and done button
      final canvasFinder = find.byKey(const Key('bubbles_touch_canvas'));
      expect(canvasFinder, findsOneWidget);
      final doneBtnFinder = find.byKey(const Key('pop_bubbles_done_btn'));
      expect(doneBtnFinder, findsOneWidget);

      // Tap on the canvas to pop bubbles
      await tester.tapAt(const Offset(300, 400));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tapAt(const Offset(400, 500));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Done button
      await tester.tap(doneBtnFinder);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 600));

      // Celebration overlay appears
      expect(find.byType(CelebrationOverlay), findsOneWidget);
      expect(find.text('Bubble Pop Calm'), findsOneWidget);
    });

    testWidgets('BreathingFlowerGame renders breathing loop, ripple canvas, and peaceful exit',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));

      await tester.pumpWidget(
        const MaterialApp(
          home: BreathingFlowerGame(childId: 'child_test_01', isUrdu: false),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Verify header & breath counter
      expect(find.text('Breathing Flower'), findsOneWidget);
      expect(find.text('Calm Breaths: 0'), findsOneWidget);

      // Verify breathing surface
      final surfaceFinder = find.byKey(const Key('breathing_touch_surface'));
      expect(surfaceFinder, findsOneWidget);

      // Verify initial prompt (Inhale phase)
      expect(find.text('Breathe In Slowly'), findsOneWidget);

      // Tap to create ripple wave
      await tester.tapAt(const Offset(400, 450));
      await tester.pump(const Duration(milliseconds: 200));

      // Verify peaceful exit button
      final doneBtnFinder = find.byKey(const Key('breathing_done_btn'));
      expect(doneBtnFinder, findsOneWidget);

      await tester.tap(doneBtnFinder);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 600));

      // Celebration overlay appears
      expect(find.byType(CelebrationOverlay), findsOneWidget);
      expect(find.text('Breathing Flower Meditation'), findsOneWidget);
    });

    testWidgets('BuildVehicleGame snaps 3 pieces into blueprint, illuminates, drives off and celebrates',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));

      await tester.pumpWidget(
        const MaterialApp(
          home: BuildVehicleGame(childId: 'child_test_01', isUrdu: false),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Verify header & progress
      expect(find.text('Build Vehicle'), findsOneWidget);
      expect(find.text('Parts Assembled: 0/3'), findsOneWidget);

      // Verify blueprint target and piece draggables
      expect(find.byKey(const Key('blueprint_drag_target')), findsOneWidget);
      expect(find.byKey(const Key('draggable_part_chassis')), findsOneWidget);
      expect(find.byKey(const Key('draggable_part_cabin')), findsOneWidget);
      expect(find.byKey(const Key('draggable_part_wheels')), findsOneWidget);

      // Test tap-to-snap accessibility: snap chassis
      await tester.tap(find.byKey(const Key('draggable_part_chassis')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Parts Assembled: 1/3'), findsOneWidget);

      // Test drag-and-drop: drag cabin to blueprint
      final cabinFinder = find.byKey(const Key('draggable_part_cabin'));
      final blueprintFinder = find.byKey(const Key('blueprint_drag_target'));
      await tester.drag(cabinFinder, tester.getCenter(blueprintFinder) - tester.getCenter(cabinFinder));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Parts Assembled: 2/3'), findsOneWidget);

      // Snap final piece (wheels) via tap-to-snap
      await tester.tap(find.byKey(const Key('draggable_part_wheels')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Parts Assembled: 3/3'), findsOneWidget);

      // Advance past drive-off animation & completion delay
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pump(const Duration(milliseconds: 1500));

      // Celebration overlay appears
      expect(find.byType(CelebrationOverlay), findsOneWidget);
      expect(find.text('Vehicle Assembly Mission'), findsOneWidget);
    });

    testWidgets('ShadowMatchGame matches 3 items via drag & tap pairing, bursts, and celebrates',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));

      await tester.pumpWidget(
        const MaterialApp(
          home: ShadowMatchGame(childId: 'child_test_01', isUrdu: false),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Verify header & progress
      expect(find.text('Shadow Match'), findsOneWidget);
      expect(find.text('Shadows Matched: 0/3'), findsOneWidget);

      // Verify color items and shadow silhouettes exist
      expect(find.byKey(const Key('draggable_cup')), findsOneWidget);
      expect(find.byKey(const Key('draggable_shoe')), findsOneWidget);
      expect(find.byKey(const Key('draggable_banana')), findsOneWidget);

      expect(find.byKey(const Key('shadow_target_cup')), findsOneWidget);
      expect(find.byKey(const Key('shadow_target_shoe')), findsOneWidget);
      expect(find.byKey(const Key('shadow_target_banana')), findsOneWidget);

      // Match 1: Drag Cup to Cup Shadow
      final cupFinder = find.byKey(const Key('draggable_cup'));
      final cupShadowFinder = find.byKey(const Key('shadow_target_cup'));
      await tester.drag(cupFinder, tester.getCenter(cupShadowFinder) - tester.getCenter(cupFinder));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Shadows Matched: 1/3'), findsOneWidget);

      // Match 2: Tap-to-pair Shoe (tap shoe, then tap shoe shadow)
      await tester.tap(find.byKey(const Key('draggable_shoe')));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const Key('shadow_target_shoe')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Shadows Matched: 2/3'), findsOneWidget);

      // Match 3: Drag Banana to Banana Shadow
      final bananaFinder = find.byKey(const Key('draggable_banana'));
      final bananaShadowFinder = find.byKey(const Key('shadow_target_banana'));
      await tester.drag(bananaFinder, tester.getCenter(bananaShadowFinder) - tester.getCenter(bananaFinder));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Shadows Matched: 3/3'), findsOneWidget);

      // Advance through celebratory burst and overlay
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 1200));

      // Celebration overlay appears
      expect(find.byType(CelebrationOverlay), findsOneWidget);
      expect(find.text('Shadow Match Puzzle'), findsOneWidget);
    });

    testWidgets('GamesRegistry registers all 11 games across ADL, Sorting, and Calming suites',
        (WidgetTester tester) async {
      expect(GamesRegistry.allGames.length, 11);

      // Check all IDs exist
      final ids = GamesRegistry.allGames.map((g) => g.id).toList();
      expect(ids, containsAll([
        'wash_hands',
        'pack_bag',
        'brush_teeth',
        'toy_chest_cleanup',
        'laundry_sort',
        'shape_tower',
        'fruit_merge',
        'pop_bubbles',
        'breathing_flower',
        'build_vehicle',
        'shadow_match',
      ]));

      // Verify category counts
      final adlGames = GamesRegistry.allGames.where((g) => g.category == 'adl').toList();
      final sortingGames = GamesRegistry.allGames.where((g) => g.category == 'sorting').toList();
      final calmingGames = GamesRegistry.allGames.where((g) => g.category == 'calming').toList();

      expect(adlGames.length, 3);
      expect(sortingGames.length, 4);
      expect(calmingGames.length, 4);

      // Verify getGameById helper works
      for (final id in ids) {
        final game = GamesRegistry.getGameById(id);
        expect(game, isNotNull);
        expect(game!.id, id);
      }
    });
  });
}
