import 'package:shared_preferences/shared_preferences.dart';

enum WidgetTheme {
  light,
  dark,
  greenAccent,
  blueAccent,
}

enum WidgetLayout {
  compact,
  detailed,
  minimal,
}

class WidgetPreferences {
  static const String _keyTheme = 'widget_theme';
  static const String _keyLayout = 'widget_layout';
  static const String _keyShowNextPrayerOnly = 'widget_show_next_only';
  static const String _keyShowHijriDate = 'widget_show_hijri_date';

  static Future<WidgetTheme> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_keyTheme) ?? 0;
    return WidgetTheme.values[themeIndex];
  }

  static Future<void> setTheme(WidgetTheme theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTheme, theme.index);
  }

  static Future<WidgetLayout> getLayout() async {
    final prefs = await SharedPreferences.getInstance();
    final layoutIndex = prefs.getInt(_keyLayout) ?? 1; // Default to detailed
    return WidgetLayout.values[layoutIndex];
  }

  static Future<void> setLayout(WidgetLayout layout) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLayout, layout.index);
  }

  static Future<bool> getShowNextPrayerOnly() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyShowNextPrayerOnly) ?? false;
  }

  static Future<void> setShowNextPrayerOnly(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowNextPrayerOnly, value);
  }

  static Future<bool> getShowHijriDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyShowHijriDate) ?? true;
  }

  static Future<void> setShowHijriDate(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowHijriDate, value);
  }

  static Map<String, dynamic> getThemeColors(WidgetTheme theme) {
    switch (theme) {
      case WidgetTheme.light:
        return {
          'background': 0xFFFFFFFF,
          'text': 0xFF000000,
          'accent': 0xFF2E7D32,
          'cardBg': 0xFFE8F5E9,
        };
      case WidgetTheme.dark:
        return {
          'background': 0xFF000000,
          'text': 0xFFFFFFFF,
          'accent': 0xFF4CAF50,
          'cardBg': 0xFF1B5E20,
        };
      case WidgetTheme.greenAccent:
        return {
          'background': 0xFFF1F8E9,
          'text': 0xFF33691E,
          'accent': 0xFF689F38,
          'cardBg': 0xFFC5E1A5,
        };
      case WidgetTheme.blueAccent:
        return {
          'background': 0xFFE3F2FD,
          'text': 0xFF0D47A1,
          'accent': 0xFF1976D2,
          'cardBg': 0xFF90CAF9,
        };
    }
  }
}
