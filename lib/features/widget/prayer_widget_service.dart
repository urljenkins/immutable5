import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:home_widget/home_widget.dart';
import 'package:http/http.dart' as http;
import 'package:immutable5/services/secure_storage_provider.dart';
import 'package:intl/intl.dart';

import '../prayer/prayer_times_service.dart';
import 'widget_preferences.dart';

class PrayerWidgetService {
  static const String _appGroupId = 'group.immutable5.prayertimes';

  // Main prayers to display on widget
  static const List<String> mainPrayers = [
    'Fajr',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha',
  ];

  /// Update the home screen widget with current prayer times
  static Future<void> updateWidget({
    required double latitude,
    required double longitude,
    required int method,
    required int madhab,
  }) async {
    if (kIsWeb) return;
    try {
      final service = PrayerTimesService(
        latitude: latitude,
        longitude: longitude,
        method: method,
        madhab: madhab,
      );

      final times = await service.getTodayPrayerTimes();
      final nextPrayer = await service.getNextPrayer();
      final now = DateTime.now();
      final timeFormat = DateFormat('HH:mm');

      // Filter to main prayers only
      final mainPrayerTimes = <String, String>{};
      for (final prayer in mainPrayers) {
        if (times.containsKey(prayer)) {
          mainPrayerTimes[prayer] = timeFormat.format(times[prayer]!);
        }
      }

      // Store prayer times data
      await HomeWidget.saveWidgetData<String>(
        'next_prayer_name',
        nextPrayer.key,
      );
      await HomeWidget.saveWidgetData<String>(
        'next_prayer_time',
        timeFormat.format(nextPrayer.value),
      );

      // Store all main prayer times as a JSON-like string
      for (final entry in mainPrayerTimes.entries) {
        await HomeWidget.saveWidgetData<String>(
          'prayer_${entry.key.toLowerCase()}',
          entry.value,
        );
      }

      // Store last update timestamp
      await HomeWidget.saveWidgetData<String>(
        'last_updated',
        DateFormat('dd MMM, HH:mm').format(now),
      );

      // Calculate time remaining for next prayer
      final difference = nextPrayer.value.difference(now);
      final hours = difference.inHours;
      final minutes = difference.inMinutes.remainder(60);
      await HomeWidget.saveWidgetData<String>(
        'time_remaining',
        hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m',
      );

      // Format countdown as HH:MM for widget header
      final countdownHours = hours.toString().padLeft(2, '0');
      final countdownMinutes = minutes.toString().padLeft(2, '0');
      await HomeWidget.saveWidgetData<String>(
        'countdown_formatted',
        '$countdownHours:$countdownMinutes',
      );

      // Get and store location name
      final locationName = await _getLocationName(latitude, longitude);
      await HomeWidget.saveWidgetData<String>('location_name', locationName);

      // Get and store Hijri date
      final hijri = HijriCalendar.now();
      final hijriDate =
          '${hijri.hDay} ${_getHijriMonthName(hijri.hMonth)} ${hijri.hYear}';
      await HomeWidget.saveWidgetData<String>('hijri_date', hijriDate);

      // Store widget theme preferences
      final theme = await WidgetPreferences.getTheme();
      final layout = await WidgetPreferences.getLayout();
      final colors = WidgetPreferences.getThemeColors(theme);

      await HomeWidget.saveWidgetData<int>(
        'theme_background',
        colors['background'],
      );
      await HomeWidget.saveWidgetData<int>('theme_text', colors['text']);
      await HomeWidget.saveWidgetData<int>(
        'theme_text_secondary',
        colors['textSecondary'],
      );
      await HomeWidget.saveWidgetData<int>('theme_accent', colors['accent']);
      await HomeWidget.saveWidgetData<int>('theme_card_bg', colors['cardBg']);
      await HomeWidget.saveWidgetData<int>('theme_index', theme.index);
      await HomeWidget.saveWidgetData<int>('layout_type', layout.index);

      // Update the widget UI
      await HomeWidget.updateWidget(
        androidName: 'PrayerTimesWidgetProvider',
        iOSName: 'PrayerTimesWidget',
      );
    } catch (e) {
      // Store error state
      await HomeWidget.saveWidgetData<String>(
        'error_message',
        'Unable to load prayer times',
      );
      await HomeWidget.updateWidget(
        androidName: 'PrayerTimesWidgetProvider',
        iOSName: 'PrayerTimesWidget',
      );
    }
  }

  /// Get location name from coordinates using reverse geocoding
  static Future<String> _getLocationName(
    double latitude,
    double longitude,
  ) async {
    try {
      // Try to get cached location name first
      final prefs = SecureStorageProvider();
      final cachedLat = await prefs.getDouble('cached_location_lat');
      final cachedLon = await prefs.getDouble('cached_location_lon');
      final cachedName = await prefs.getString('cached_location_name');

      // If coordinates match cached values, return cached name
      if (cachedName != null &&
          cachedLat != null &&
          cachedLon != null &&
          (cachedLat - latitude).abs() < 0.01 &&
          (cachedLon - longitude).abs() < 0.01) {
        return cachedName;
      }

      // Use OpenStreetMap Nominatim for reverse geocoding
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&zoom=10',
      );

      final response = await http
          .get(url, headers: {'User-Agent': 'Immutable5PrayerApp/1.0'})
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] as Map<String, dynamic>?;

        String locationName = 'Unknown Location';

        if (address != null) {
          // Try to get city, town, or village name
          locationName =
              address['city'] as String? ??
              address['town'] as String? ??
              address['village'] as String? ??
              address['municipality'] as String? ??
              address['county'] as String? ??
              address['state'] as String? ??
              'Unknown Location';
        }

        // Cache the result
        await prefs.setDouble('cached_location_lat', latitude);
        await prefs.setDouble('cached_location_lon', longitude);
        await prefs.setString('cached_location_name', locationName);

        return locationName;
      }
    } catch (e) {
      // Fallback to cached name or default
      final prefs = SecureStorageProvider();
      return await prefs.getString('cached_location_name') ??
          'Current Location';
    }
    return 'Current Location';
  }

  /// Get Hijri month name
  static String _getHijriMonthName(int month) {
    const months = [
      'Muharram',
      'Safar',
      'Rabi\' al-Awwal',
      'Rabi\' al-Thani',
      'Jumada al-Ula',
      'Jumada al-Thani',
      'Rajab',
      'Sha\'ban',
      'Ramadan',
      'Shawwal',
      'Dhu al-Qi\'dah',
      'Dhu al-Hijjah',
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return '';
  }

  /// Initialize the widget with app group (iOS requirement)
  static Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId(_appGroupId);
    } catch (e) {
      // Widget not supported on all platforms (e.g. Linux)
    }
    if (kIsWeb) return;
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  /// Get stored location and settings from SharedPreferences
  static Future<Map<String, dynamic>> getStoredSettings() async {
    final prefs = SecureStorageProvider();
    return {
      'latitude': await prefs.getDouble('location_latitude') ?? 51.5074,
      'longitude': await prefs.getDouble('location_longitude') ?? -0.1278,
      'method': await prefs.getInt('calculation_method') ?? 2,
      'madhab': await prefs.getInt('madhab') ?? 0,
    };
  }

  /// Update widget with stored settings
  static Future<void> updateWidgetWithStoredSettings() async {
    if (kIsWeb) return;
    final settings = await getStoredSettings();
    await updateWidget(
      latitude: settings['latitude'] as double,
      longitude: settings['longitude'] as double,
      method: settings['method'] as int,
      madhab: settings['madhab'] as int,
    );
  }

  /// Register background callback for periodic updates
  static Future<void> registerBackgroundCallback() async {
    if (kIsWeb) return;
    await HomeWidget.registerInteractivityCallback(backgroundCallback);
  }

  /// Background callback for widget updates
  @pragma('vm:entry-point')
  static Future<void> backgroundCallback(Uri? uri) async {
    if (kIsWeb) return;
    if (uri?.host == 'updatewidget') {
      await updateWidgetWithStoredSettings();
    }
  }
}
