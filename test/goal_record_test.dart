import 'package:flutter_test/flutter_test.dart';
import 'package:parwarish_ai/models/goal_record_model.dart';
import 'package:parwarish_ai/services/therapist_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Goal Record Telemetry Tests', () {
    test('GoalRecordModel serialization and telemetry logging', () async {
      final now = DateTime.now();
      final record = GoalRecordModel(
        id: 'rec_101',
        childId: 'child_01',
        domainId: 'dom_04',
        goalId: 'goal_04_1',
        moduleName: 'Happy Smile Mirror',
        gameType: 'emotion_mirror',
        timeTakenSeconds: 38,
        accuracyScore: 0.95,
        moodState: 'Happy',
        completedAt: now,
      );

      final map = record.toMap();
      expect(map['child_id'], equals('child_01'));
      expect(map['time_taken_seconds'], equals(38));
      expect(map['mood_state'], equals('Happy'));
      expect(map['accuracy_score'], equals(0.95));

      await TherapistService.instance.logGoalRecord(record);
      final logs = await TherapistService.instance.getGoalRecordsForChild('child_01');

      expect(logs.isNotEmpty, isTrue);
      expect(logs.first.moduleName, equals('Happy Smile Mirror'));
      expect(logs.first.timeTakenSeconds, equals(38));
      expect(logs.first.moodState, equals('Happy'));
    });
  });
}
