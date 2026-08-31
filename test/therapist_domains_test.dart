import 'package:flutter_test/flutter_test.dart';
import 'package:parwarish_ai/services/therapist_service.dart';

void main() {
  group('Therapist 22 Autism Clinical Domains Tests', () {
    test('Verify that all 22 clinical domains are present and numbered 1 to 22', () {
      final domains = TherapistService.instance.domains;
      expect(domains.length, equals(22));

      for (int i = 0; i < 22; i++) {
        expect(domains[i].indexNumber, equals(i + 1));
        expect(domains[i].titleEn.isNotEmpty, isTrue);
        expect(domains[i].titleUr.isNotEmpty, isTrue);
        expect(domains[i].goals.isNotEmpty, isTrue);
      }
    });

    test('Verify clinical goal retrieval by ID', () {
      final goal = TherapistService.instance.getGoalById('goal_04_1');
      expect(goal, isNotNull);
      expect(goal!.domainId, equals('dom_04'));
      expect(goal.gameType, equals('emotion_mirror'));
      expect(goal.titleEn, contains('Happy Smile'));
    });

    test('Verify domain retrieval by ID', () {
      final domain = TherapistService.instance.getDomainById('dom_09');
      expect(domain, isNotNull);
      expect(domain!.indexNumber, equals(9));
      expect(domain.titleEn, contains('Hygiene & Handwashing'));
    });
  });
}
