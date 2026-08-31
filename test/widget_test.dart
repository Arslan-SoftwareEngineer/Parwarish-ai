import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parwarish_ai/main.dart';
import 'package:parwarish_ai/child_login_screen.dart';
import 'package:parwarish_ai/services/localization_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalizationService.instance.init();
  });

  testWidgets('ParwarishApp launches with ChildLoginScreen and 3 role tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const ParwarishApp());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ChildLoginScreen), findsOneWidget);
    expect(find.text('Parwarish.ai'), findsOneWidget);
    expect(find.text('Parent Portal'), findsOneWidget);
    expect(find.text('Child Space'), findsOneWidget);
    expect(find.text('Therapist'), findsOneWidget);
  });
}
