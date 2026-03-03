import 'package:hijri/hijri_calendar.dart';
import '../../di/service_locator.dart';
import 'dua_repository.dart';
import 'models/dua_model.dart';

class ContextualDuaService {
  final DuaRepository _repository = getIt<DuaRepository>();

  /// Given the current time, Hijri calendar, and calculated prayer times (if any),
  /// returns the Dua with the highest context score. Returns null if no context matches.
  Future<Dua?> getBestContextualDua({
    required DateTime now,
    required HijriCalendar hijriDate,
    Map<String, DateTime>? todayPrayerTimes,
  }) async {
    final duas = await _repository.getAllDuas();
    if (duas.isEmpty) return null;

    Dua? bestDua;
    int highestScore = -1;
    // Lower priority number = higher priority mathematically
    int bestPriority = 999;

    // Compute the active time window based on current time & prayer times
    final activeTimeWindow = _determineActiveTimeWindow(now, todayPrayerTimes);
    final activeHijriPeriod = _determineActiveHijriPeriod(hijriDate);
    final activeDayOfWeek = _determineDayOfWeek(now);

    for (final dua in duas) {
      if (dua.displayContext == null) continue;
      final ctx = dua.displayContext!;

      int score = 0;

      // 1. Check Time Windows
      if (ctx.timeWindows.isNotEmpty) {
        if (ctx.timeWindows.contains(activeTimeWindow) ||
            ctx.timeWindows.contains('anytime')) {
          score += 10;
        } else {
          // If strictly restricted by time window and we are not in it, skip this dua
          continue;
        }
      }

      // 2. Check Hijri Periods
      if (ctx.hijriPeriods.isNotEmpty) {
        if (activeHijriPeriod != null &&
            ctx.hijriPeriods.contains(activeHijriPeriod)) {
          score += 20; // High weight for specific Islamic periods like Ramadan
        } else {
          // Restricted by period and not in it
          continue;
        }
      }

      // 3. Check Day of Week
      if (ctx.daysOfWeek.isNotEmpty) {
        if (ctx.daysOfWeek.contains(activeDayOfWeek) ||
            ctx.daysOfWeek.contains('any')) {
          score += 5;
        } else {
          continue;
        }
      }

      if (score > 0) {
        // Evaluate against best match
        if (score > highestScore) {
          highestScore = score;
          bestPriority = dua.priority;
          bestDua = dua;
        } else if (score == highestScore) {
          // Tie-breaker: lower priority number wins
          if (dua.priority < bestPriority) {
            bestPriority = dua.priority;
            bestDua = dua;
          }
        }
      }
    }

    return bestDua;
  }

  /// Returns a list of all Duas that match the current context, sorted by score and priority.
  Future<List<Dua>> getContextualDuas({
    required DateTime now,
    required HijriCalendar hijriDate,
    Map<String, DateTime>? todayPrayerTimes,
  }) async {
    final duas = await _repository.getAllDuas();
    if (duas.isEmpty) return [];

    final activeTimeWindow = _determineActiveTimeWindow(now, todayPrayerTimes);
    final activeHijriPeriod = _determineActiveHijriPeriod(hijriDate);
    final activeDayOfWeek = _determineDayOfWeek(now);

    final List<Map<String, dynamic>> scoredDuas = [];

    for (final dua in duas) {
      if (dua.displayContext == null) continue;
      final ctx = dua.displayContext!;

      int score = 0;

      // 1. Check Time Windows
      if (ctx.timeWindows.isNotEmpty) {
        if (ctx.timeWindows.contains(activeTimeWindow) ||
            ctx.timeWindows.contains('anytime')) {
          score += 10;
        } else {
          // If strictly restricted by time window and we are not in it, skip this dua
          continue;
        }
      }

      // 2. Check Hijri Periods
      if (ctx.hijriPeriods.isNotEmpty) {
        if (activeHijriPeriod != null &&
            ctx.hijriPeriods.contains(activeHijriPeriod)) {
          score += 20; // High weight for specific Islamic periods like Ramadan
        } else {
          // Restricted by period and not in it
          continue;
        }
      }

      // 3. Check Day of Week
      if (ctx.daysOfWeek.isNotEmpty) {
        if (ctx.daysOfWeek.contains(activeDayOfWeek) ||
            ctx.daysOfWeek.contains('any')) {
          score += 5;
        } else {
          continue;
        }
      }

      if (score > 0) {
        scoredDuas.add({'dua': dua, 'score': score});
      }
    }

    scoredDuas.sort((a, b) {
      final scoreCompare = (b['score'] as int).compareTo(a['score'] as int);
      if (scoreCompare != 0) return scoreCompare;
      final duaA = a['dua'] as Dua;
      final duaB = b['dua'] as Dua;
      return duaA.priority.compareTo(duaB.priority);
    });

    return scoredDuas.map((e) => e['dua'] as Dua).toList();
  }

  /// Evaluates specific context string to show alongside the Dua (e.g., "Jummah Mubarak...")
  /// This returns a custom string for high-value known contexts.
  String? getContextualMessage(
    Dua dua,
    DateTime now,
    Map<String, DateTime>? prayerTimes,
    HijriCalendar hijriDate,
  ) {
    if (dua.id == 'walking_to_masjid_001' && now.weekday == DateTime.friday) {
      return 'Jummah Mubarak. As you prepare to head to the masjid, remember the dua for walking.';
    }

    final activeHijriPeriod = _determineActiveHijriPeriod(hijriDate);
    if ((dua.id == 'ramadan_iftar_001' || dua.id == 'ramadan_iftar_002') &&
        activeHijriPeriod == 'ramadan') {
      return 'The time for breaking your fast is approaching. The Prophet (PBUH) used to say this dua.';
    }

    // Default or empty for generic contexts
    if (dua.occasion.isNotEmpty) {
      return 'For ${dua.occasion.toLowerCase()}';
    }

    return null;
  }

  String _determineActiveTimeWindow(
    DateTime now,
    Map<String, DateTime>? prayerTimes,
  ) {
    if (prayerTimes == null || prayerTimes.isEmpty) {
      // Fallback if no prayer times available, do basic hour checking
      final hour = now.hour;
      if (hour >= 4 && hour < 8) {
        return 'morning'; // Approximately around Fajr/Sunrise
      }
      if (hour >= 8 && hour < 12) return 'morning';
      if (hour >= 12 && hour < 15) return 'dhuhr';
      if (hour >= 15 && hour < 18) return 'asr';
      if (hour >= 18 && hour < 20) return 'maghrib';
      if (hour >= 20 || hour < 4) return 'night';
      return 'anytime';
    }

    // Advanced window checking using actual prayer times
    final fajr = prayerTimes['Fajr'];
    final dhuhr = prayerTimes['Dhuhr'];
    final asr = prayerTimes['Asr'];
    final maghrib = prayerTimes['Maghrib'];
    final isha = prayerTimes['Isha'];

    // For Jummah prep (approx 1.5 hours before Dhuhr on Friday)
    if (now.weekday == DateTime.friday && dhuhr != null) {
      final diff = dhuhr.difference(now);
      if (diff.inMinutes > 0 && diff.inMinutes <= 90) {
        // 1.5 hours before Jummah
        return 'pre_jummah'; // Synthetic token specific to Friday prayers
      }
    }

    // For Iftar prep (15 - 30 minutes before Maghrib)
    if (maghrib != null) {
      final diff = maghrib.difference(now);
      if (diff.inMinutes > 0 && diff.inMinutes <= 30) {
        return 'pre_maghrib'; // Synthetic token for breaking fast preparation
      }
    }

    // Standard prayer windows
    if (fajr != null &&
        _isBetween(
          now,
          fajr.subtract(const Duration(hours: 1)),
          fajr.add(const Duration(hours: 1)),
        )) {
      return 'fajr';
    }
    if (dhuhr != null &&
        _isBetween(now, dhuhr, asr ?? dhuhr.add(const Duration(hours: 3)))) {
      return 'dhuhr';
    }
    if (asr != null &&
        _isBetween(now, asr, maghrib ?? asr.add(const Duration(hours: 3)))) {
      return 'asr';
    }
    if (maghrib != null &&
        _isBetween(
          now,
          maghrib,
          isha ?? maghrib.add(const Duration(hours: 1, minutes: 30)),
        )) {
      return 'maghrib';
    }
    if (isha != null &&
        _isBetween(now, isha, fajr ?? isha.add(const Duration(hours: 8)))) {
      return 'isha';
    }

    // Night detection (Last third of the night)
    if (fajr != null && maghrib != null && isha != null) {
      // Calculate length of night (Maghrib to next Fajr)
      // Since we only have today's Fajr, we estimate next Fajr is roughly 24 hours after today's Fajr
      final nextFajr = fajr.add(const Duration(days: 1));
      if (now.isAfter(isha) && now.isBefore(nextFajr)) {
        final nightDuration = nextFajr.difference(maghrib);
        final thirdOfNight = Duration(seconds: nightDuration.inSeconds ~/ 3);
        final lastThirdStart = nextFajr.subtract(thirdOfNight);

        if (now.isAfter(lastThirdStart)) {
          return 'last_third_night';
        }
        return 'night';
      }
    }

    // General morning/evening boundaries
    if (now.hour >= 5 && now.hour < 12) return 'morning';
    if (now.hour >= 16 && now.hour < 20) return 'evening';

    return 'anytime';
  }

  bool _isBetween(DateTime time, DateTime start, DateTime end) {
    if (time.isAfter(start) && time.isBefore(end)) return true;
    if (time.isAtSameMomentAs(start) || time.isAtSameMomentAs(end)) return true;
    return false;
  }

  String? _determineActiveHijriPeriod(HijriCalendar date) {
    if (date.hMonth == 9) return 'ramadan';
    if (date.hMonth == 9 && date.hDay >= 21) return 'ramadan_last_ten';
    if (date.hMonth == 12 && date.hDay <= 10) return 'dhul_hijjah_first_ten';
    if (date.hMonth == 1 && date.hDay == 10) return 'ashura';
    if (date.hMonth == 8) return 'shaban';
    if (date.hMonth == 1) return 'muharram';
    return null;
  }

  String _determineDayOfWeek(DateTime date) {
    switch (date.weekday) {
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
}
