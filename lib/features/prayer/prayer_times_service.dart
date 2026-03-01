import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;
import 'package:immutable5/services/secure_storage_provider.dart';

typedef PrayerTimesServiceFactory = PrayerTimesService Function(
  double lat,
  double lon,
  int method,
  int madhab,
);

class PrayerTimesService {
  // Replace with user's actual location and calculation params
  final double latitude;
  final double longitude;
  final int method;
  final int madhab;

  // Cache the next prayer to avoid duplicate API calls
  MapEntry<String, DateTime>? _cachedNextPrayer;
  DateTime? _cacheTimestamp;

  PrayerTimesService({
    this.latitude = 51.5074,
    this.longitude = -0.1278,
    this.method = 2,
    this.madhab = 0,
  }); // Default: London, method 2, Shafi

  String _getCacheKey(DateTime date) {
    return 'prayer_times_${date.year}_${date.month}_${date.day}_${latitude.toStringAsFixed(2)}_${longitude.toStringAsFixed(2)}_${method}_$madhab';
  }

  DateTime _parseTimeString(String timeStr, DateTime date) {
    // Remove any timezone info like "(PKT)" that might be in the string
    final cleanTime = timeStr.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
    final timeParts = cleanTime.split(':');

    if (timeParts.length < 2) {
      throw FormatException('Invalid time format: $timeStr');
    }

    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    // Validate hour and minute
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      throw FormatException('Invalid time values: $hour:$minute');
    }

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  Future<Map<String, DateTime>> getTodayPrayerTimes({
    bool forceRefresh = false,
  }) async {
    return getPrayerTimesForDate(DateTime.now(), forceRefresh: forceRefresh);
  }

  Future<Map<String, DateTime>> getPrayerTimesForDate(
    DateTime date, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = _getCacheKey(date);

    // Check cache first unless force refresh
    if (!forceRefresh) {
      final prefs = SecureStorageProvider();
      final cachedData = await prefs.getString(cacheKey);
      if (cachedData != null) {
        try {
          final Map<String, dynamic> cached = json.decode(cachedData);
          final Map<String, DateTime> result = {};
          cached.forEach((name, timestamp) {
            result[name] = DateTime.fromMillisecondsSinceEpoch(
              timestamp as int,
            );
          });
          return result;
        } catch (e) {
          // Cache corrupted, continue to fetch from network
        }
      }
    }

    // Fetch from network
    final url = Uri.parse(
      'https://api.aladhan.com/v1/timings/${date.millisecondsSinceEpoch ~/ 1000}?latitude=$latitude&longitude=$longitude&method=$method&school=$madhab',
    );

    try {
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
            'Prayer times request timed out. Please check your internet connection.',
          );
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final timings = data['data']['timings'];
        final Map<String, DateTime> result = {};
        final Map<String, int> cacheData = {};

        timings.forEach((name, timeStr) {
          try {
            final dateTime = _parseTimeString(timeStr as String, date);
            result[name] = dateTime;
            cacheData[name] = dateTime.millisecondsSinceEpoch;
          } catch (e) {
            // Skip invalid prayer times
            developer.log(
              'Warning: Could not parse prayer time for $name: $timeStr - $e',
              name: 'PrayerTimesService',
            );
          }
        });

        // Cache the result
        final prefs = SecureStorageProvider();
        await prefs.setString(cacheKey, json.encode(cacheData));

        return result;
      } else {
        throw Exception(
          'Failed to fetch prayer times (Status: ${response.statusCode})',
        );
      }
    } on TimeoutException {
      throw TimeoutException(
        'Prayer times request timed out. Please check your internet connection.',
      );
    } catch (e) {
      throw Exception('Failed to fetch prayer times: $e');
    }
  }

  Future<MapEntry<String, DateTime>> getNextPrayer({
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();

    // Use cached next prayer if it's still valid (within last minute and in the future)
    if (!forceRefresh &&
        _cachedNextPrayer != null &&
        _cacheTimestamp != null &&
        now.difference(_cacheTimestamp!).inSeconds < 60 &&
        _cachedNextPrayer!.value.isAfter(now)) {
      return _cachedNextPrayer!;
    }

    final times = await getTodayPrayerTimes();
    final upcoming = times.entries.where((e) => e.value.isAfter(now)).toList();
    upcoming.sort((a, b) => a.value.compareTo(b.value));
    if (upcoming.isNotEmpty) {
      _cachedNextPrayer = upcoming.first;
      _cacheTimestamp = now;
      return upcoming.first;
    } else {
      // If all today's prayers have passed, get tomorrow's Fajr
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowCacheKey = _getCacheKey(tomorrow);

      // Check tomorrow's cache first
      final prefs = SecureStorageProvider();
      final cachedTomorrowData = await prefs.getString(tomorrowCacheKey);
      if (cachedTomorrowData != null) {
        try {
          final Map<String, dynamic> cached = json.decode(cachedTomorrowData);
          if (cached.containsKey('Fajr')) {
            final fajrTime = DateTime.fromMillisecondsSinceEpoch(
              cached['Fajr'] as int,
            );
            final entry = MapEntry('Fajr', fajrTime);
            _cachedNextPrayer = entry;
            _cacheTimestamp = now;
            return entry;
          }
        } catch (e) {
          // Cache corrupted, fetch from network
        }
      }

      // Fetch tomorrow's prayer times from network
      final url = Uri.parse(
        'https://api.aladhan.com/v1/timings/${tomorrow.millisecondsSinceEpoch ~/ 1000}?latitude=$latitude&longitude=$longitude&method=$method&school=$madhab',
      );

      try {
        final response = await http.get(url).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException(
              'Prayer times request timed out. Please check your internet connection.',
            );
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final timings = data['data']['timings'];

          // Cache all of tomorrow's prayer times while we're at it
          final Map<String, int> tomorrowCacheData = {};
          timings.forEach((name, timeStr) {
            try {
              final dateTime = _parseTimeString(timeStr as String, tomorrow);
              tomorrowCacheData[name] = dateTime.millisecondsSinceEpoch;
            } catch (e) {
              developer.log(
                'Warning: Could not parse tomorrow\'s prayer time for $name: $timeStr - $e',
                name: 'PrayerTimesService',
              );
            }
          });
          await prefs.setString(
            tomorrowCacheKey,
            json.encode(tomorrowCacheData),
          );

          if (tomorrowCacheData.containsKey('Fajr')) {
            final fajrTime = DateTime.fromMillisecondsSinceEpoch(
              tomorrowCacheData['Fajr']!,
            );
            final entry = MapEntry('Fajr', fajrTime);
            _cachedNextPrayer = entry;
            _cacheTimestamp = now;
            return entry;
          } else {
            throw Exception('Fajr time not found in tomorrow\'s prayer times');
          }
        } else {
          throw Exception(
            'Failed to fetch tomorrow\'s prayer times (Status: ${response.statusCode})',
          );
        }
      } on TimeoutException {
        throw TimeoutException(
          'Prayer times request timed out. Please check your internet connection.',
        );
      } catch (e) {
        throw Exception('Failed to fetch tomorrow\'s prayer times: $e');
      }
    }
  }

  Future<MapEntry<String, DateTime>> getPastPrayer({
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();

    final times = await getTodayPrayerTimes();
    final past = times.entries.where((e) => e.value.isBefore(now)).toList();
    past.sort((a, b) => b.value.compareTo(a.value)); // Descending order
    if (past.isNotEmpty) {
      return past.first;
    } else {
      // If no prayers today have passed (e.g. before Fajr), it must be Isha from yesterday
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayTimes = await getPrayerTimesForDate(yesterday);
      if (yesterdayTimes.containsKey('Isha')) {
        return MapEntry('Isha', yesterdayTimes['Isha']!);
      } else {
        // Fallback if missing
        return MapEntry('Isha', DateTime.fromMillisecondsSinceEpoch(0));
      }
    }
  }

  Future<DateTime> getPastPrayerTime() async {
    final entry = await getPastPrayer();
    return entry.value;
  }

  Future<String> getPastPrayerName() async {
    final entry = await getPastPrayer();
    return entry.key;
  }

  Future<DateTime> getNextPrayerTime() async {
    final entry = await getNextPrayer();
    return entry.value;
  }

  Future<String> getNextPrayerName() async {
    final entry = await getNextPrayer();
    return entry.key;
  }

  Future<void> clearCache() async {
    final prefs = SecureStorageProvider();
    final keys = await prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('prayer_times_')) {
        await prefs.remove(key);
      }
    }
  }

  Future<Map<String, DateTime>> refreshPrayerTimes() async {
    _cachedNextPrayer = null;
    _cacheTimestamp = null;
    return getTodayPrayerTimes(forceRefresh: true);
  }
}
