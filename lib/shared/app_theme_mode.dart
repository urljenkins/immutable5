enum AppThemeMode {
  light,
  dark,
  amoled;

  String get displayName {
    switch (this) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.amoled:
        return 'AMOLED Black';
    }
  }
}
