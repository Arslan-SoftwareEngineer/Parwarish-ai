import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parwarish_ai/core/constants/clinical_domains.dart';
import 'package:parwarish_ai/services/auth_service.dart';
import 'package:parwarish_ai/services/clinical_service.dart';
import 'package:parwarish_ai/models/daily_session_model.dart';
import 'package:parwarish_ai/screens/therapist/therapist_portal_screen.dart';
import 'package:parwarish_ai/screens/therapist/therapist_login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'user_role': 'therapist',
      'current_user_email': 'dr_ayesha@parwarish.ai',
      'current_user_name': 'Dr. Ayesha Khan, BCBA-D',
      'license_number': 'BCBA-PK-88492',
    });
    await AuthService.instance.init();
    ClinicalService.instance.init();
  });

  group('1. Clinical Domain & Goal Taxonomy (All 22 Domains)', () {
    test('All 22 Domains are correctly defined with IDs 1..22 and sub-goals', () {
      expect(ClinicalTaxonomy.domains.length, equals(22));

      final expectedNames = [
        'Receptive Language',
        'Expressive Language',
        'Social Interaction & Play',
        'Joint Attention',
        'Imitation & Modeling',
        'Emotional Recognition & Expression',
        'Sensory Regulation',
        'ADL: Personal Hygiene',
        'ADL: Dressing & Grooming',
        'ADL: Toileting & Bathroom Habits',
        'ADL: Feeding & Table Manners',
        'Fine Motor Coordination',
        'Gross Motor Pacing',
        'Executive Functioning: Organization',
        'Executive Functioning: Task Switching & Flexibility',
        'Cognitive Sorting & Seriation',
        'Cognitive Merging & Synthesis',
        'Visual-Spatial Awareness',
        'Frustration Tolerance & Coping',
        'Self-Advocacy & Functional Communication',
        'Routine & Daily Schedule Adherence',
        'Safety Awareness & Boundary Recognition',
      ];

      for (int i = 0; i < 22; i++) {
        final domain = ClinicalTaxonomy.domains[i];
        expect(domain.id, equals(i + 1));
        expect(domain.name, equals(expectedNames[i]));
        expect(domain.subGoals.isNotEmpty, isTrue);
        for (final goal in domain.subGoals) {
          expect(goal.goalId.isNotEmpty, isTrue);
          expect(goal.title.isNotEmpty, isTrue);
          expect(goal.moduleName.isNotEmpty, isTrue);
          expect(['touch_game', 'voice', 'camera', 'breathe'].contains(goal.interactionType), isTrue);
        }
      }
    });

    test('getDomainById returns correct domain and uniqueCategories works', () {
      final d7 = ClinicalTaxonomy.getDomainById(7);
      expect(d7, isNotNull);
      expect(d7!.name, equals('Sensory Regulation'));

      final d22 = ClinicalTaxonomy.getDomainById(22);
      expect(d22, isNotNull);
      expect(d22!.name, equals('Safety Awareness & Boundary Recognition'));

      final categories = ClinicalTaxonomy.uniqueCategories;
      expect(categories.contains('Communication'), isTrue);
      expect(categories.contains('Daily Living Skills'), isTrue);
      expect(categories.contains('Sensory & Behavioral'), isTrue);
    });
  });

  group('2. Strict Access Control & Gatekeeping Rules', () {
    test('Therapist & Admin callers are authorized to manage children and goals', () async {
      expect(() => ClinicalService.instance.verifyClinicalAuthority('therapist'), returnsNormally);
      expect(() => ClinicalService.instance.verifyClinicalAuthority('admin'), returnsNormally);
    });

    test('Parent role throws ClinicalAccessDeniedException on restricted actions', () async {
      expect(
        () => ClinicalService.instance.verifyClinicalAuthority('parent'),
        throwsA(isA<ClinicalAccessDeniedException>()),
      );

      // Parent cannot create child
      expect(
        () => ClinicalService.instance.createChild(
          name: 'Unauthorized Child',
          dateOfBirth: DateTime(2020, 1, 1),
          parentUid: 'parent_01',
          autismLevel: 'Mild',
          createdByUid: 'parent_01',
          callerRole: 'parent',
        ),
        throwsA(isA<ClinicalAccessDeniedException>()),
      );

      // Parent cannot reclassify autism level
      expect(
        () => ClinicalService.instance.updateChildAutismLevel(
          childId: 'child_01',
          newLevel: 'Severe',
          callerRole: 'parent',
        ),
        throwsA(isA<ClinicalAccessDeniedException>()),
      );

      // Parent cannot delete child
      expect(
        () => ClinicalService.instance.deleteChild(
          childId: 'child_01',
          callerRole: 'parent',
        ),
        throwsA(isA<ClinicalAccessDeniedException>()),
      );

      // Parent cannot push clinical goals
      expect(
        () => ClinicalService.instance.pushGoalsToChild(
          childId: 'child_01',
          goals: [],
          callerRole: 'parent',
        ),
        throwsA(isA<ClinicalAccessDeniedException>()),
      );

      // Parent cannot publish clinical report
      expect(
        () => ClinicalService.instance.publishTherapistReport(
          childId: 'child_01',
          dateString: '2026-09-22',
          report: TherapistReportModel(
            summary: 'Test',
            strengths: 'Test',
            areasOfConcern: 'Test',
            homeRecommendations: 'Test',
            submittedAt: DateTime.now(),
            therapistName: 'Parent Hacker',
          ),
          callerRole: 'parent',
        ),
        throwsA(isA<ClinicalAccessDeniedException>()),
      );
    });

    testWidgets('TherapistPortalScreen shows Access Denied screen when accessed with parent role', (tester) async {
      SharedPreferences.setMockInitialValues({
        'user_role': 'parent',
        'current_user_email': 'parent@parwarish.ai',
      });
      await AuthService.instance.init();

      await tester.pumpWidget(
        const MaterialApp(
          home: TherapistPortalScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Access Denied: Clinical Portal'), findsOneWidget);
      expect(find.textContaining('Parents do NOT have permission to register children'), findsOneWidget);
      expect(find.byKey(const Key('return_to_login_btn')), findsOneWidget);
    });
  });

  group('3. Children Directory & Management (Therapist/Admin CRUD)', () {
    test('Therapist can fetch children, create child, update autism level, and delete child', () async {
      final initial = await ClinicalService.instance.fetchChildren();
      expect(initial.isNotEmpty, isTrue);

      // Create new child
      final created = await ClinicalService.instance.createChild(
        name: 'Bilal Ahmed',
        dateOfBirth: DateTime(2019, 8, 14),
        parentUid: 'parent_demo_99',
        autismLevel: 'Moderate',
        createdByUid: 'therapist_demo_01',
        callerRole: 'therapist',
      );
      expect(created.name, equals('Bilal Ahmed'));
      expect(created.autismLevel, equals('Moderate'));

      // Update autism level
      await ClinicalService.instance.updateChildAutismLevel(
        childId: created.id,
        newLevel: 'Mild',
        callerRole: 'therapist',
      );
      final updatedList = await ClinicalService.instance.fetchChildren();
      final fetched = updatedList.firstWhere((c) => c.id == created.id);
      expect(fetched.autismLevel, equals('Mild'));

      // Delete child
      await ClinicalService.instance.deleteChild(
        childId: created.id,
        callerRole: 'therapist',
      );
      final afterDelete = await ClinicalService.instance.fetchChildren();
      expect(afterDelete.any((c) => c.id == created.id), isFalse);
    });

    testWidgets('Renders Children Directory, search input, and Add Child modal', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({
        'user_role': 'therapist',
        'current_user_email': 'dr_ayesha@parwarish.ai',
        'current_user_name': 'Dr. Ayesha Khan, BCBA-D',
      });
      await AuthService.instance.init();

      await tester.pumpWidget(
        const MaterialApp(
          home: TherapistPortalScreen(initialTabIndex: 0),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Children Clinical Directory'), findsOneWidget);
      expect(find.byKey(const Key('child_search_field')), findsOneWidget);
      expect(find.byKey(const Key('add_child_modal_btn')), findsOneWidget);
      expect(find.text('Aayan'), findsOneWidget);

      // Open Add Child Modal
      await tester.tap(find.byKey(const Key('add_child_modal_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Add Child Profile (Therapist/Admin)'), findsOneWidget);
      expect(find.byKey(const Key('modal_child_name_input')), findsOneWidget);
      expect(find.byKey(const Key('modal_autism_level_select')), findsOneWidget);
      expect(find.byKey(const Key('modal_save_child_btn')), findsOneWidget);
    });
  });

  group('4. Goal Assignment Studio', () {
    testWidgets('Goal Assignment Studio renders 22 domains and pushes goals to child', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({
        'user_role': 'therapist',
        'current_user_email': 'dr_ayesha@parwarish.ai',
      });
      await AuthService.instance.init();

      await tester.pumpWidget(
        const MaterialApp(
          home: TherapistPortalScreen(initialTabIndex: 1),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Clinical Goal Studio:'), findsOneWidget);
      expect(find.text('22 Clinical Domains'), findsOneWidget);
      expect(find.byKey(const Key('push_goals_btn')), findsOneWidget);

      // Switch to Sensory Regulation domain (ID 7)
      await tester.tap(find.byKey(const Key('domain_item_7')));
      await tester.pumpAndSettle();

      expect(find.text('Sensory Regulation'), findsWidgets);
      expect(find.byKey(const Key('goal_checkbox_g_07_01')), findsOneWidget);

      // Push goals
      await tester.tap(find.byKey(const Key('push_goals_btn')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Successfully pushed'), findsOneWidget);
    });
  });

  group('5. Daily Telemetry & Session Inspector', () {
    testWidgets('Telemetry Inspector renders 4 KPI cards and Granular Module Breakdown table', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      SharedPreferences.setMockInitialValues({
        'user_role': 'therapist',
        'current_user_email': 'dr_ayesha@parwarish.ai',
      });
      await AuthService.instance.init();

      await tester.pumpWidget(
        const MaterialApp(
          home: TherapistPortalScreen(initialTabIndex: 2),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Daily Telemetry Inspector:'), findsOneWidget);
      expect(find.byKey(const Key('kpi_time')), findsOneWidget);
      expect(find.byKey(const Key('kpi_completion')), findsOneWidget);
      expect(find.byKey(const Key('kpi_mood')), findsOneWidget);
      expect(find.byKey(const Key('kpi_struggle')), findsOneWidget);
      expect(find.text('Granular Module Breakdown'), findsOneWidget);
    });
  });

  group('6. Daily Report Generator & Parent Messenger', () {
    testWidgets('Report Generator pre-populates fields and finalizes report to parent', (tester) async {
      SharedPreferences.setMockInitialValues({
        'user_role': 'therapist',
        'current_user_email': 'dr_ayesha@parwarish.ai',
      });
      await AuthService.instance.init();

      await tester.pumpWidget(
        const MaterialApp(
          home: TherapistPortalScreen(initialTabIndex: 3),
        ),
      );
      await tester.pumpAndSettle();

      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      expect(find.textContaining('Clinical Daily Report:'), findsOneWidget);
      expect(find.byKey(const Key('report_summary_field')), findsOneWidget);
      expect(find.byKey(const Key('report_strengths_field')), findsOneWidget);
      expect(find.byKey(const Key('report_concerns_field')), findsOneWidget);
      expect(find.byKey(const Key('report_home_plan_field')), findsOneWidget);
      expect(find.byKey(const Key('finalize_and_send_btn')), findsOneWidget);

      // Tap finalize & send
      await tester.ensureVisible(find.byKey(const Key('finalize_and_send_btn')));
      await tester.tap(find.byKey(const Key('finalize_and_send_btn')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Report finalized and published to Parent Dashboard'), findsOneWidget);
    });
  });

  group('7. Therapist Clinical Login Screen', () {
    testWidgets('TherapistLoginScreen renders fields, role switch, and quick demo buttons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TherapistLoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Parwarish.ai Clinical Portal'), findsOneWidget);
      expect(find.byKey(const Key('role_therapist_tab')), findsOneWidget);
      expect(find.byKey(const Key('role_admin_tab')), findsOneWidget);
      expect(find.byKey(const Key('therapist_email_field')), findsOneWidget);
      expect(find.byKey(const Key('therapist_license_field')), findsOneWidget);
      expect(find.byKey(const Key('therapist_password_field')), findsOneWidget);
      expect(find.byKey(const Key('therapist_signin_button')), findsOneWidget);
      expect(find.byKey(const Key('quick_therapist_btn')), findsOneWidget);
      expect(find.byKey(const Key('quick_admin_btn')), findsOneWidget);
      expect(find.byKey(const Key('simulate_parent_btn')), findsOneWidget);
    });
  });
}
