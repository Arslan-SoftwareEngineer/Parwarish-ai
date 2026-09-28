import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parwarish_ai/main.dart';
import 'package:parwarish_ai/screens/welcome_screen.dart';
import 'package:parwarish_ai/services/localization_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalizationService.instance.init();
  });

  testWidgets('ParwarishApp launches with WelcomeScreen showing Parent Portal and Child Space, and NO Therapist role', (WidgetTester tester) async {
    await tester.pumpWidget(const ParwarishApp());
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.text('Parwarish.ai'), findsOneWidget);
    expect(find.text('Parent Portal'), findsOneWidget);
    expect(find.text('Child Space'), findsOneWidget);
    expect(find.text('Therapist'), findsNothing);
  });
}
