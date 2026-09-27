import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parwarish_ai/screens/child/child_dashboard.dart';
import 'package:parwarish_ai/screens/child/lesson_screen.dart';
import 'package:parwarish_ai/services/localization_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'child_id': 'child_demo_01',
      'child_name': 'Aayan',
      'autism_level': 'Moderate',
      'user_role': 'child',
    });
    await LocalizationService.instance.init();
  });

  group('Task 5: Child Dashboard, Adaptive Modules & Sensor Lessons Tests', () {
    testWidgets('ChildDashboard renders child name, streak badge, language toggle, and tabs', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChildDashboard(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Header checks
      expect(find.text("Aayan's Space"), findsOneWidget);
      expect(find.text('Streak: 4'), findsOneWidget);
      expect(find.byKey(const Key('lang_toggle_chip')), findsOneWidget);

      // Learn Tab default checks (Moderate track)
      expect(find.text('Wash Hands'), findsOneWidget);
      expect(find.text('Dress Up'), findsOneWidget);
      expect(find.text('Eating Routine'), findsOneWidget);

      // Bottom Navigation items
      expect(find.text('Learn'), findsOneWidget);
      expect(find.text('Schedule'), findsOneWidget);
      expect(find.text('Badges'), findsOneWidget);
    });

    testWidgets('ChildDashboard language toggle toggles ENG / اردو', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChildDashboard(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('اردو'), findsOneWidget);

      // Tap toggle button
      await tester.tap(find.byKey(const Key('lang_toggle_chip')));
      await tester.pumpAndSettle();

      expect(find.text('ENG'), findsOneWidget);
      expect(find.text('Aayan کی جگہ'), findsOneWidget);
    });

    testWidgets('ChildDashboard switches between Learn, Schedule, and Badges tabs', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChildDashboard(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Tap Schedule tab
      await tester.tap(find.text('Schedule'));
      await tester.pumpAndSettle();

      expect(find.text('Daily Visual Routine Timeline'), findsOneWidget);
      expect(find.text('Morning Routine: Wake Up & Stretch'), findsOneWidget);

      // Tap Badges tab
      await tester.tap(find.text('Badges'));
      await tester.pumpAndSettle();

      expect(find.text('First Spark'), findsOneWidget);
      expect(find.text('Streak Hero'), findsOneWidget);
    });

    testWidgets('LessonScreen renders prompt and completes with celebration dialog', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LessonScreen(
            lessonTitle: 'Wash Hands',
            videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
            englishPrompt: 'Say "Clean bubbles" while washing your hands!',
            urduPrompt: 'ہاتھ دھوتے وقت کہیں "صاف جھاگ"!',
            interactionType: 'voice',
            isUrdu: false,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Check header and prompt
      expect(find.text('Wash Hands'), findsWidgets);
      expect(find.text('VOICE'), findsOneWidget);
      expect(find.byKey(const Key('manual_complete_btn')), findsOneWidget);

      // Complete lesson via manual complete button
      await tester.ensureVisible(find.byKey(const Key('manual_complete_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('manual_complete_btn')));
      await tester.pumpAndSettle();

      // Celebration dialog should appear
      expect(find.text('Great Job!'), findsOneWidget);
      expect(find.byKey(const Key('celebration_done_btn')), findsOneWidget);

      // Tap continue
      await tester.tap(find.byKey(const Key('celebration_done_btn')));
      await tester.pumpAndSettle();

      // Screen pops
      expect(find.byType(LessonScreen), findsNothing);
    });

    testWidgets('LessonScreen for Camera interaction renders camera UI and smile button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LessonScreen(
            lessonTitle: 'Emotions Mirror',
            videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
            englishPrompt: 'Look at the mirror and smile with joy!',
            urduPrompt: 'آئینے میں دیکھیں اور خوشی سے مسکرائیں!',
            interactionType: 'camera',
            isUrdu: false,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Emotions Mirror'), findsWidgets);
      expect(find.text('CAMERA'), findsOneWidget);
      expect(find.byKey(const Key('smile_complete_btn')), findsOneWidget);
      expect(find.text('I am Smiling!'), findsOneWidget);

      // Tap smile button
      await tester.ensureVisible(find.byKey(const Key('smile_complete_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('smile_complete_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Great Job!'), findsOneWidget);
    });
  });
}
