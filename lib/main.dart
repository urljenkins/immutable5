import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'features/prayer_tracking/prayer_stats_page.dart';
import 'features/notifications/notification_service.dart';
import 'features/widget/prayer_widget_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/settings/settings_page.dart';
import 'features/quran/quran_page.dart';
import 'features/qibla/qibla_page.dart';
import 'features/calendar/calendar_page.dart';
import 'features/hajj/hajj_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'generated/app_localizations.dart';
import 'features/common_words/common_words_page.dart';
import 'features/duas/duas_page.dart';
import 'features/home/home_page.dart';
import 'features/places/places_page.dart';
import 'di/service_locator.dart';
import 'shared/app_colors.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);
final ValueNotifier<Color> accentColorNotifier =
    ValueNotifier(AppColors.accent);
final ValueNotifier<BottomNavVisibility> bottomNavVisibilityNotifier =
    ValueNotifier(const BottomNavVisibility());
const String _keyAccentColor = 'accent_color';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  setupLocator();

  // Initialize notification service
  await NotificationService().initialize();

  // Initialize widget service
  await PrayerWidgetService.initialize();

  final prefs = await SharedPreferences.getInstance();
  final useDark = prefs.getBool('useAmoledTheme') ?? true;
  themeNotifier.value = useDark ? ThemeMode.dark : ThemeMode.light;

  final accentValue = prefs.getInt(_keyAccentColor);
  if (accentValue != null) {
    AppColors.accent = Color(accentValue);
    accentColorNotifier.value = AppColors.accent;
  }

  bottomNavVisibilityNotifier.value = BottomNavVisibility.fromPrefs(prefs);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return ValueListenableBuilder<Color>(
          valueListenable: accentColorNotifier,
          builder: (_, accentColor, __) {
            // Define base text theme with Plus Jakarta Sans
            final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

            return MaterialApp(
              onGenerateTitle: (context) =>
                  AppLocalizations.of(context)!.appTitle,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: accentColor,
                  primary: accentColor,
                  surface: AppColors.textPrimary, // Light theme surface
                ),
                useMaterial3: true,
                textTheme: baseTextTheme,
                appBarTheme: const AppBarTheme(
                  elevation: 0,
                  centerTitle: true,
                  backgroundColor: Colors.transparent,
                ),
              ),
              darkTheme: ThemeData.dark().copyWith(
                scaffoldBackgroundColor: AppColors.background,
                colorScheme: ColorScheme.dark(
                  primary: accentColor,
                  surface: AppColors
                      .background, // Using background color for main surface
                  onSurface: AppColors.textPrimary,
                ),
                textTheme: baseTextTheme.apply(
                  bodyColor: AppColors.textPrimary,
                  displayColor: AppColors.textPrimary,
                ),
                appBarTheme: const AppBarTheme(
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  centerTitle: true,
                ),
                // Remove default divider colors
                dividerTheme: DividerThemeData(
                  color: AppColors.textPrimary.withValues(alpha: 0.1),
                ),
              ),
              themeMode: mode,
              home: const AppScaffold(),
            );
          },
        );
      },
    );
  }
}

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: accentColorNotifier,
      builder: (_, accentColor, __) {
        return ValueListenableBuilder<BottomNavVisibility>(
          valueListenable: bottomNavVisibilityNotifier,
          builder: (_, visibility, __) {
            final navItems = _buildNavItems(context, visibility);
            final currentIndex =
                _currentIndex >= navItems.length ? 0 : _currentIndex;

            return Scaffold(
              extendBody: true, // Allows body to go behind the nav bar
              body: navItems[currentIndex].page,
              bottomNavigationBar: SafeArea(
                bottom: true,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: navItems.map((item) {
                            final index = navItems.indexOf(item);
                            final isSelected = index == _currentIndex;

                            return GestureDetector(
                              onTap: () {
                                setState(() => _currentIndex = index);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? accentColor.withValues(alpha: 0.2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  item.item.icon is Icon
                                      ? (item.item.icon as Icon).icon
                                      : Icons.circle,
                                  color: isSelected
                                      ? accentColor
                                      : AppColors.textSecondary,
                                  size: 24,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<_NavItem> _buildNavItems(
      BuildContext context, BottomNavVisibility visibility) {
    final items = <_NavItem>[
      _NavItem(
        page: const MyHomePage(title: 'Immutable5'),
        item: BottomNavigationBarItem(
          icon: const Icon(Icons.home),
          label: AppLocalizations.of(context)!.home,
        ),
      ),
    ];

    if (visibility.showTrack) {
      items.add(
        _NavItem(
          page: const PrayerStatsPage(),
          item: const BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: 'Track',
          ),
        ),
      );
    }

    if (visibility.showPlaces) {
      items.add(
        _NavItem(
          page: const PlacesPage(),
          item: BottomNavigationBarItem(
            icon: const Icon(Icons.map),
            label: AppLocalizations.of(context)!.places,
          ),
        ),
      );
    }

    if (visibility.showQibla) {
      items.add(
        _NavItem(
          page: const QiblaPage(),
          item: const BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Qibla',
          ),
        ),
      );
    }

    if (visibility.showCalendar) {
      items.add(
        _NavItem(
          page: const CalendarPage(),
          item: BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_today),
            label: AppLocalizations.of(context)!.calendar,
          ),
        ),
      );
    }

    if (visibility.showHajj) {
      items.add(
        _NavItem(
          page: const HajjPage(),
          item: BottomNavigationBarItem(
            icon: const Icon(Icons.directions_walk),
            label: AppLocalizations.of(context)!.hajj,
          ),
        ),
      );
    }

    if (visibility.showCommonWords) {
      items.add(
        _NavItem(
          page: const CommonWordsPage(),
          item: BottomNavigationBarItem(
            icon: const Icon(Icons.translate),
            label: AppLocalizations.of(context)!.commonWords,
          ),
        ),
      );
    }

    if (visibility.showDuas) {
      items.add(
        _NavItem(
          page: const DuasPage(),
          item: const BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Duas',
          ),
        ),
      );
    }

    if (visibility.showQuran) {
      items.add(
        _NavItem(
          page: const QuranPage(),
          item: BottomNavigationBarItem(
            icon: const Icon(Icons.book),
            label: AppLocalizations.of(context)!.quran,
          ),
        ),
      );
    }

    items.add(
      _NavItem(
        page: const SettingsPage(),
        item: BottomNavigationBarItem(
          icon: const Icon(Icons.settings),
          label: AppLocalizations.of(context)!.settings,
        ),
      ),
    );

    return items;
  }
}

class _NavItem {
  final Widget page;
  final BottomNavigationBarItem item;
  const _NavItem({required this.page, required this.item});
}

class BottomNavVisibility {
  final bool showTrack;
  final bool showQibla;
  final bool showPlaces;
  final bool showCalendar;
  final bool showHajj;
  final bool showCommonWords;
  final bool showDuas;
  final bool showQuran;

  const BottomNavVisibility({
    this.showTrack = true,
    this.showQibla = true,
    this.showPlaces = true,
    this.showCalendar = true,
    this.showHajj = true,
    this.showCommonWords = true,
    this.showDuas = true,
    this.showQuran = true,
  });

  static const _keyTrack = 'nav_show_track';
  static const _keyQibla = 'nav_show_qibla';
  static const _keyPlaces = 'nav_show_places';
  static const _keyCalendar = 'nav_show_calendar';
  static const _keyHajj = 'nav_show_hajj';
  static const _keyCommonWords = 'nav_show_common_words';
  static const _keyDuas = 'nav_show_duas';
  static const _keyQuran = 'nav_show_quran';

  factory BottomNavVisibility.fromPrefs(SharedPreferences prefs) {
    return BottomNavVisibility(
      showTrack: prefs.getBool(_keyTrack) ?? true,
      showQibla: prefs.getBool(_keyQibla) ?? true,
      showPlaces: prefs.getBool(_keyPlaces) ?? true,
      showCalendar: prefs.getBool(_keyCalendar) ?? true,
      showHajj: prefs.getBool(_keyHajj) ?? true,
      showCommonWords: prefs.getBool(_keyCommonWords) ?? true,
      showDuas: prefs.getBool(_keyDuas) ?? true,
      showQuran: prefs.getBool(_keyQuran) ?? true,
    );
  }

  BottomNavVisibility copyWith({
    bool? showTrack,
    bool? showQibla,
    bool? showPlaces,
    bool? showCalendar,
    bool? showHajj,
    bool? showCommonWords,
    bool? showDuas,
    bool? showQuran,
  }) {
    return BottomNavVisibility(
      showTrack: showTrack ?? this.showTrack,
      showQibla: showQibla ?? this.showQibla,
      showPlaces: showPlaces ?? this.showPlaces,
      showCalendar: showCalendar ?? this.showCalendar,
      showHajj: showHajj ?? this.showHajj,
      showCommonWords: showCommonWords ?? this.showCommonWords,
      showDuas: showDuas ?? this.showDuas,
      showQuran: showQuran ?? this.showQuran,
    );
  }

  Future<void> save(SharedPreferences prefs) async {
    await prefs.setBool(_keyTrack, showTrack);
    await prefs.setBool(_keyQibla, showQibla);
    await prefs.setBool(_keyPlaces, showPlaces);
    await prefs.setBool(_keyCalendar, showCalendar);
    await prefs.setBool(_keyHajj, showHajj);
    await prefs.setBool(_keyCommonWords, showCommonWords);
    await prefs.setBool(_keyDuas, showDuas);
    await prefs.setBool(_keyQuran, showQuran);
  }
}
