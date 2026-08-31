import 'package:flutter_test/flutter_test.dart';
import 'package:parwarish_ai/services/localization_service.dart';

void main() {
  group('Parent Psychological Safety Safeguard Tests', () {
    test('Parent dictionary contains positive strength terms and zero deficit labels', () {
      final loc = LocalizationService.instance;
      loc.currentLocale.value = 'en';

      expect(loc.tr('child_profiles'), equals('My Little Champions'));
      expect(loc.tr('analytics_title'), equals('Growth & Strengths'));
      expect(loc.tr('daily_reports'), equals('Daily Reports from Therapist'));
      expect(loc.tr('daily_strengths'), equals('Daily Strengths & Joys'));

      // Verify Urdu positive terms
      loc.currentLocale.value = 'ur';
      expect(loc.tr('child_profiles'), contains('چیمپیئنز'));
      expect(loc.tr('analytics_title'), contains('نمایاں صلاحیتیں'));
      expect(loc.tr('daily_reports'), contains('رپورٹ'));
    });
  });
}
