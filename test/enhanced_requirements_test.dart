import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parwarish_ai/main.dart';
import 'package:parwarish_ai/screens/welcome_screen.dart';
import 'package:parwarish_ai/screens/auth/child_login_screen.dart';
import 'package:parwarish_ai/screens/child/child_dashboard.dart';
import 'package:parwarish_ai/screens/settings/child_settings_screen.dart';
import 'package:parwarish_ai/screens/settings/parent_settings_screen.dart';
import 'package:parwarish_ai/services/theme_service.dart';
import 'package:parwarish_ai/services/notification_service.dart';
import 'package:parwarish_ai/services/localization_service.dart';
import 'package:parwarish_ai/services/auth_service.dart';
import 'package:parwarish_ai/services/clinical_service.dart';
import 'package:parwarish_ai/models/daily_session_model.dart';
import 'package:parwarish_ai/models/child_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalizationService.instance.init();
    await AuthService.instance.init();
    await ThemeService.instance.init();
    await ParentNotificationService.instance.init();
    ClinicalService.instance.init();
  });

  group('7 Core Requirements Verification Tests', () {
    // ---------------------------------------------------------------------------
    // Requirement 1: 1-time space selection with guidelines and automatic selection
    // ---------------------------------------------------------------------------
    testWidgets('Req 1: Welcome Screen displays 1-time setup guidelines and stores selection', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: WelcomeScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Guidelines banner must be visible
      expect(find.text('First-Time Installation Guidelines'), findsOneWidget);
      expect(find.byKey(const Key('parent_portal_btn')), findsOneWidget);
      expect(find.byKey(const Key('child_space_btn')), findsOneWidget);

      // Tap Child Space button
      await tester.ensureVisible(find.byKey(const Key('child_space_btn')));
      await tester.tap(find.byKey(const Key('child_space_btn')));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selected_device_space'), equals('child'));
    });

    testWidgets('Req 1: Subsequent launch automatically opens chosen space without welcome screen', (tester) async {
      SharedPreferences.setMockInitialValues({
        'selected_device_space': 'child',
        'user_role': 'child',
      });
      await AuthService.instance.init();

      await tester.pumpWidget(const ParwarishApp());
      await tester.pumpAndSettle();

      // Welcome screen must NOT appear
      expect(find.byType(WelcomeScreen), findsNothing);
      expect(find.text('First-Time Installation Guidelines'), findsNothing);
      // Directly opens child space / profile selection
      expect(find.text('Who is Learning Today?'), findsOneWidget);
    });

    // ---------------------------------------------------------------------------
    // Requirement 2: In child space, filters for games are removed
    // ---------------------------------------------------------------------------
    testWidgets('Req 2: Child Space does NOT have game category filter chips', (tester) async {
      SharedPreferences.setMockInitialValues({
        'child_id': 'child_01',
        'child_name': 'Aayan',
        'autism_level': 'Mild',
        'user_role': 'child',
      });

      await tester.pumpWidget(
        const MaterialApp(home: ChildDashboard()),
      );
      await tester.pumpAndSettle();

      // Filter chips must not exist in child space
      expect(find.byKey(const Key('game_category_chip_all')), findsNothing);
      expect(find.byKey(const Key('game_category_chip_adl')), findsNothing);
      expect(find.byKey(const Key('game_category_chip_sorting')), findsNothing);
      expect(find.byKey(const Key('game_category_chip_calming')), findsNothing);
      expect(find.text('All Games (11)'), findsNothing);
    });

    // ---------------------------------------------------------------------------
    // Requirement 3: Child is only shown quests & games setup according to therapist goals
    // ---------------------------------------------------------------------------
    testWidgets('Req 3: Child is only shown therapist assigned goals and games', (tester) async {
      // Child with 2 specific goals from therapist
      final testChild = ChildModel(
        id: 'child_test_goals',
        parentUid: 'parent_demo_01',
        name: 'Aayan',
        autismLevel: 'Moderate',
        currentStreak: 5,
        lastLogin: DateTime.now(),
      );

      // Assign goals to child in ClinicalService
      await ClinicalService.instance.pushGoalsToChild(
        childId: 'child_test_goals',
        callerRole: 'therapist',
        goals: [
          ActiveGoalItem(
            goalId: 'g_08_01',
            domainId: 8,
            domainName: 'ADL: Personal Hygiene',
            goalTitle: 'Hand Washing 4-Stage Routine',
            assignedAt: DateTime.now(),
          ),
          ActiveGoalItem(
            goalId: 'g_07_01',
            domainId: 7,
            domainName: 'Sensory Regulation',
            goalTitle: 'Paced Deep Breathing',
            assignedAt: DateTime.now(),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(home: ChildDashboard(child: testChild)),
      );
      await tester.pumpAndSettle();

      // Only the assigned quests should be present
      expect(find.text('Wash Hands'), findsOneWidget);
      expect(find.text('Calm Down'), findsOneWidget);
      // Unassigned quest should not be present
      expect(find.text('Tie Shoes'), findsNothing);

      // Scroll to view games
      await tester.scrollUntilVisible(find.byKey(const Key('game_card_wash_hands')), 200);
      expect(find.byKey(const Key('game_card_wash_hands')), findsOneWidget);
      await tester.scrollUntilVisible(find.byKey(const Key('game_card_breathing_flower')), 200);
      expect(find.byKey(const Key('game_card_breathing_flower')), findsOneWidget);
      // Unassigned game should not be present
      expect(find.byKey(const Key('game_card_fruit_merge')), findsNothing);
    });

    // ---------------------------------------------------------------------------
    // Requirement 4: Schedule quest automatically marked when completed
    // ---------------------------------------------------------------------------
    testWidgets('Req 4: Schedule item is auto-marked when quest completes', (tester) async {
      SharedPreferences.setMockInitialValues({
        'child_id': 'child_01',
        'child_name': 'Aayan',
        'autism_level': 'Moderate',
      });

      await tester.pumpWidget(
        const MaterialApp(home: ChildDashboard()),
      );
      await tester.pumpAndSettle();

      // Open schedule tab first to check initial state
      await tester.tap(find.text('Schedule'));
      await tester.pumpAndSettle();
      expect(find.text('Quest: Wash Hands'), findsOneWidget);

      // Return to learn tab
      await tester.tap(find.text('Learn'));
      await tester.pumpAndSettle();

      // Tap Wash Hands quest card
      await tester.tap(find.byKey(const Key('lesson_card_wash_hands')));
      await tester.pumpAndSettle();

      // Complete quest via manual complete button
      await tester.ensureVisible(find.byKey(const Key('manual_complete_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('manual_complete_btn')));
      await tester.pumpAndSettle();

      // Dismiss celebration dialog
      await tester.tap(find.byKey(const Key('celebration_done_btn')));
      await tester.pumpAndSettle();

      // Go to Schedule tab
      await tester.tap(find.text('Schedule'));
      await tester.pumpAndSettle();

      // The quest checkbox in the schedule should now be checked (line-through decoration)
      final textWidget = tester.widget<Text>(find.text('Quest: Wash Hands'));
      expect(textWidget.style?.decoration, equals(TextDecoration.lineThrough));
    });

    // ---------------------------------------------------------------------------
    // Requirement 5: Remove demo feature on login screen of child and parent
    // ---------------------------------------------------------------------------
    testWidgets('Req 5: Login screen has NO demo feature and empty input fields', (tester) async {
      // Test Child Login Screen
      await tester.pumpWidget(
        const MaterialApp(home: ChildLoginScreen(isParentLogin: false)),
      );
      await tester.pumpAndSettle();

      // Demo button must not exist
      expect(find.byKey(const Key('demo_login_btn')), findsNothing);
      expect(find.text('1-Tap Demo Instant Access'), findsNothing);

      // Fields must not be pre-filled with demo credentials
      final emailField = tester.widget<TextField>(find.byKey(const Key('email_field')));
      expect(emailField.controller?.text, isEmpty);

      final passField = tester.widget<TextField>(find.byKey(const Key('password_field')));
      expect(passField.controller?.text, isEmpty);

      // Test Parent Login Screen
      await tester.pumpWidget(
        const MaterialApp(home: ChildLoginScreen(isParentLogin: true)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('demo_login_btn')), findsNothing);
      final parentEmailField = tester.widget<TextField>(find.byKey(const Key('email_field')));
      expect(parentEmailField.controller?.text, isEmpty);
    });

    // ---------------------------------------------------------------------------
    // Requirement 6: Mode changing (Dark / Light / System Aligned)
    // ---------------------------------------------------------------------------
    test('Req 6: Mode changing updates ThemeService and persists to SharedPreferences', () async {
      expect(ThemeService.instance.currentThemeMode, equals(ThemeMode.system));

      await ThemeService.instance.setThemeMode(ThemeMode.dark);
      expect(ThemeService.instance.currentThemeMode, equals(ThemeMode.dark));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_theme_mode'), equals('dark'));

      await ThemeService.instance.setThemeMode(ThemeMode.light);
      expect(ThemeService.instance.currentThemeMode, equals(ThemeMode.light));
      expect(prefs.getString('app_theme_mode'), equals('light'));
    });

    // ---------------------------------------------------------------------------
    // Requirement 7: Settings in app, parent gate, parent notification, child options
    // ---------------------------------------------------------------------------
    testWidgets('Req 7: Child clicking settings triggers notification and prompts parent credentials', (tester) async {
      SharedPreferences.setMockInitialValues({
        'child_id': 'child_01',
        'child_name': 'Aayan',
        'current_user_email': 'parent@parwarish.ai',
      });
      await AuthService.instance.init();

      await tester.pumpWidget(
        const MaterialApp(home: ChildDashboard()),
      );
      await tester.pumpAndSettle();

      // Settings button must exist
      expect(find.byKey(const Key('child_settings_btn')), findsOneWidget);

      // Tap settings button
      await tester.tap(find.byKey(const Key('child_settings_btn')));
      await tester.pumpAndSettle();

      // Parent notification must be sent
      expect(ParentNotificationService.instance.notifications.isNotEmpty, isTrue);
      expect(
        ParentNotificationService.instance.notifications.first.message,
        contains('Aayan is attempting to access and modify settings'),
      );

      // Parent login / verification dialog must be shown
      expect(find.text('Parent Authorization'), findsOneWidget);
      expect(find.byKey(const Key('parent_gate_password')), findsOneWidget);

      // Child cannot proceed without password
      await tester.tap(find.byKey(const Key('parent_gate_unlock_btn')));
      await tester.pumpAndSettle();
      expect(find.byType(ChildSettingsScreen), findsNothing);

      // Enter parent credentials
      await tester.enterText(find.byKey(const Key('parent_gate_password')), 'parentPass123');
      await tester.tap(find.byKey(const Key('parent_gate_unlock_btn')));
      await tester.pumpAndSettle();

      // Child Settings Screen opens
      expect(find.byType(ChildSettingsScreen), findsOneWidget);
      // Safe options for child
      expect(find.text('Theme Mode (Light / Dark / System)'), findsOneWidget);
      expect(find.text('Favorite Color Scheme'), findsOneWidget);
      expect(find.text('Font Size Scaling'), findsOneWidget);
    });

    testWidgets('Req 7: Parent Settings Screen allows managing space, themes, and viewing alerts', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ParentSettingsScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Parent Settings & Control'), findsOneWidget);
      expect(find.text('Display Mode (Dark / Light / System Aligned)'), findsOneWidget);
      expect(find.text('Color Scheme'), findsOneWidget);
      expect(find.text('Font Size Scaling'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Device Space Management'), 200);
      expect(find.text('Device Space Management'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Child Security Alerts & History'), 200);
      expect(find.text('Child Security Alerts & History'), findsOneWidget);
    });
  });
}
