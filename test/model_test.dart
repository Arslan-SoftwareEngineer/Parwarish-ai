import 'package:flutter_test/flutter_test.dart';
import 'package:parwarish_ai/models/child_model.dart';
import 'package:parwarish_ai/models/parent_model.dart';
import 'package:parwarish_ai/models/activity_log_model.dart';

void main() {
  group('Data Models Tests', () {
    test('ChildModel serialization and parsing', () {
      final now = DateTime.now();
      final child = ChildModel(
        id: 'child_123',
        parentUid: 'parent_456',
        name: 'Aayan',
        autismLevel: 'Moderate',
        currentStreak: 5,
        lastLogin: now,
      );

      final map = child.toMap();
      expect(map['parent_uid'], equals('parent_456'));
      expect(map['name'], equals('Aayan'));
      expect(map['autism_level'], equals('Moderate'));
      expect(map['current_streak'], equals(5));

      final restored = ChildModel.fromMap('child_123', {
        'parent_uid': 'parent_456',
        'name': 'Aayan',
        'autism_level': 'Moderate',
        'current_streak': 5,
        'last_login': now.toIso8601String(),
      });

      expect(restored.id, equals('child_123'));
      expect(restored.name, equals('Aayan'));
      expect(restored.autismLevel, equals('Moderate'));
      expect(restored.currentStreak, equals(5));
    });

    test('ParentModel mapping', () {
      final now = DateTime.now();
      final parent = ParentModel(
        uid: 'uid_test',
        email: 'test@parwarish.ai',
        createdAt: now,
      );

      final map = parent.toMap();
      expect(map['email'], equals('test@parwarish.ai'));

      final restored = ParentModel.fromMap('uid_test', {
        'email': 'test@parwarish.ai',
        'created_at': now.toIso8601String(),
      });

      expect(restored.uid, equals('uid_test'));
      expect(restored.email, equals('test@parwarish.ai'));
    });

    test('ActivityLogModel mapping', () {
      final now = DateTime.now();
      final log = ActivityLogModel(
        id: 'log_999',
        moduleName: 'Wash Hands',
        interactionType: 'voice',
        completedAt: now,
      );

      final map = log.toMap();
      expect(map['module_name'], equals('Wash Hands'));
      expect(map['interaction_type'], equals('voice'));

      final restored = ActivityLogModel.fromMap('log_999', {
        'module_name': 'Wash Hands',
        'interaction_type': 'voice',
        'completed_at': now.toIso8601String(),
      });

      expect(restored.id, equals('log_999'));
      expect(restored.moduleName, equals('Wash Hands'));
      expect(restored.interactionType, equals('voice'));
    });
  });
}
