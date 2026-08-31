import 'package:flutter_test/flutter_test.dart';
import 'package:parwarish_ai/services/streak_service.dart';

void main() {
  group('StreakService Tests', () {
    test('Consecutive day login (yesterday) increments streak', () {
      final now = DateTime(2026, 8, 31, 10, 0);
      final yesterday = DateTime(2026, 8, 30, 15, 30);

      final newStreak = StreakService.calculateNewStreak(
        lastLogin: yesterday,
        currentStreak: 3,
        currentDate: now,
      );

      expect(newStreak, equals(4));
    });

    test('Same day login maintains current streak', () {
      final now = DateTime(2026, 8, 31, 18, 0);
      final earlierToday = DateTime(2026, 8, 31, 8, 0);

      final newStreak = StreakService.calculateNewStreak(
        lastLogin: earlierToday,
        currentStreak: 5,
        currentDate: now,
      );

      expect(newStreak, equals(5));
    });

    test('Missed day (> 1 day ago) resets streak to 1', () {
      final now = DateTime(2026, 8, 31, 10, 0);
      final twoDaysAgo = DateTime(2026, 8, 29, 10, 0);

      final newStreak = StreakService.calculateNewStreak(
        lastLogin: twoDaysAgo,
        currentStreak: 10,
        currentDate: now,
      );

      expect(newStreak, equals(1));
    });

    test('Initial streak 0 with yesterday login increments to 1', () {
      final now = DateTime(2026, 8, 31, 10, 0);
      final yesterday = DateTime(2026, 8, 30, 10, 0);

      final newStreak = StreakService.calculateNewStreak(
        lastLogin: yesterday,
        currentStreak: 0,
        currentDate: now,
      );

      expect(newStreak, equals(1));
    });
  });
}
