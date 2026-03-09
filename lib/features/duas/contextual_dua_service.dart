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

    // Compute the active context tokens
    final activeTimeWindows = _determineActiveTimeWindows(
      now,
      todayPrayerTimes,
    );
    final activeHijriPeriods = _determineActiveHijriPeriods(hijriDate);
    final activeDayOfWeek = _determineDayOfWeek(now);
    final seasonalContext = _determineSeasonalContext(now);

    for (final dua in duas) {
      if (dua.displayContext == null) continue;
      final ctx = dua.displayContext!;

      int score = 0;

      // 1. Check Time Windows
      if (ctx.timeWindows.isNotEmpty) {
        bool match = false;
        for (final window in activeTimeWindows) {
          if (ctx.timeWindows.contains(window)) {
            match = true;
            score += 10;
            break;
          }
        }
        if (ctx.timeWindows.contains('anytime')) {
          match = true;
          score += 2;
        }

        if (!match) continue;
      }

      // 2. Check Hijri Periods
      if (ctx.hijriPeriods.isNotEmpty) {
        bool match = false;
        for (final period in activeHijriPeriods) {
          if (ctx.hijriPeriods.contains(period)) {
            match = true;
            score += 25; // High weight for specific Islamic periods
            break;
          }
        }
        if (!match) continue;
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

      // 4. Check Conditions (Seasonal etc)
      if (ctx.conditions.isNotEmpty) {
        if (ctx.conditions.contains(seasonalContext)) {
          score += 8;
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

    final activeTimeWindows = _determineActiveTimeWindows(
      now,
      todayPrayerTimes,
    );
    final activeHijriPeriods = _determineActiveHijriPeriods(hijriDate);
    final activeDayOfWeek = _determineDayOfWeek(now);

    final List<Map<String, dynamic>> scoredDuas = [];

    for (final dua in duas) {
      if (dua.displayContext == null) continue;
      final ctx = dua.displayContext!;

      int score = 0;

      // 1. Check Time Windows
      if (ctx.timeWindows.isNotEmpty) {
        final hasMatch = ctx.timeWindows.any(
          (window) => activeTimeWindows.contains(window) || window == 'anytime',
        );
        if (hasMatch) {
          score += 10;
        } else {
          // If strictly restricted by time window and we are not in it, skip this dua
          continue;
        }
      }

      // 2. Check Hijri Periods
      if (ctx.hijriPeriods.isNotEmpty) {
        final hasMatch = ctx.hijriPeriods.any(
          (period) => activeHijriPeriods.contains(period),
        );
        if (hasMatch) {
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
  String? getContextualMessage(
    Dua dua,
    DateTime now,
    Map<String, DateTime>? prayerTimes,
    HijriCalendar hijriDate,
  ) {
    if (dua.id == 'walking_to_masjid_001' && now.weekday == DateTime.friday) {
      return 'Jummah Mubarak. As you prepare to head to the masjid, remember the dua for walking.';
    }

    final periods = _determineActiveHijriPeriods(hijriDate);
    if (periods.contains('ramadan')) {
      if (dua.id == 'ramadan_iftar_001' || dua.id == 'ramadan_iftar_002') {
        return 'The time for breaking your fast is approaching. The Prophet (PBUH) used to say this dua.';
      }
    }

    if (periods.contains('arafah')) {
      return 'Today is the Day of Arafah, the best day for making dua.';
    }

    if (periods.contains('eid_al_fitr')) {
      return 'Eid Mubarak! On this joyful day, remember to thank Allah.';
    }

    if (periods.contains('eid_al_adha')) {
      return 'Eid Mubarak! On this Day of Sacrifice, remember the legacy of Ibrahim (AS).';
    }

    if (periods.contains('white_days')) {
      return 'These are the "White Days" (13th, 14th, 15th). Fasting today is highly recommended.';
    }

    final windows = _determineActiveTimeWindows(now, prayerTimes);
    if (windows.contains('last_third_night')) {
      return 'The Last Third of the Night: A time when Allah descends to the lowest heaven to answer prayers.';
    }

    // Default or empty for generic contexts
    if (dua.occasion.isNotEmpty) {
      return 'For ${dua.occasion.toLowerCase()}';
    }

    return null;
  }

  List<String> _determineActiveTimeWindows(
    DateTime now,
    Map<String, DateTime>? prayerTimes,
  ) {
    final List<String> windows = ['anytime'];

    // Basic hour-based windows
    final hour = now.hour;
    if (hour >= 5 && hour < 11) windows.add('morning');
    if (hour >= 11 && hour < 15) windows.add('midday');
    if (hour >= 15 && hour < 19) windows.add('evening');
    if (hour >= 19 || hour < 5) windows.add('night');
    if (hour == 0) windows.add('midnight');

    if (prayerTimes == null || prayerTimes.isEmpty) {
      return windows;
    }

    // Advanced window checking using actual prayer times
    final fajr = prayerTimes['Fajr'];
    final sunrise =
        prayerTimes['Sunrise'] ?? fajr?.add(const Duration(minutes: 90));
    final dhuhr = prayerTimes['Dhuhr'];
    final asr = prayerTimes['Asr'];
    final maghrib = prayerTimes['Maghrib'];
    final isha = prayerTimes['Isha'];

    // Pre/Post Sunrise
    if (sunrise != null) {
      if (now.isBefore(sunrise) &&
          now.isAfter(sunrise.subtract(const Duration(minutes: 30)))) {
        windows.add('pre_sunrise');
      }
      if (now.isAfter(sunrise) &&
          now.isBefore(sunrise.add(const Duration(hours: 1)))) {
        windows.add('post_sunrise');
      }
    }

    // For Jummah prep
    if (now.weekday == DateTime.friday && dhuhr != null) {
      final diff = dhuhr.difference(now);
      if (diff.inMinutes > 0 && diff.inMinutes <= 120) {
        windows.add('pre_jummah');
      }
    }

    // For Iftar prep
    if (maghrib != null) {
      final diff = maghrib.difference(now);
      if (diff.inMinutes > 0 && diff.inMinutes <= 45) {
        windows.add('pre_maghrib');
      }
    }

    // Between Maghrib and Isha
    if (maghrib != null &&
        isha != null &&
        now.isAfter(maghrib) &&
        now.isBefore(isha)) {
      windows.add('between_maghrib_isha');
    }

    // Standard prayer windows
    if (fajr != null &&
        _isBetween(
          now,
          fajr.subtract(const Duration(minutes: 30)),
          fajr.add(const Duration(hours: 1)),
        )) {
      windows.add('fajr');
    }
    if (dhuhr != null &&
        _isBetween(now, dhuhr, asr ?? dhuhr.add(const Duration(hours: 3)))) {
      windows.add('dhuhr');
    }
    if (asr != null &&
        _isBetween(now, asr, maghrib ?? asr.add(const Duration(hours: 3)))) {
      windows.add('asr');
    }
    if (maghrib != null &&
        _isBetween(
          now,
          maghrib,
          isha ?? maghrib.add(const Duration(hours: 1, minutes: 30)),
        )) {
      windows.add('maghrib');
    }
    if (isha != null &&
        _isBetween(
          now,
          isha,
          fajr?.add(const Duration(days: 1)) ??
              isha.add(const Duration(hours: 8)),
        )) {
      windows.add('isha');
    }

    // Last third of the night
    if (fajr != null && maghrib != null) {
      final nextFajr = fajr.isBefore(maghrib)
          ? fajr.add(const Duration(days: 1))
          : fajr;
      final nightDuration = nextFajr.difference(maghrib);
      final lastThirdStart = nextFajr.subtract(
        Duration(seconds: nightDuration.inSeconds ~/ 3),
      );

      if (now.isAfter(lastThirdStart) && now.isBefore(nextFajr)) {
        windows.add('last_third_night');
      }
    }

    return windows;
  }

  bool _isBetween(DateTime time, DateTime start, DateTime end) {
    if (time.isAfter(start) && time.isBefore(end)) return true;
    if (time.isAtSameMomentAs(start) || time.isAtSameMomentAs(end)) return true;
    return false;
  }

  List<String> _determineActiveHijriPeriods(HijriCalendar date) {
    final List<String> periods = [];

    // Month-based
    if (date.hMonth == 1) periods.add('muharram');
    if (date.hMonth == 7) periods.add('rajab');
    if (date.hMonth == 8) periods.add('shaban');
    if (date.hMonth == 9) periods.add('ramadan');
    if (date.hMonth == 10) periods.add('shawwal');
    if (date.hMonth == 12) periods.add('dhul_hijjah');

    // Specific days
    if (date.hMonth == 1 && date.hDay == 10) periods.add('ashura');
    if (date.hMonth == 9 && date.hDay >= 21) periods.add('ramadan_last_ten');
    if (date.hMonth == 12 && date.hDay <= 10)
      periods.add('dhul_hijjah_first_ten');
    if (date.hMonth == 12 && date.hDay == 9) periods.add('arafah');
    if (date.hMonth == 10 && date.hDay == 1) periods.add('eid_al_fitr');
    if (date.hMonth == 12 && date.hDay == 10) periods.add('eid_al_adha');

    // White Days (13, 14, 15)
    if (date.hDay >= 13 && date.hDay <= 15) periods.add('white_days');

    return periods;
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

  String _determineSeasonalContext(DateTime now) {
    final month = now.month;
    // Simple Northern Hemisphere seasons
    if (month >= 3 && month <= 5) return 'spring';
    if (month >= 6 && month <= 8) return 'summer';
    if (month >= 9 && month <= 11) return 'autumn';
    return 'winter';
  }
}
