import 'package:flutter_test/flutter_test.dart';
import 'package:parwarish_ai/services/localization_service.dart';

void main() {
  group('LocalizationService Tests', () {
    test('English and Urdu key resolutions', () {
      final loc = LocalizationService.instance;
      loc.currentLocale.value = 'en';

      expect(loc.tr('app_name'), equals('Parwarish.ai'));
      expect(loc.tr('parent_login'), equals('Parent Portal'));
      expect(loc.tr('child_login'), equals('Child Space'));

      loc.currentLocale.value = 'ur';
      expect(loc.tr('app_name'), contains('پرورش'));
      expect(loc.tr('parent_login'), contains('والدین'));
      expect(loc.tr('child_login'), contains('بچوں'));
    });
  });
}
