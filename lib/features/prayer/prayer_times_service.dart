import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PrayerTimesService {
  // Replace with user's actual location and calculation params
  final double latitude;
  final double longitude;
  final int method;
  final int madhab;

  PrayerTimesService({
    this.latitude = 51.5074,
    this.longitude = -0.1278,
    this.method = 2,
    this.madhab = 0,
  }); // Default: London, method 2, Shafi

  String _getCacheKey(DateTime date) {
    return 'prayer_times_${date.year}_${date.month}_${date.day}_${latitude.toStringAsFixed(2)}_${longitude.toStringAsFixed(2)}_$method\_$madhab';
  }

  Future<Map<String, DateTime>> getTodayPrayerTimes({bool forceRefresh = false}) async {
    final now = DateTime.now();
    final cacheKey = _getCacheKey(now);

    // Check cache first unless force refresh
    if (!forceRefresh) {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        try {
          final Map<String, dynamic> cached = json.decode(cachedData);
          final Map<String, DateTime> result = {};
          cached.forEach((name, timestamp) {
            result[name] = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
          });
          return result;
        } catch (e) {
          // Cache corrupted, continue to fetch from network
        }
      }
    }

    // Fetch from network
    final url = Uri.parse(
        'https://api.aladhan.com/v1/timings/${now.millisecondsSinceEpoch ~/ 1000}?latitude=$latitude&longitude=$longitude&method=$method&school=$madhab');

    try {
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Prayer times request timed out. Please check your internet connection.');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final timings = data['data']['timings'];
        final Map<String, DateTime> result = {};
        final Map<String, int> cacheData = {};

        timings.forEach((name, timeStr) {
          // Example: "05:03"
          final timeParts = (timeStr as String).split(":");
          int hour = int.parse(timeParts[0]);
          int minute = int.parse(timeParts[1]);
          final dateTime = DateTime(now.year, now.month, now.day, hour, minute);
          result[name] = dateTime;
          cacheData[name] = dateTime.millisecondsSinceEpoch;
        });

        // Cache the result
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(cacheKey, json.encode(cacheData));

        return result;
      } else {
        throw Exception('Failed to fetch prayer times (Status: ${response.statusCode})');
      }
    } on TimeoutException {
      throw TimeoutException('Prayer times request timed out. Please check your internet connection.');
    } catch (e) {
      throw Exception('Failed to fetch prayer times: $e');
    }
  }

  Future<MapEntry<String, DateTime>> getNextPrayer() async {
    final times = await getTodayPrayerTimes();
    final now = DateTime.now();
    final upcoming = times.entries.where((e) => e.value.isAfter(now)).toList();
    upcoming.sort((a, b) => a.value.compareTo(b.value));
    if (upcoming.isNotEmpty) {
      return upcoming.first;
    } else {
      // If all today's prayers have passed, get tomorrow's Fajr
      final tomorrow = now.add(const Duration(days: 1));
      final url = Uri.parse(
          'https://api.aladhan.com/v1/timings/${tomorrow.millisecondsSinceEpoch ~/ 1000}?latitude=$latitude&longitude=$longitude&method=$method&school=$madhab');

      try {
        final response = await http.get(url).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Prayer times request timed out. Please check your internet connection.');
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final timings = data['data']['timings'];
          final fajrStr = timings['Fajr'] as String;
          final timeParts = fajrStr.split(":");
          int hour = int.parse(timeParts[0]);
          int minute = int.parse(timeParts[1]);
          final fajrTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, hour, minute);
          return MapEntry('Fajr', fajrTime);
        } else {
          throw Exception('Failed to fetch tomorrow\'s Fajr time (Status: ${response.statusCode})');
        }
      } on TimeoutException {
        throw TimeoutException('Prayer times request timed out. Please check your internet connection.');
      } catch (e) {
        throw Exception('Failed to fetch tomorrow\'s Fajr time: $e');
      }
    }
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
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('prayer_times_')) {
        await prefs.remove(key);
      }
    }
  }

  Future<Map<String, DateTime>> refreshPrayerTimes() async {
    return getTodayPrayerTimes(forceRefresh: true);
  }
}
