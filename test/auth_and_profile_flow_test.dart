import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parwarish_ai/screens/welcome_screen.dart';
import 'package:parwarish_ai/screens/auth/child_login_screen.dart';
import 'package:parwarish_ai/screens/child/child_profile_selection.dart';
import 'package:parwarish_ai/services/localization_service.dart';
import 'package:parwarish_ai/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalizationService.instance.init();
    await AuthService.instance.init();
  });

  group('Task 3: Authentication & Profile Selection Flow Tests', () {
    testWidgets('WelcomeScreen renders Parwarish.ai branding and two primary buttons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomeScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Parwarish.ai'), findsOneWidget);
      expect(find.byKey(const Key('parent_portal_btn')), findsOneWidget);
      expect(find.byKey(const Key('child_space_btn')), findsOneWidget);
    });

    testWidgets('WelcomeScreen navigating to Parent Portal opens ChildLoginScreen(isParentLogin: true)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomeScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));

      // Tap Parent Portal
      await tester.ensureVisible(find.byKey(const Key('parent_portal_btn')));
      await tester.tap(find.byKey(const Key('parent_portal_btn')));
      await tester.pumpAndSettle();

      expect(find.byType(ChildLoginScreen), findsOneWidget);
      final loginScreenFinder = find.byType(ChildLoginScreen);
      final loginScreen = tester.widget<ChildLoginScreen>(loginScreenFinder);
      expect(loginScreen.isParentLogin, isTrue);
      expect(find.text('Sign In to Parent Portal'), findsOneWidget);
      expect(find.byKey(const Key('google_sign_in_btn')), findsOneWidget);
      expect(find.byKey(const Key('apple_sign_in_btn')), findsOneWidget);
    });

    testWidgets('WelcomeScreen navigating to Child Space opens ChildLoginScreen(isParentLogin: false)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomeScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));

      // Tap Child Space
      await tester.ensureVisible(find.byKey(const Key('child_space_btn')));
      await tester.tap(find.byKey(const Key('child_space_btn')));
      await tester.pumpAndSettle();

      expect(find.byType(ChildLoginScreen), findsOneWidget);
      final loginScreenFinder = find.byType(ChildLoginScreen);
      final loginScreen = tester.widget<ChildLoginScreen>(loginScreenFinder);
      expect(loginScreen.isParentLogin, isFalse);
      expect(find.text('Sign In to Child Space'), findsOneWidget);
    });

    testWidgets('ChildLoginScreen email sign-in stores user_role and space in SharedPreferences', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChildLoginScreen(isParentLogin: false),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Requirement 5: Demo login button must NOT be present
      expect(find.byKey(const Key('demo_login_btn')), findsNothing);

      // Enter credentials and tap sign in
      await tester.enterText(find.byKey(const Key('email_field')), 'child@parwarish.ai');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      await tester.ensureVisible(find.byKey(const Key('sign_in_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sign_in_button')));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_role'), equals('child'));
      expect(prefs.getString('selected_device_space'), equals('child'));
    });

    testWidgets('ChildProfileSelection displays animated grid of child cards', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChildProfileSelection(parentUid: 'parent_demo_01'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(ChildProfileSelection), findsOneWidget);
      expect(find.text('Who is Learning Today?'), findsOneWidget);
      expect(find.text('Aayan'), findsOneWidget);
      expect(find.text('Zainab'), findsOneWidget);
    });
  });
}
