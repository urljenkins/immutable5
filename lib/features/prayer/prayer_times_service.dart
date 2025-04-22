import 'dart:convert';
import 'package:http/http.dart' as http;

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

  Future<Map<String, DateTime>> getTodayPrayerTimes() async {
    final now = DateTime.now();
    final url = Uri.parse(
        'https://api.aladhan.com/v1/timings/${now.millisecondsSinceEpoch ~/ 1000}?latitude=$latitude&longitude=$longitude&method=$method&school=$madhab');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final timings = data['data']['timings'];
      final Map<String, DateTime> result = {};
      timings.forEach((name, timeStr) {
        // Example: "05:03"
        final timeParts = (timeStr as String).split(":");
        int hour = int.parse(timeParts[0]);
        int minute = int.parse(timeParts[1]);
        result[name] = DateTime(now.year, now.month, now.day, hour, minute);
      });
      return result;
    } else {
      throw Exception('Failed to fetch prayer times');
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
      final response = await http.get(url);
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
        throw Exception('Failed to fetch tomorrow\'s Fajr time');
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
}
