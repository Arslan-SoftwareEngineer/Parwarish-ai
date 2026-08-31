class StreakService {
  /// Computes the new streak based on the last login date and current date.
  /// - If last login was today: keep current streak (or 1 if 0).
  /// - If last login was yesterday: increment current streak by 1.
  /// - If last login was older than yesterday: reset current streak to 1.
  static int calculateNewStreak({
    required DateTime lastLogin,
    required int currentStreak,
    DateTime? currentDate,
  }) {
    final now = currentDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDay = DateTime(lastLogin.year, lastLogin.month, lastLogin.day);

    final differenceInDays = today.difference(lastDay).inDays;

    if (differenceInDays == 0) {
      // Same day login: keep current streak (ensure minimum 1)
      return currentStreak > 0 ? currentStreak : 1;
    } else if (differenceInDays == 1) {
      // Consecutive day login: increment streak
      return (currentStreak > 0 ? currentStreak : 0) + 1;
    } else {
      // Missed at least one day or first time: reset to 1
      return 1;
    }
  }

  /// Returns true if the streak was incremented today compared to yesterday
  static bool wasStreakIncremented({
    required DateTime lastLogin,
    DateTime? currentDate,
  }) {
    final now = currentDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDay = DateTime(lastLogin.year, lastLogin.month, lastLogin.day);
    return today.difference(lastDay).inDays == 1;
  }
}
