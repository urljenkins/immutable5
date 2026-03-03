import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:immutable5/services/secure_storage_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../services/battery_optimizer.dart';
import '../../services/cache_manager.dart';
import '../../shared/app_colors.dart';
import '../notifications/notification_service.dart';
import '../quran/juz_of_the_day_service.dart';
import '../quran/quran_context_menu_settings.dart';
import '../widget/widget_settings_page.dart';
import '../../shared/app_theme_mode.dart';
import 'nav_bar_customization_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const _keyCalculationMethod = 'calculationMethod';
  static const _keyMadhab = 'madhab';
  static const _keyNotificationsEnabled = 'notificationsEnabled';
  static const _keyAppThemeMode = 'appThemeMode';
  static const _keyAccentColor = 'accent_color';
  static const _keyJummahReminders = 'jummahReminders';
  static const _keyIftarReminders = 'iftarReminders';
  static const _keyJuzMode = 'juzMode';
  static const List<String> _methods = [
    'Method 2 (University of Islamic Sciences)',
    'Method 4 (Islamic Society of North America)',
  ];
  static const List<String> _madhabs = ['Shafi', 'Hanafi', 'Maliki', 'Hanbali'];
  String _calculationMethod = _methods[0];
  String _madhab = 'Shafi';
  bool _notificationsEnabled = true;
  AppThemeMode _appThemeMode = AppThemeMode.dark;
  bool _jummahReminders = true;
  bool _iftarReminders = true;
  bool _batterySaverMode = false;
  bool _showPastPrayer = false;
  JuzMode _juzMode = JuzMode.standard;
  QuranContextMenuSettings _ctxMenuSettings = const QuranContextMenuSettings();

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = SecureStorageProvider();
    final batteryOptimizer = BatteryOptimizer();
    await batteryOptimizer.initialize();

    if (!mounted) return;

    final calculationMethod =
        await prefs.getString(_keyCalculationMethod) ?? _calculationMethod;
    final madhab = await prefs.getString(_keyMadhab) ?? _madhab;
    final notificationsEnabled =
        await prefs.getBool(_keyNotificationsEnabled) ?? _notificationsEnabled;
    final themeModeStr = await prefs.getString(_keyAppThemeMode);
    AppThemeMode initialMode = AppThemeMode.dark;
    if (themeModeStr != null) {
      initialMode = AppThemeMode.values.firstWhere(
        (e) => e.name == themeModeStr,
        orElse: () => AppThemeMode.dark,
      );
    } else {
      final useDark = await prefs.getBool('useAmoledTheme') ?? true;
      initialMode = useDark ? AppThemeMode.dark : AppThemeMode.light;
    }
    final jummahReminders =
        await prefs.getBool(_keyJummahReminders) ?? _jummahReminders;
    final iftarReminders =
        await prefs.getBool(_keyIftarReminders) ?? _iftarReminders;
    final savedJuzMode = await prefs.getString(_keyJuzMode);
    final ctxMenuSettings = await QuranContextMenuSettings.fromPrefs(prefs);
    final showPastPrayer = await prefs.getBool('show_past_prayer') ?? false;

    setState(() {
      _calculationMethod = calculationMethod;
      _madhab = madhab;
      _notificationsEnabled = notificationsEnabled;
      _appThemeMode = initialMode;
      _jummahReminders = jummahReminders;
      _iftarReminders = iftarReminders;
      _batterySaverMode = batteryOptimizer.isBatterySaverEnabled();
      _showPastPrayer = showPastPrayer;
      _juzMode =
          savedJuzMode == 'surahBased' ? JuzMode.surahBased : JuzMode.standard;
      _ctxMenuSettings = ctxMenuSettings;
    });
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
          color: AppColors.accent,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.settings,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 100), // Space for nav bar
          children: [
            _buildSectionHeader(context, 'Calculation'),
            ListTile(
              title: Text(AppLocalizations.of(context)!.calculationMethod),
              subtitle: Text(_calculationMethod),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              onTap: () async {
                final choice = await showDialog<String>(
                  context: context,
                  builder: (_) => SimpleDialog(
                    backgroundColor: AppColors.cardSurface,
                    title: Text(
                      AppLocalizations.of(context)!.selectCalculationMethod,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    children: _methods
                        .map(
                          (m) => RadioListTile<String>(
                            title: Text(m),
                            value: m,
                            groupValue: _calculationMethod,
                            activeColor: AppColors.accent,
                            onChanged: (v) => Navigator.pop(context, v),
                          ),
                        )
                        .toList(),
                  ),
                );
                if (choice != null) {
                  final prefs = SecureStorageProvider();
                  if (!mounted) return;
                  setState(() => _calculationMethod = choice);
                  prefs.setString(_keyCalculationMethod, choice);
                }
              },
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.madhab),
              subtitle: Text(_madhab),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              onTap: () async {
                final choice = await showDialog<String>(
                  context: context,
                  builder: (_) => SimpleDialog(
                    backgroundColor: AppColors.cardSurface,
                    title: Text(AppLocalizations.of(context)!.selectMadhab),
                    children: _madhabs
                        .map(
                          (m) => RadioListTile<String>(
                            title: Text(m),
                            value: m,
                            groupValue: _madhab,
                            activeColor: AppColors.accent,
                            onChanged: (v) => Navigator.pop(context, v),
                          ),
                        )
                        .toList(),
                  ),
                );
                if (choice != null) {
                  final prefs = SecureStorageProvider();
                  if (!mounted) return;
                  setState(() => _madhab = choice);
                  prefs.setString(_keyMadhab, choice);
                }
              },
            ),
            const Divider(),
            _buildSectionHeader(context, 'Preferences'),
            SwitchListTile(
              title: Text(AppLocalizations.of(context)!.notifications),
              subtitle: const Text('Get notified for each prayer time'),
              value: _notificationsEnabled,
              activeColor: AppColors.accent,
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              onChanged: (value) async {
                if (value) {
                  // Request notification permissions when enabling
                  final granted =
                      await NotificationService().requestPermissions();
                  if (!granted) {
                    // Show dialog explaining permissions are needed
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Notification permissions are required to enable prayer reminders',
                          ),
                        ),
                      );
                    }
                    return;
                  }
                }

                final prefs = SecureStorageProvider();
                setState(() => _notificationsEnabled = value);
                await prefs.setBool(_keyNotificationsEnabled, value);

                if (!value) {
                  await NotificationService().cancelAllNotifications();
                }
              },
            ),
            SwitchListTile(
              title: const Text('Show Past Prayer Time'),
              subtitle: const Text(
                  'Display time remaining for current/past prayer instead of next prayer'),
              value: _showPastPrayer,
              activeColor: AppColors.accent,
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              onChanged: (value) async {
                final prefs = SecureStorageProvider();
                setState(() => _showPastPrayer = value);
                await prefs.setBool('show_past_prayer', value);
                // The HomeController will pick this up on its next load or when touched
              },
            ),
            if (_notificationsEnabled) ...[
              SwitchListTile(
                title: const Text('Jummah Prep Reminder'),
                subtitle: const Text(
                  'Remind me 1 hour before Friday Dhuhr (Jummah) to prepare.',
                ),
                value: _jummahReminders,
                activeColor: AppColors.accent,
                contentPadding: const EdgeInsets.symmetric(horizontal: 40),
                onChanged: (value) async {
                  final prefs = SecureStorageProvider();
                  setState(() => _jummahReminders = value);
                  await prefs.setBool(_keyJummahReminders, value);
                },
              ),
              SwitchListTile(
                title: const Text('Iftar Prep Reminder'),
                subtitle: const Text(
                  'Remind me 15 minutes before Maghrib during Ramadan.',
                ),
                value: _iftarReminders,
                activeColor: AppColors.accent,
                contentPadding: const EdgeInsets.symmetric(horizontal: 40),
                onChanged: (value) async {
                  final prefs = SecureStorageProvider();
                  setState(() => _iftarReminders = value);
                  await prefs.setBool(_keyIftarReminders, value);
                },
              ),
            ],
            ListTile(
              title: const Text('App Theme'),
              subtitle: Text(_appThemeMode.displayName),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              onTap: () async {
                final choice = await showDialog<AppThemeMode>(
                  context: context,
                  builder: (_) => SimpleDialog(
                    backgroundColor: AppColors.cardSurface,
                    title: Text(
                      'Select App Theme',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    children: AppThemeMode.values
                        .map(
                          (m) => RadioListTile<AppThemeMode>(
                            title: Text(m.displayName),
                            value: m,
                            groupValue: _appThemeMode,
                            activeColor: AppColors.accent,
                            onChanged: (v) => Navigator.pop(context, v),
                          ),
                        )
                        .toList(),
                  ),
                );
                if (choice != null) {
                  final prefs = SecureStorageProvider();
                  if (!mounted) return;
                  setState(() => _appThemeMode = choice);
                  prefs.setString(_keyAppThemeMode, choice.name);
                  themeNotifier.value = choice;
                }
              },
            ),
            ListTile(
              title: const Text('Accent Color'),
              subtitle: const Text('Change the app\'s highlight color'),
              trailing: CircleAvatar(
                backgroundColor: AppColors.accent,
                radius: 12,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              onTap: () => _showColorPicker(context),
            ),
            const Divider(),
            _buildSectionHeader(context, 'Quran'),
            ListTile(
              title: const Text('Juz Mode'),
              subtitle: Text(
                _juzMode == JuzMode.standard
                    ? 'Standard (30 equal parts)'
                    : 'Surah-based (whole surahs)',
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              onTap: () async {
                final choice = await showDialog<JuzMode>(
                  context: context,
                  builder: (_) => SimpleDialog(
                    backgroundColor: AppColors.cardSurface,
                    title: Text(
                      'Select Juz Mode',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    children: [
                      RadioListTile<JuzMode>(
                        title: const Text('Standard (30 equal parts)'),
                        subtitle: const Text(
                          'Traditional division — a juz may split a surah',
                        ),
                        value: JuzMode.standard,
                        groupValue: _juzMode,
                        activeColor: AppColors.accent,
                        onChanged: (v) => Navigator.pop(context, v),
                      ),
                      RadioListTile<JuzMode>(
                        title: const Text('Surah-based (whole surahs)'),
                        subtitle: const Text(
                          'Groups of whole surahs — no surah is split',
                        ),
                        value: JuzMode.surahBased,
                        groupValue: _juzMode,
                        activeColor: AppColors.accent,
                        onChanged: (v) => Navigator.pop(context, v),
                      ),
                    ],
                  ),
                );
                if (choice != null) {
                  final prefs = SecureStorageProvider();
                  if (!mounted) return;
                  setState(() => _juzMode = choice);
                  prefs.setString(
                    _keyJuzMode,
                    choice == JuzMode.surahBased ? 'surahBased' : 'standard',
                  );
                }
              },
            ),
            // ── Long-press context menu toggles ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 4,
              ),
              child: Text(
                'Long-press menu actions',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            SwitchListTile(
              title: const Text('Copy verse'),
              subtitle: const Text('Copy Arabic text to clipboard'),
              value: _ctxMenuSettings.showCopy,
              activeColor: AppColors.accent,
              contentPadding: const EdgeInsets.symmetric(horizontal: 40),
              onChanged: (v) async {
                final prefs = SecureStorageProvider();
                final updated = _ctxMenuSettings.copyWith(showCopy: v);
                await updated.save(prefs);
                if (!mounted) return;
                setState(() => _ctxMenuSettings = updated);
              },
            ),
            SwitchListTile(
              title: const Text('Bookmark verse'),
              subtitle: const Text('Save verse to your bookmarks'),
              value: _ctxMenuSettings.showBookmark,
              activeColor: AppColors.accent,
              contentPadding: const EdgeInsets.symmetric(horizontal: 40),
              onChanged: (v) async {
                final prefs = SecureStorageProvider();
                final updated = _ctxMenuSettings.copyWith(showBookmark: v);
                await updated.save(prefs);
                if (!mounted) return;
                setState(() => _ctxMenuSettings = updated);
              },
            ),
            SwitchListTile(
              title: const Text('Share verse'),
              subtitle: const Text('Share verse via system share sheet'),
              value: _ctxMenuSettings.showShare,
              activeColor: AppColors.accent,
              contentPadding: const EdgeInsets.symmetric(horizontal: 40),
              onChanged: (v) async {
                final prefs = SecureStorageProvider();
                final updated = _ctxMenuSettings.copyWith(showShare: v);
                await updated.save(prefs);
                if (!mounted) return;
                setState(() => _ctxMenuSettings = updated);
              },
            ),
            SwitchListTile(
              title: const Text('Ayah info'),
              subtitle: const Text('Show surah & verse number'),
              value: _ctxMenuSettings.showAyahInfo,
              activeColor: AppColors.accent,
              contentPadding: const EdgeInsets.symmetric(horizontal: 40),
              onChanged: (v) async {
                final prefs = SecureStorageProvider();
                final updated = _ctxMenuSettings.copyWith(showAyahInfo: v);
                await updated.save(prefs);
                if (!mounted) return;
                setState(() => _ctxMenuSettings = updated);
              },
            ),
            const Divider(),
            _buildSectionHeader(context, 'Bottom bar'),
            ListTile(
              leading: const Icon(
                Icons.dashboard_customize,
                color: AppColors.textSecondary,
              ),
              title: const Text('Customize Bottom Bar'),
              subtitle: const Text('Reorder, show/hide tabs & set max icons'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textSecondary,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NavBarCustomizationPage(),
                  ),
                );
              },
            ),
            const Divider(),
            _buildSectionHeader(context, 'Power & Data'),
            SwitchListTile(
              title: const Text('Battery Saver Mode'),
              subtitle: const Text(
                'Reduce battery usage by limiting background updates',
              ),
              value: _batterySaverMode,
              activeColor: AppColors.accent,
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              secondary: const Icon(
                Icons.battery_saver,
                color: AppColors.textSecondary,
              ),
              onChanged: (value) async {
                final batteryOptimizer = BatteryOptimizer();
                await batteryOptimizer.setBatterySaverMode(value);
                setState(() => _batterySaverMode = value);

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value
                          ? 'Battery saver enabled - Updates will be less frequent'
                          : 'Battery saver disabled - Normal update frequency',
                    ),
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: AppColors.textSecondary,
              ),
              title: const Text('Clear Cache'),
              subtitle: const Text('Free up storage space'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textSecondary,
              ),
              onTap: () async {
                final cacheManager = CacheManager();
                final stats = await cacheManager.getStats();

                if (!context.mounted) return;
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppColors.cardSurface,
                    title: const Text('Clear Cache'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cache Size: ${stats['totalSizeKB']} KB'),
                        Text('Items: ${stats['totalItems']}'),
                        Text('Expired: ${stats['expiredItems']}'),
                        const SizedBox(height: 16),
                        const Text('Clear all cached data?'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          await cacheManager.clearAll();
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Cache cleared')),
                            );
                          }
                        },
                        child: const Text(
                          'Clear',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.widgets,
                color: AppColors.textSecondary,
              ),
              title: const Text('Widget Settings'),
              subtitle: const Text('Customize home screen widget'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textSecondary,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WidgetSettingsPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    final colors = [
      const Color(0xFFD4AF37), // Muted Gold (Default)
      const Color(0xFF10B981), // Emerald
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFFF43F5E), // Rose
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF06B6D4), // Cyan
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: const Text('Select Accent Color'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors.map((color) {
            final isSelected = color.toARGB32() == AppColors.accent.toARGB32();
            return GestureDetector(
              onTap: () async {
                final prefs = SecureStorageProvider();
                setState(() {
                  AppColors.accent = color;
                });
                accentColorNotifier.value = color;
                await prefs.setInt(_keyAccentColor, color.toARGB32());
                if (context.mounted) Navigator.pop(context);
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: Colors.white, width: 3)
                      : null,
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
