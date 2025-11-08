import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../prayer/prayer_times_service.dart';
import 'widget_preferences.dart';

class PrayerWidgetService {
  static const String _widgetName = 'PrayerTimesWidget';
  static const String _appGroupId = 'group.immutable5.prayertimes';

  // Main prayers to display on widget
  static const List<String> mainPrayers = [
    'Fajr',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha'
  ];

  /// Update the home screen widget with current prayer times
  static Future<void> updateWidget({
    required double latitude,
    required double longitude,
    required int method,
    required int madhab,
  }) async {
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

      // Store widget theme preferences
      final theme = await WidgetPreferences.getTheme();
      final layout = await WidgetPreferences.getLayout();
      final colors = WidgetPreferences.getThemeColors(theme);

      await HomeWidget.saveWidgetData<int>('theme_background', colors['background']);
      await HomeWidget.saveWidgetData<int>('theme_text', colors['text']);
      await HomeWidget.saveWidgetData<int>('theme_accent', colors['accent']);
      await HomeWidget.saveWidgetData<int>('theme_card_bg', colors['cardBg']);
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

  /// Initialize the widget with app group (iOS requirement)
  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  /// Get stored location and settings from SharedPreferences
  static Future<Map<String, dynamic>> getStoredSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'latitude': prefs.getDouble('location_latitude') ?? 51.5074,
      'longitude': prefs.getDouble('location_longitude') ?? -0.1278,
      'method': prefs.getInt('calculation_method') ?? 2,
      'madhab': prefs.getInt('madhab') ?? 0,
    };
  }

  /// Update widget with stored settings
  static Future<void> updateWidgetWithStoredSettings() async {
    final settings = await getStoredSettings();
    await updateWidget(
      latitude: settings['latitude'],
      longitude: settings['longitude'],
      method: settings['method'],
      madhab: settings['madhab'],
    );
  }

  /// Register background callback for periodic updates
  static Future<void> registerBackgroundCallback() async {
    await HomeWidget.registerBackgroundCallback(backgroundCallback);
  }

  /// Background callback for widget updates
  @pragma('vm:entry-point')
  static Future<void> backgroundCallback(Uri? uri) async {
    if (uri?.host == 'updatewidget') {
      await updateWidgetWithStoredSettings();
    }
  }
}
