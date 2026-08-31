import 'package:flutter_test/flutter_test.dart';
import 'package:parwarish_ai/services/therapist_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Therapist Daily Report Tests', () {
    test('Create and retrieve daily progress report for parent', () async {
      final report = await TherapistService.instance.createAndSendDailyReport(
        childId: 'child_01',
        childName: 'Aayan',
        therapistName: 'Dr. Ayesha Khan',
        strengthsObserved: [
          'Joyful engagement with emotion mirror',
          'Fast physical step sequencing',
        ],
        therapistNotes: 'Great session today with cheerful smiles.',
        homeActivityTip: 'High-five after handwashing.',
        primaryMood: 'Happy',
        goalsCompletedCount: 3,
        totalDurationMinutes: 14,
      );

      expect(report.childName, equals('Aayan'));
      expect(report.therapistName, equals('Dr. Ayesha Khan'));
      expect(report.primaryMood, equals('Happy'));

      final reports = await TherapistService.instance.getDailyReportsForChild('child_01');
      expect(reports.isNotEmpty, isTrue);
      expect(reports.first.therapistNotes, contains('Great session today'));
    });
  });
}
