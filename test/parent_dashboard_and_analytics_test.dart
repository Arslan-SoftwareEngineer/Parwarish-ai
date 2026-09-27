import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parwarish_ai/screens/parent/parent_dashboard.dart';
import 'package:parwarish_ai/screens/parent/parent_analytics_view.dart';
import 'package:parwarish_ai/services/localization_service.dart';
import 'package:parwarish_ai/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'user_role': 'parent',
      'current_user_email': 'parent@parwarish.ai',
    });
    await LocalizationService.instance.init();
    await AuthService.instance.init();
  });

  group('Task 4: Parent Dashboard & Telemetry Analytics Tests', () {
    testWidgets('ParentDashboard renders AppBar and child cards with positive milestones and NO add child FAB', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ParentDashboard(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Check AppBar
      expect(find.text('Parent Dashboard'), findsOneWidget);
      expect(find.byKey(const Key('logout_button')), findsOneWidget);

      // Verify NO add child FAB exists in Parent Dashboard
      expect(find.byKey(const Key('add_child_fab')), findsNothing);
      expect(find.text('Add Child Profile'), findsNothing);

      // Check child cards and positive strength milestones (NO autism labels)
      expect(find.text('Aayan'), findsOneWidget);
      expect(find.text('Active Explorer'), findsWidgets);
      expect(find.textContaining('Autism Level'), findsNothing);
      expect(find.text('4d streak'), findsOneWidget);
    });

    testWidgets('ParentDashboard respects therapist-only enrollment rule', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ParentDashboard(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('Child enrollment and personalized routines are supervised'), findsOneWidget);
    });

    testWidgets('Tapping child card navigates to ParentAnalyticsView', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ParentDashboard(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Tap Aayan's card
      await tester.tap(find.byKey(const Key('child_card_child_01')));
      await tester.pumpAndSettle();

      expect(find.byType(ParentAnalyticsView), findsOneWidget);
      expect(find.text('Aayan'), findsOneWidget);
    });

    testWidgets('ParentAnalyticsView renders metrics, distribution row, and activity list', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ParentAnalyticsView(childId: 'child_01', childName: 'Aayan'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Top metric summary cards
      expect(find.byKey(const Key('metric_lessons_completed')), findsOneWidget);
      expect(find.byKey(const Key('metric_active_streak')), findsOneWidget);
      expect(find.byKey(const Key('metric_struggles_count')), findsOneWidget);

      // Interaction Distribution row
      expect(find.text('Interaction Distribution'), findsOneWidget);
      expect(find.text('Voice'), findsOneWidget);
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Breathe'), findsOneWidget);

      // Activity History list
      expect(find.text('Activity History'), findsOneWidget);
      expect(find.text('Morning Routine: Brush Teeth'), findsOneWidget);
      expect(find.text('Emotion Mirror: Happy Face Match'), findsOneWidget);
    });
  });
}
