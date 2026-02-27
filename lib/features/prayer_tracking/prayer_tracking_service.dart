import 'package:shared_preferences/shared_preferences.dart';

class PrayerTrackingService {
  static final PrayerTrackingService _instance =
      PrayerTrackingService._internal();
  factory PrayerTrackingService() => _instance;
  PrayerTrackingService._internal();

  final List<String> mainPrayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  /// Mark a prayer as completed for a specific date
  Future<void> markPrayerCompleted(String prayerName, DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getPrayerKey(prayerName, date);
    await prefs.setBool(key, true);
    await prefs.setInt(
      '${key}_timestamp',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Check if a prayer is completed for a specific date
  Future<bool> isPrayerCompleted(String prayerName, DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getPrayerKey(prayerName, date);
    return prefs.getBool(key) ?? false;
  }

  /// Get all completed prayers for a specific date
  Future<Map<String, bool>> getCompletedPrayersForDate(DateTime date) async {
    final Map<String, bool> completions = {};
    for (final prayer in mainPrayers) {
      completions[prayer] = await isPrayerCompleted(prayer, date);
    }
    return completions;
  }

  /// Get completion percentage for today
  Future<double> getTodayCompletionPercentage() async {
    final completions = await getCompletedPrayersForDate(DateTime.now());
    final completed = completions.values.where((v) => v).length;
    return completed / mainPrayers.length;
  }

  /// Get current prayer streak (consecutive days with all prayers completed)
  Future<int> getCurrentStreak() async {
    int streak = 0;
    DateTime date = DateTime.now().subtract(
      const Duration(days: 1),
    ); // Start from yesterday

    while (true) {
      final completions = await getCompletedPrayersForDate(date);
      final allCompleted = completions.values.every((v) => v);

      if (!allCompleted) break;

      streak++;
      date = date.subtract(const Duration(days: 1));

      // Limit to checking last 365 days
      if (streak >= 365) break;
    }

    return streak;
  }

  /// Get longest streak ever
  Future<int> getLongestStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('longest_streak') ?? 0;
  }

  /// Update longest streak if current is higher
  Future<void> updateLongestStreak(int currentStreak) async {
    final longest = await getLongestStreak();
    if (currentStreak > longest) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('longest_streak', currentStreak);
    }
  }

  /// Get total prayers completed
  Future<int> getTotalPrayersCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    return keys
        .where(
          (k) =>
              k.startsWith('prayer_') &&
              k.endsWith('_completed') &&
              prefs.getBool(k) == true,
        )
        .length;
  }

  /// Get prayers completed in last 30 days
  Future<Map<DateTime, Map<String, bool>>> getLast30DaysHistory() async {
    final Map<DateTime, Map<String, bool>> history = {};
    final now = DateTime.now();

    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      history[date] = await getCompletedPrayersForDate(date);
    }

    return history;
  }

  /// Get statistics for display
  Future<Map<String, dynamic>> getStatistics() async {
    final todayCompletion = await getTodayCompletionPercentage();
    final currentStreak = await getCurrentStreak();
    final longestStreak = await getLongestStreak();
    final totalPrayers = await getTotalPrayersCompleted();

    return {
      'todayCompletion': todayCompletion,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalPrayers': totalPrayers,
    };
  }

  String _getPrayerKey(String prayerName, DateTime date) {
    return 'prayer_${prayerName}_${date.year}_${date.month}_${date.day}_completed';
  }

  /// Toggle prayer completion status
  Future<void> togglePrayerCompletion(String prayerName, DateTime date) async {
    final isCompleted = await isPrayerCompleted(prayerName, date);

    if (isCompleted) {
      // Unmark
      final prefs = await SharedPreferences.getInstance();
      final key = _getPrayerKey(prayerName, date);
      await prefs.remove(key);
      await prefs.remove('${key}_timestamp');
    } else {
      // Mark as completed
      await markPrayerCompleted(prayerName, date);

      // Update streak if today is complete
      if (_isSameDay(date, DateTime.now())) {
        final completions = await getCompletedPrayersForDate(date);
        final allComplete = completions.values.every((v) => v);
        if (allComplete) {
          final streak = await getCurrentStreak() + 1; // +1 for today
          await updateLongestStreak(streak);
        }
      }
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
