// ignore_for_file: subtype_of_sealed_class, must_be_immutable
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parwarish_ai/models/child_profile.dart';
import 'package:parwarish_ai/models/activity_log.dart';
import 'package:parwarish_ai/services/streak_service.dart';

class FakeDocumentSnapshot extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  final Map<String, dynamic>? _data;
  final String _id;
  FakeDocumentSnapshot(this._id, this._data);

  @override
  String get id => _id;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  bool get exists => _data != null;
}

class FakeDocumentReference extends Fake implements DocumentReference<Map<String, dynamic>> {
  Map<String, dynamic>? currentData;
  Map<String, dynamic>? updatedData;

  FakeDocumentReference(this.currentData);

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    return FakeDocumentSnapshot('child_001', currentData);
  }

  @override
  Future<void> update(Map<Object?, Object?> data) async {
    updatedData = Map<String, dynamic>.from(data);
    if (currentData != null) {
      currentData!.addAll(updatedData!);
    } else {
      currentData = Map<String, dynamic>.from(updatedData!);
    }
  }
}

void main() {
  group('ChildProfile Model Tests', () {
    test('ChildProfile instantiation and toMap()', () {
      final now = DateTime(2026, 9, 22, 10, 0);
      final profile = ChildProfile(
        id: 'child_101',
        parentUid: 'parent_202',
        name: 'Zain',
        autismLevel: 'Moderate',
        currentStreak: 4,
        lastLogin: now,
        struggleFlags: 2,
      );

      expect(profile.id, equals('child_101'));
      expect(profile.parentUid, equals('parent_202'));
      expect(profile.name, equals('Zain'));
      expect(profile.autismLevel, equals('Moderate'));
      expect(profile.currentStreak, equals(4));
      expect(profile.lastLogin, equals(now));
      expect(profile.struggleFlags, equals(2));

      final map = profile.toMap();
      expect(map['parent_uid'], equals('parent_202'));
      expect(map['name'], equals('Zain'));
      expect(map['autism_level'], equals('Moderate'));
      expect(map['current_streak'], equals(4));
      expect((map['last_login'] as Timestamp).toDate(), equals(now));
      expect(map['struggle_flags'], equals(2));
    });

    test('ChildProfile.fromFirestore handles null timestamps gracefully', () {
      final doc = FakeDocumentSnapshot('child_102', {
        'parent_uid': 'parent_303',
        'name': 'Sara',
        'autism_level': 'Mild',
        'current_streak': 1,
        'last_login': null,
        'struggle_flags': 0,
      });

      final profile = ChildProfile.fromFirestore(doc);
      expect(profile.id, equals('child_102'));
      expect(profile.parentUid, equals('parent_303'));
      expect(profile.name, equals('Sara'));
      expect(profile.autismLevel, equals('Mild'));
      expect(profile.currentStreak, equals(1));
      expect(profile.lastLogin, isNull);
      expect(profile.struggleFlags, equals(0));

      final map = profile.toMap();
      expect(map['last_login'], isNull);
    });

    test('ChildProfile.fromFirestore parses valid Timestamp', () {
      final loginDate = DateTime(2026, 9, 21, 14, 30);
      final doc = FakeDocumentSnapshot('child_103', {
        'parent_uid': 'parent_404',
        'name': 'Hamza',
        'autism_level': 'Severe',
        'current_streak': 7,
        'last_login': Timestamp.fromDate(loginDate),
        'struggle_flags': 3,
      });

      final profile = ChildProfile.fromFirestore(doc);
      expect(profile.id, equals('child_103'));
      expect(profile.name, equals('Hamza'));
      expect(profile.autismLevel, equals('Severe'));
      expect(profile.currentStreak, equals(7));
      expect(profile.lastLogin, equals(loginDate));
      expect(profile.struggleFlags, equals(3));
    });
  });

  group('ActivityLog Model Tests', () {
    test('ActivityLog instantiation and toMap()', () {
      final completedAt = DateTime(2026, 9, 22, 11, 15);
      final log = ActivityLog(
        id: 'log_001',
        moduleName: 'Calm Breathing',
        interactionType: 'breathe',
        completedAt: completedAt,
        durationSeconds: 120,
        struggleCount: 1,
      );

      expect(log.id, equals('log_001'));
      expect(log.moduleName, equals('Calm Breathing'));
      expect(log.interactionType, equals('breathe'));
      expect(log.completedAt, equals(completedAt));
      expect(log.durationSeconds, equals(120));
      expect(log.struggleCount, equals(1));

      final map = log.toMap();
      expect(map['module_name'], equals('Calm Breathing'));
      expect(map['interaction_type'], equals('breathe'));
      expect((map['completed_at'] as Timestamp).toDate(), equals(completedAt));
      expect(map['duration_seconds'], equals(120));
      expect(map['struggle_count'], equals(1));
    });

    test('ActivityLog.fromFirestore parses snapshot properly', () {
      final completedAt = DateTime(2026, 9, 22, 8, 45);
      final doc = FakeDocumentSnapshot('log_002', {
        'module_name': 'Emotion Mirror',
        'interaction_type': 'camera',
        'completed_at': Timestamp.fromDate(completedAt),
        'duration_seconds': 90,
        'struggle_count': 0,
      });

      final log = ActivityLog.fromFirestore(doc);
      expect(log.id, equals('log_002'));
      expect(log.moduleName, equals('Emotion Mirror'));
      expect(log.interactionType, equals('camera'));
      expect(log.completedAt, equals(completedAt));
      expect(log.durationSeconds, equals(90));
      expect(log.struggleCount, equals(0));
    });
  });

  group('StreakService.checkAndUpdateStreak Tests', () {
    test('If last_login is null: newStreak = 1 and updates Firestore', () async {
      final fakeRef = FakeDocumentReference({
        'current_streak': 0,
        'last_login': null,
      });

      final newStreak = await StreakService.checkAndUpdateStreak(
        childId: 'child_001',
        childDocRef: fakeRef,
        nowOverride: DateTime(2026, 9, 22, 10, 0),
      );

      expect(newStreak, equals(1));
      expect(fakeRef.updatedData, isNotNull);
      expect(fakeRef.updatedData!['current_streak'], equals(1));
      expect(fakeRef.updatedData!['last_login'], isA<FieldValue>());
    });

    test('If last_login is yesterday: newStreak = currentStreak + 1 and updates Firestore', () async {
      final yesterday = DateTime(2026, 9, 21, 15, 0);
      final fakeRef = FakeDocumentReference({
        'current_streak': 5,
        'last_login': Timestamp.fromDate(yesterday),
      });

      final newStreak = await StreakService.checkAndUpdateStreak(
        childId: 'child_001',
        childDocRef: fakeRef,
        nowOverride: DateTime(2026, 9, 22, 10, 0),
      );

      expect(newStreak, equals(6));
      expect(fakeRef.updatedData, isNotNull);
      expect(fakeRef.updatedData!['current_streak'], equals(6));
    });

    test('If last_login is > 1 day ago: newStreak = 1 (streak broken) and updates Firestore', () async {
      final threeDaysAgo = DateTime(2026, 9, 19, 10, 0);
      final fakeRef = FakeDocumentReference({
        'current_streak': 8,
        'last_login': Timestamp.fromDate(threeDaysAgo),
      });

      final newStreak = await StreakService.checkAndUpdateStreak(
        childId: 'child_001',
        childDocRef: fakeRef,
        nowOverride: DateTime(2026, 9, 22, 10, 0),
      );

      expect(newStreak, equals(1));
      expect(fakeRef.updatedData, isNotNull);
      expect(fakeRef.updatedData!['current_streak'], equals(1));
    });

    test('If last_login is today: newStreak = currentStreak and does NOT update Firestore', () async {
      final todayMorning = DateTime(2026, 9, 22, 7, 0);
      final fakeRef = FakeDocumentReference({
        'current_streak': 4,
        'last_login': Timestamp.fromDate(todayMorning),
      });

      final newStreak = await StreakService.checkAndUpdateStreak(
        childId: 'child_001',
        childDocRef: fakeRef,
        nowOverride: DateTime(2026, 9, 22, 18, 0),
      );

      expect(newStreak, equals(4));
      // No update expected because already logged in today
      expect(fakeRef.updatedData, isNull);
    });
  });
}
