import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:immutable5/services/secure_storage_provider.dart';

import 'di/service_locator.dart';
import 'features/common_words/common_words_page.dart';
import 'features/duas/duas_page.dart';
import 'features/hadith/hadiths_page.dart';
import 'features/hajj/hajj_page.dart';
import 'features/home/home_page.dart';
import 'features/notifications/notification_service.dart';
import 'features/places/places_page.dart';
import 'features/prayer_tracking/prayer_stats_page.dart';
import 'features/qibla/qibla_page.dart';
import 'features/quran/quran_page.dart';
import 'features/settings/settings_page.dart';
import 'features/tasbih/tasbih_page.dart';
import 'features/widget/prayer_widget_service.dart';
import 'l10n/app_localizations.dart';
import 'shared/app_colors.dart';
import 'shared/app_theme_mode.dart';

final ValueNotifier<AppThemeMode> themeNotifier =
    ValueNotifier(AppThemeMode.dark);
final ValueNotifier<Color> accentColorNotifier = ValueNotifier(
  AppColors.accent,
);
final ValueNotifier<NavBarConfig> navBarConfigNotifier =
    ValueNotifier(NavBarConfig.defaultConfig());
const String _keyAccentColor = 'accent_color';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    setupLocator();

    if (!kIsWeb) {
      // Initialize notification service - only on mobile
      await NotificationService().initialize();

      // Initialize widget service - only on mobile
      await PrayerWidgetService.initialize();
    }

    final prefs = SecureStorageProvider();

    final themeModeStr = await prefs.getString('appThemeMode');
    AppThemeMode initialMode = AppThemeMode.dark;
    if (themeModeStr != null) {
      initialMode = AppThemeMode.values.firstWhere(
        (e) => e.name == themeModeStr,
        orElse: () => AppThemeMode.dark,
      );
    } else {
      // Fallback for previous users
      final useDark = await prefs.getBool('useAmoledTheme') ?? true;
      initialMode = useDark ? AppThemeMode.dark : AppThemeMode.light;
    }
    themeNotifier.value = initialMode;

    final accentValue = await prefs.getInt(_keyAccentColor);
    if (accentValue != null) {
      AppColors.accent = Color(accentValue);
      accentColorNotifier.value = AppColors.accent;
    }

    navBarConfigNotifier.value = await NavBarConfig.fromPrefs(prefs);
  } catch (e) {
    debugPrint('Error during initialization: $e');
  } finally {
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, appMode, __) {
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
                scaffoldBackgroundColor: appMode == AppThemeMode.amoled
                    ? Colors.black
                    : AppColors.background,
                colorScheme: ColorScheme.dark(
                  primary: accentColor,
                  surface: appMode == AppThemeMode.amoled
                      ? Colors.black
                      : AppColors
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
              themeMode: appMode == AppThemeMode.light
                  ? ThemeMode.light
                  : ThemeMode.dark,
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

  /// When a user selects an overflow item we store its id so the body
  /// shows that page even though it doesn't have an icon in the bar.
  String? _overflowSelectedId;

  /// Tracks the last time the back button was pressed while on the home tab,
  /// so we can implement "press back again to exit".
  DateTime? _lastBackPress;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: accentColorNotifier,
      builder: (_, accentColor, __) {
        return ValueListenableBuilder<NavBarConfig>(
          valueListenable: navBarConfigNotifier,
          builder: (_, config, __) {
            final allItems = _buildAllNavItems(context);

            // Ordered visible items based on config
            final visibleIds = config.visibleTabIds;
            final visibleItems = <_NavItem>[];
            for (final id in visibleIds) {
              final match = allItems.where((i) => i.id == id);
              if (match.isNotEmpty) visibleItems.add(match.first);
            }

            // Split into bar items and overflow items
            final maxVisible = config.maxVisibleTabs;
            final barItems = visibleItems.length <= maxVisible
                ? visibleItems
                : visibleItems.sublist(0, maxVisible);
            final overflowItems = visibleItems.length > maxVisible
                ? visibleItems.sublist(maxVisible)
                : <_NavItem>[];

            // Determine the currently shown page
            Widget currentPage;
            if (_overflowSelectedId != null) {
              final match = allItems.where((i) => i.id == _overflowSelectedId);
              currentPage =
                  match.isNotEmpty ? match.first.page : barItems[0].page;
            } else {
              final safeIndex =
                  _currentIndex >= barItems.length ? 0 : _currentIndex;
              currentPage = barItems[safeIndex].page;
            }

            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) {
                if (didPop) return;

                // If we're on an overflow page, go to home first.
                if (_overflowSelectedId != null) {
                  setState(() {
                    _overflowSelectedId = null;
                    _currentIndex = 0;
                  });
                  return;
                }

                // If we're not on the home tab, switch to home.
                if (_currentIndex != 0) {
                  setState(() {
                    _currentIndex = 0;
                  });
                  return;
                }

                // We're on the home tab — check for double-press.
                final now = DateTime.now();
                if (_lastBackPress != null &&
                    now.difference(_lastBackPress!) <
                        const Duration(seconds: 2)) {
                  SystemNavigator.pop();
                  return;
                }
                _lastBackPress = now;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Press back again to exit'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: ColoredBox(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Scaffold(
                      extendBody: true,
                      backgroundColor: Colors.transparent,
                      body: currentPage,
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
                                  vertical: 12,
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.cardSurface
                                      .withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    // Bar items
                                    ...barItems.map((item) {
                                      final index = barItems.indexOf(item);
                                      final isSelected =
                                          _overflowSelectedId == null &&
                                              index == _currentIndex;

                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _currentIndex = index;
                                            _overflowSelectedId = null;
                                          });
                                        },
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? accentColor.withValues(
                                                    alpha: 0.2,
                                                  )
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                item.icon,
                                                color: isSelected
                                                    ? accentColor
                                                    : AppColors.textSecondary,
                                                size: 24,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                item.label,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: isSelected
                                                      ? FontWeight.w600
                                                      : FontWeight.normal,
                                                  color: isSelected
                                                      ? accentColor
                                                      : AppColors.textSecondary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                    // Overflow "More" button
                                    if (overflowItems.isNotEmpty)
                                      GestureDetector(
                                        onTap: () => _showOverflowSheet(
                                          context,
                                          overflowItems,
                                          accentColor,
                                        ),
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _overflowSelectedId != null
                                                ? accentColor.withValues(
                                                    alpha: 0.2,
                                                  )
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.more_horiz,
                                                color: _overflowSelectedId !=
                                                        null
                                                    ? accentColor
                                                    : AppColors.textSecondary,
                                                size: 24,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'More',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight:
                                                      _overflowSelectedId !=
                                                              null
                                                          ? FontWeight.w600
                                                          : FontWeight.normal,
                                                  color: _overflowSelectedId !=
                                                          null
                                                      ? accentColor
                                                      : AppColors.textSecondary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
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

  void _showOverflowSheet(
    BuildContext context,
    List<_NavItem> overflowItems,
    Color accentColor,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ...overflowItems.map((item) {
                final isSelected = _overflowSelectedId == item.id;
                return ListTile(
                  leading: Icon(
                    item.icon,
                    color: isSelected ? accentColor : AppColors.textSecondary,
                  ),
                  title: Text(
                    item.label,
                    style: TextStyle(
                      color: isSelected ? accentColor : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _overflowSelectedId = item.id;
                    });
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  /// Returns ALL possible nav items in a canonical order.
  /// The NavBarConfig determines which are visible and in what order.
  List<_NavItem> _buildAllNavItems(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      _NavItem(
        id: 'home',
        page: const MyHomePage(title: 'Immutable5'),
        icon: Icons.home,
        label: l10n.home,
      ),
      const _NavItem(
        id: 'track',
        page: PrayerStatsPage(),
        icon: Icons.check_circle,
        label: 'Track',
      ),
      _NavItem(
        id: 'places',
        page: const PlacesPage(),
        icon: Icons.map,
        label: l10n.places,
      ),
      const _NavItem(
        id: 'qibla',
        page: QiblaPage(),
        icon: Icons.explore,
        label: 'Qibla',
      ),
      _NavItem(
        id: 'hajj',
        page: const HajjPage(),
        icon: Icons.directions_walk,
        label: l10n.hajj,
      ),
      _NavItem(
        id: 'common_words',
        page: const CommonWordsPage(),
        icon: Icons.translate,
        label: l10n.commonWords,
      ),
      _NavItem(
        id: 'tasbih',
        page: const TasbihPage(),
        icon: Icons.fingerprint,
        label: l10n.tasbih,
      ),
      const _NavItem(
        id: 'duas',
        page: DuasPage(),
        icon: Icons.menu_book,
        label: 'Duas',
      ),
      const _NavItem(
        id: 'hadiths',
        page: HadithsPage(),
        icon: Icons.library_books,
        label: 'Hadiths',
      ),
      _NavItem(
        id: 'quran',
        page: const QuranPage(),
        icon: Icons.book,
        label: l10n.quran,
      ),
      _NavItem(
        id: 'settings',
        page: const SettingsPage(),
        icon: Icons.settings,
        label: l10n.settings,
      ),
    ];
  }
}

class _NavItem {
  final String id;
  final Widget page;
  final IconData icon;
  final String label;
  const _NavItem({
    required this.id,
    required this.page,
    required this.icon,
    required this.label,
  });
}

// ─── Navigation Bar Configuration ────────────────────────────────────────────

/// Represents a single tab entry in the navigation bar configuration.
class NavTabEntry {
  final String id;
  final bool visible;

  const NavTabEntry({required this.id, this.visible = true});

  Map<String, dynamic> toJson() => {'id': id, 'visible': visible};

  factory NavTabEntry.fromJson(Map<String, dynamic> json) => NavTabEntry(
        id: json['id'] as String,
        visible: json['visible'] as bool? ?? true,
      );

  NavTabEntry copyWith({bool? visible}) =>
      NavTabEntry(id: id, visible: visible ?? this.visible);
}

/// Full configuration for the bottom navigation bar: ordered tabs,
/// visibility flags, and a maximum number of icons to show in the bar.
class NavBarConfig {
  final List<NavTabEntry> tabs;
  final int maxVisibleTabs;

  static const String _storageKey = 'nav_bar_config';

  /// All known tab IDs in their default order.
  static const List<String> allTabIds = [
    'home',
    'track',
    'places',
    'qibla',
    'hajj',
    'common_words',
    'tasbih',
    'duas',
    'hadiths',
    'quran',
    'settings',
  ];

  /// IDs that cannot be hidden or reordered away.
  static const Set<String> pinnedIds = {'home', 'settings'};

  const NavBarConfig({required this.tabs, this.maxVisibleTabs = 5});

  /// Default config with all tabs visible in canonical order.
  factory NavBarConfig.defaultConfig() => NavBarConfig(
        tabs: allTabIds.map((id) => NavTabEntry(id: id)).toList(),
      );

  /// Ordered list of visible tab IDs.
  List<String> get visibleTabIds =>
      tabs.where((t) => t.visible).map((t) => t.id).toList();

  /// Tabs that show as icons in the bar.
  List<String> get barTabIds {
    final vis = visibleTabIds;
    return vis.length <= maxVisibleTabs ? vis : vis.sublist(0, maxVisibleTabs);
  }

  /// Tabs that go into the overflow menu.
  List<String> get overflowTabIds {
    final vis = visibleTabIds;
    return vis.length > maxVisibleTabs ? vis.sublist(maxVisibleTabs) : [];
  }

  // ── Persistence ────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'tabs': tabs.map((t) => t.toJson()).toList(),
        'maxVisibleTabs': maxVisibleTabs,
      };

  factory NavBarConfig.fromJson(Map<String, dynamic> json) {
    final tabsList = (json['tabs'] as List)
        .map((e) => NavTabEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    // Ensure any new tabs that may have been added in an update are present.
    for (final id in allTabIds) {
      if (!tabsList.any((t) => t.id == id)) {
        tabsList.add(NavTabEntry(id: id));
      }
    }
    // Remove stale tabs that no longer exist (e.g. 'calendar' removed in this update).
    tabsList.removeWhere((t) => !allTabIds.contains(t.id));
    return NavBarConfig(
      tabs: tabsList,
      maxVisibleTabs: json['maxVisibleTabs'] as int? ?? 5,
    );
  }

  static Future<NavBarConfig> fromPrefs(SecureStorageProvider prefs) async {
    final raw = await prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        return NavBarConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        // Corrupt data — fall through to default.
      }
    }
    return NavBarConfig.defaultConfig();
  }

  Future<void> save(SecureStorageProvider prefs) async {
    await prefs.setString(_storageKey, jsonEncode(toJson()));
  }

  NavBarConfig copyWith({List<NavTabEntry>? tabs, int? maxVisibleTabs}) =>
      NavBarConfig(
        tabs: tabs ?? this.tabs,
        maxVisibleTabs: maxVisibleTabs ?? this.maxVisibleTabs,
      );
}
