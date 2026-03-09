import 'dart:core';

import 'package:hijri/hijri_calendar.dart';

import 'hadith_repository.dart';
import 'models/hadith.dart';

class ContextualHadithService {
  final HadithRepository _repository;

  ContextualHadithService(this._repository);

  Future<List<Hadith>> getRecommendedHadiths({
    DateTime? now,
    String? prayerTimeWindow, // 'fajr', 'dhuhr', etc.
    List<String> conditions = const [],
  }) async {
    final hadiths = await _repository.getAllHadiths();
    final currentTime = now ?? DateTime.now();
    final hijriDate = HijriCalendar.fromDate(currentTime);

    final String dayOfWeek = _getDayOfWeekString(currentTime.weekday);
    final currentHijriMonth = hijriDate.hMonth;
    final currentHijriDay = hijriDate.hDay;

    final List<String> currentHijriPeriods = _getCurrentHijriPeriods(
      currentHijriMonth,
      currentHijriDay,
    );

    return hadiths.where((hadith) {
      if (hadith.displayContext == null) return false;
      final ctx = hadith.displayContext!;

      // 1. Time windows match
      if (prayerTimeWindow != null &&
          ctx.timeWindows.contains(prayerTimeWindow)) {
        return true;
      }

      // 2. Day of week match
      if (ctx.daysOfWeek.contains(dayOfWeek)) {
        return true;
      }

      // 3. Exact Hijri dates match
      if (ctx.hijriDates.any(
        (d) =>
            d.month == currentHijriMonth &&
            (d.day == currentHijriDay || d.recurring),
      )) {
        return true;
      }

      // 4. Period match (e.g., Ramadan)
      if (ctx.hijriPeriods.any((p) => currentHijriPeriods.contains(p))) {
        return true;
      }

      // 5. Conditions match (e.g., waking)
      if (conditions.isNotEmpty &&
          ctx.conditions.any((c) => conditions.contains(c))) {
        return true;
      }

      return false;
    }).toList()..sort((a, b) => a.priority.compareTo(b.priority));
  }

  String _getDayOfWeekString(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'monday';
      case DateTime.tuesday:
        return 'tuesday';
      case DateTime.wednesday:
        return 'wednesday';
      case DateTime.thursday:
        return 'thursday';
      case DateTime.friday:
        return 'friday';
      case DateTime.saturday:
        return 'saturday';
      case DateTime.sunday:
        return 'sunday';
      default:
        return 'any';
    }
  }

  List<String> _getCurrentHijriPeriods(int month, int day) {
    final periods = <String>[];
    if (month == 9) {
      periods.add('ramadan');
      if (day >= 20) periods.add('ramadan_last_ten');
    }
    if (month == 10) periods.add('shawwal');
    if (month == 12 && day <= 10) periods.add('dhul_hijjah_first_ten');
    if (month == 1 && day == 10) periods.add('ashura');
    if (month == 1) periods.add('muharram');
    if (month == 8) periods.add('shaban');
    return periods;
  }
}
