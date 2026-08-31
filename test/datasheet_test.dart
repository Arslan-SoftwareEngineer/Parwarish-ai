import 'package:flutter_test/flutter_test.dart';
import 'package:parwarish_ai/models/therapist_datasheet_model.dart';
import 'package:parwarish_ai/services/therapist_service.dart';

void main() {
  group('Therapist Datasheet & Clinical Case Record Tests', () {
    test('DatasheetSessionEntry correctly computes mastery percentage', () {
      final entry1 = DatasheetSessionEntry.create(
        id: 'entry_01',
        childId: 'child_123',
        childName: 'Ayaan',
        date: DateTime(2026, 8, 31, 10, 0),
        sessionType: 'ABA Therapy',
        domainId: 'domain_09_hygiene',
        domainTitle: 'Self-Care: Hygiene & Handwashing',
        goalId: 'goal_09_01',
        goalTitle: '4-Step Handwashing Sequence',
        promptLevel: 'Gestural',
        trialsAttempted: 10,
        trialsSuccessful: 9,
        sensoryState: 'Regulated',
        behavioralNotes: 'Calm throughout session.',
        clinicalNotes: 'Prompted gesturally on step 4.',
        homeRecommendations: 'Practice with visual sequence board.',
        nextSessionTargets: 'Fade prompt to independent.',
      );

      expect(entry1.masteryPercentage, equals(90.0));
      expect(entry1.promptLevel, equals('Gestural'));
      expect(entry1.sensoryState, equals('Regulated'));

      final zeroTrialsEntry = DatasheetSessionEntry.create(
        id: 'entry_02',
        childId: 'child_123',
        childName: 'Ayaan',
        date: DateTime.now(),
        sessionType: 'Baseline Assessment',
        domainId: 'domain_01_receptive_lang',
        domainTitle: 'Receptive Language',
        goalId: 'goal_01_01',
        goalTitle: 'Object Identification',
        promptLevel: 'Independent',
        trialsAttempted: 0,
        trialsSuccessful: 0,
        sensoryState: 'Calm',
        behavioralNotes: '',
        clinicalNotes: '',
        homeRecommendations: '',
        nextSessionTargets: '',
      );

      expect(zeroTrialsEntry.masteryPercentage, equals(0.0));
    });

    test('DatasheetSessionEntry serialization to and from Map', () {
      final now = DateTime(2026, 8, 31, 14, 30);
      final entry = DatasheetSessionEntry(
        id: 'test_id_99',
        childId: 'c_abc',
        childName: 'Zainab',
        date: now,
        sessionType: 'Speech & Language',
        domainId: 'domain_02_expressive_lang',
        domainTitle: 'Expressive Language & Vocalization',
        goalId: 'goal_02_01',
        goalTitle: 'Morning Phonics',
        promptLevel: 'Modeling',
        trialsAttempted: 12,
        trialsSuccessful: 9,
        masteryPercentage: 75.0,
        sensoryState: 'Sensory Seeking',
        behavioralNotes: 'Active vocal approximations.',
        clinicalNotes: 'Articulation improved by 25%.',
        homeRecommendations: 'Pause before handing snacks.',
        nextSessionTargets: 'Generalize verbal requests.',
        createdAt: now,
      );

      final map = entry.toMap();
      expect(map['child_id'], equals('c_abc'));
      expect(map['session_type'], equals('Speech & Language'));
      expect(map['trials_attempted'], equals(12));
      expect(map['trials_successful'], equals(9));
      expect(map['mastery_percentage'], equals(75.0));

      final restored = DatasheetSessionEntry.fromMap('test_id_99', {
        'child_id': map['child_id'],
        'child_name': map['child_name'],
        'date': now.toIso8601String(),
        'session_type': map['session_type'],
        'domain_id': map['domain_id'],
        'domain_title': map['domain_title'],
        'goal_id': map['goal_id'],
        'goal_title': map['goal_title'],
        'prompt_level': map['prompt_level'],
        'trials_attempted': map['trials_attempted'],
        'trials_successful': map['trials_successful'],
        'mastery_percentage': map['mastery_percentage'],
        'sensory_state': map['sensory_state'],
        'behavioral_notes': map['behavioral_notes'],
        'clinical_notes': map['clinical_notes'],
        'home_recommendations': map['home_recommendations'],
        'next_session_targets': map['next_session_targets'],
        'created_at': now.toIso8601String(),
      });

      expect(restored.id, equals('test_id_99'));
      expect(restored.childName, equals('Zainab'));
      expect(restored.goalTitle, equals('Morning Phonics'));
      expect(restored.masteryPercentage, equals(75.0));
      expect(restored.sensoryState, equals('Sensory Seeking'));
    });

    test('ChildClinicalSummary generates valid defaults and serializes', () {
      final summary = ChildClinicalSummary.defaultFor('child_xyz', 'Hamza');
      expect(summary.childId, equals('child_xyz'));
      expect(summary.caseId, startsWith('CAS-HAMZ'));
      expect(summary.sensoryTriggers.length, greaterThan(0));
      expect(summary.primaryReinforcers.length, greaterThan(0));

      final map = summary.toMap();
      final fromMap = ChildClinicalSummary.fromMap(map);
      expect(fromMap.caseId, equals(summary.caseId));
      expect(fromMap.primaryTherapist, equals(summary.primaryTherapist));
      expect(fromMap.sensoryTriggers.first, equals(summary.sensoryTriggers.first));
    });

    test('TherapistService exports valid CSV string', () {
      final entry = DatasheetSessionEntry.create(
        id: 'e1',
        childId: 'c1',
        childName: 'Aria',
        date: DateTime(2026, 8, 30),
        sessionType: 'Occupational Therapy',
        domainId: 'domain_06_fine_motor',
        domainTitle: 'Fine Motor',
        goalId: 'goal_06_01',
        goalTitle: 'Shoelace Knot Tracing',
        promptLevel: 'Verbal',
        trialsAttempted: 10,
        trialsSuccessful: 8,
        sensoryState: 'Regulated',
        behavioralNotes: 'Focused execution',
        clinicalNotes: 'Good precision',
        homeRecommendations: 'Practice buttoning',
        nextSessionTargets: 'Shoelace loops',
      );

      final csv = TherapistService.instance.exportDatasheetAsCsv([entry], childName: 'Aria');
      expect(csv, contains('"Date","Child","Session Type"'));
      expect(csv, contains('"Aria"'));
      expect(csv, contains('"Occupational Therapy"'));
      expect(csv, contains('"Shoelace Knot Tracing"'));
      expect(csv, contains('80.0'));
    });

    test('TherapistService generates comprehensive Clinical Summary Report', () {
      final summary = ChildClinicalSummary.defaultFor('c1', 'Aria');
      final entry = DatasheetSessionEntry.create(
        id: 'e1',
        childId: 'c1',
        childName: 'Aria',
        date: DateTime(2026, 8, 30),
        sessionType: 'ABA Therapy',
        domainId: 'domain_03_joint_attention',
        domainTitle: 'Joint Attention',
        goalId: 'goal_03_01',
        goalTitle: '4-Second Sustained Gaze',
        promptLevel: 'Gestural',
        trialsAttempted: 5,
        trialsSuccessful: 4,
        sensoryState: 'Regulated',
        behavioralNotes: 'High joint attention',
        clinicalNotes: 'Sustained eye contact with companion mascot',
        homeRecommendations: 'Engage during peekaboo',
        nextSessionTargets: 'Extend gaze to 6s',
      );

      final report = TherapistService.instance.generateClinicalSummaryReport(
        summary: summary,
        entries: [entry],
        childName: 'Aria',
      );

      expect(report, contains('PARWARISH.AI — CLINICAL CASE & DATASHEET SUMMARY'));
      expect(report, contains('Child Name: Aria'));
      expect(report, contains('SENSORY PROFILE & TRIGGERS:'));
      expect(report, contains('BEHAVIOR INTERVENTION PLAN:'));
      expect(report, contains('4-Second Sustained Gaze'));
    });
  });
}
