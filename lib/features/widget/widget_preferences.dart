import 'package:shared_preferences/shared_preferences.dart';

enum WidgetTheme {
  nightSky, // Default - Dark navy background, gold accent
  oceanBlue, // Deep blue background, teal accent
  forest, // Dark green background, emerald accent
  light, // White background, slate text, navy accent
  pureDark, // True black background, white text, gold accent
}

enum WidgetLayout { compact, detailed, minimal }

class WidgetPreferences {
  static const String _keyTheme = 'widget_theme';
  static const String _keyLayout = 'widget_layout';
  static const String _keyShowNextPrayerOnly = 'widget_show_next_only';
  static const String _keyShowHijriDate = 'widget_show_hijri_date';

  static Future<WidgetTheme> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_keyTheme) ?? 0;
    if (themeIndex >= 0 && themeIndex < WidgetTheme.values.length) {
      return WidgetTheme.values[themeIndex];
    }
    return WidgetTheme.nightSky;
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
      case WidgetTheme.nightSky:
        // Dark navy background, gold accent, soft white text
        return {
          'background': 0xFF0F172A,
          'text': 0xFFF8FAFC, // Soft white
          'textSecondary': 0xFFCBD5E1, // Muted white for secondary text
          'accent': 0xFFD4AF37, // Gold
          'cardBg': 0xFF1E293B, // Slightly lighter navy
        };
      case WidgetTheme.oceanBlue:
        // Deep blue background, teal accent
        return {
          'background': 0xFF1A365D,
          'text': 0xFFF8FAFC,
          'textSecondary': 0xFFCBD5E1,
          'accent': 0xFF38B2AC, // Teal
          'cardBg': 0xFF2C5282,
        };
      case WidgetTheme.forest:
        // Dark green background, emerald accent
        return {
          'background': 0xFF1A4731,
          'text': 0xFFF8FAFC,
          'textSecondary': 0xFFCBD5E1,
          'accent': 0xFF10B981, // Emerald
          'cardBg': 0xFF22543D,
        };
      case WidgetTheme.light:
        // White background, slate text, navy accent
        return {
          'background': 0xFFFFFFFF,
          'text': 0xFF334155, // Slate
          'textSecondary': 0xFF64748B,
          'accent': 0xFF1E293B, // Navy
          'cardBg': 0xFFF1F5F9, // Light gray
        };
      case WidgetTheme.pureDark:
        // True black background, white text, gold accent
        return {
          'background': 0xFF000000,
          'text': 0xFFFFFFFF,
          'textSecondary': 0xFFA1A1AA,
          'accent': 0xFFD4AF37, // Gold
          'cardBg': 0xFF18181B, // Zinc-900
        };
    }
  }

  /// Get theme display name for UI
  static String getThemeName(WidgetTheme theme) {
    switch (theme) {
      case WidgetTheme.nightSky:
        return 'Night Sky';
      case WidgetTheme.oceanBlue:
        return 'Ocean Blue';
      case WidgetTheme.forest:
        return 'Forest';
      case WidgetTheme.light:
        return 'Light';
      case WidgetTheme.pureDark:
        return 'Pure Dark';
    }
  }

  /// Get theme description for UI
  static String getThemeDescription(WidgetTheme theme) {
    switch (theme) {
      case WidgetTheme.nightSky:
        return 'Dark navy with gold accents';
      case WidgetTheme.oceanBlue:
        return 'Deep blue with teal accents';
      case WidgetTheme.forest:
        return 'Dark green with emerald accents';
      case WidgetTheme.light:
        return 'Clean white with navy accents';
      case WidgetTheme.pureDark:
        return 'True black with gold accents';
    }
  }
}
