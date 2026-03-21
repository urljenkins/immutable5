import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:immutable5/services/secure_storage_provider.dart';

import '../../di/service_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/app_colors.dart';
import '../../shared/glass_container.dart';
import '../duas/duas_page.dart';
import '../duas/models/dua_model.dart';
import '../glossary/glossary_page.dart';
import '../hadith/hadith_repository.dart';
import '../hadith/hadiths_page.dart';
import '../hadith/models/hadith.dart';
import '../home/home_controller.dart';
import '../prayer/prayer_times_service.dart';
import '../quotes/quote_picker_service.dart';
import '../ramadan/ramadan_dashboard_page.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final HomeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HomeController(
      quoteService: getIt<QuotePickerService>(),
      notificationPort: getIt<NotificationPort>(),
      widgetPort: getIt<WidgetUpdatePort>(),
      prayerFactory: getIt<PrayerTimesServiceFactory>(),
      hadithRepository: getIt<HadithRepository>(),
    );
    unawaited(_controller.init());
  }

  @override
  void dispose() {
    _controller.disposeController();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final h = twoDigits(d.inHours);
    final m = twoDigits(d.inMinutes.remainder(60));
    final s = twoDigits(d.inSeconds.remainder(60));
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _controller.state;
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: state.locationLoaded
                ? IconButton(
                    icon: state.refreshing
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.accent,
                            ),
                          )
                        : const Icon(
                            Icons.refresh,
                            color: AppColors.textSecondary,
                          ),
                    onPressed: state.refreshing
                        ? null
                        : () => unawaited(_controller.refresh()),
                    tooltip: AppLocalizations.of(context)!.refreshPrayerTimes,
                  )
                : null,
            actions: [
              IconButton(
                icon: const Icon(Icons.menu_book_outlined),
                color: AppColors.textSecondary,
                tooltip: 'Glossary',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GlossaryPage(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.nights_stay_outlined),
                color: AppColors.textSecondary,
                tooltip: 'Ramadan Dashboard',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RamadanDashboardPage(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              // 1. Atmospheric Background Element (Gradient Orb)
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  height: 300,
                  width: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withValues(alpha: 0.15),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 100,
                        color: AppColors.accent.withValues(alpha: 0.2),
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Main Content
              SafeArea(
                child: state.loading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accent,
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Status Banners
                            if (state.locationNotice != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 8,
                                ),
                                child: _StatusBanner(
                                  icon: state.locationPermissionIssue
                                      ? Icons.location_off_outlined
                                      : Icons.info_outline,
                                  background:
                                      (state.locationPermissionIssue
                                              ? AppColors.error
                                              : AppColors.accent)
                                          .withValues(alpha: 0.1),
                                  foreground: state.locationPermissionIssue
                                      ? AppColors.error
                                      : AppColors.accent,
                                  message: state.locationNotice!,
                                  action: state.locationPermissionIssue
                                      ? TextButton(
                                          onPressed: () =>
                                              unawaited(_controller.refresh()),
                                          child: Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.refreshPrayerTimes,
                                            style: TextStyle(
                                              color:
                                                  state.locationPermissionIssue
                                                  ? AppColors.error
                                                  : AppColors.accent,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                              ),

                            const SizedBox(height: 20),

                            // Hero Section
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                              ),
                              child: InkWell(
                                onTap: () => unawaited(
                                  _controller.togglePrayerDisplayOption(),
                                ),
                                borderRadius: BorderRadius.circular(16),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _HijriDateBanner(),
                                    const SizedBox(height: 40),
                                    Text(
                                      state.showPastPrayer
                                          ? (state.pastPrayerName ?? '...')
                                          : (state.nextPrayerName ??
                                                (state.locationError != null &&
                                                        !state.usingCache
                                                    ? 'Offline'
                                                    : AppLocalizations.of(
                                                        context,
                                                      )!.loading)),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w300,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      state.nextPrayerTime != null
                                          ? _formatDuration(state.countdown)
                                          : '--:--:--',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 64,
                                        fontWeight: FontWeight.bold,
                                        color: state.isProhibitedTime
                                            ? AppColors.error
                                            : AppColors.accent,
                                        height: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      state.showPastPrayer
                                          ? 'TIME REMAINING'
                                          : AppLocalizations.of(
                                              context,
                                            )!.nextPrayer.toUpperCase(),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        letterSpacing: 2.0,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 40),

                            // Contextual or Standard Quote Card
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 500),
                                transitionBuilder: (child, anim) =>
                                    FadeTransition(opacity: anim, child: child),
                                child: state.contextualDua != null
                                    ? _ContextualDuaCard(
                                        key: ValueKey(
                                          'dua_${state.contextualDua!.id}',
                                        ),
                                        dua: state.contextualDua!,
                                        message: state.contextualMessage,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => DuasPage(
                                                initialDua: state.contextualDua,
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    : state.contextualHadith != null
                                    ? _ContextualHadithCard(
                                        key: ValueKey(
                                          'hadith_${state.contextualHadith!.id}',
                                        ),
                                        hadith: state.contextualHadith!,
                                        message: state.contextualMessage,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => HadithsPage(
                                                initialHadith:
                                                    state.contextualHadith,
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    : GlassContainer(
                                        key: ValueKey<String>(
                                          state.quote ?? '',
                                        ),
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(24),
                                        child: Center(
                                          child: Text(
                                            state.quote ?? '...',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 16,
                                              height: 1.6,
                                              color: AppColors.textPrimary
                                                  .withValues(alpha: 0.9),
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.message,
    this.action,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 16,
      gradientColors: [background, background.withValues(alpha: 0.05)],
      borderColor: foreground.withValues(alpha: 0.2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: foreground),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                message,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class _HijriDateBanner extends StatefulWidget {
  const _HijriDateBanner({super.key});

  @override
  State<_HijriDateBanner> createState() => _HijriDateBannerState();
}

class _HijriDateBannerState extends State<_HijriDateBanner> {
  static const _keyHijriDayOffset = 'hijriDayOffset';
  int _offset = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadOffset());
  }

  Future<void> _loadOffset() async {
    final prefs = SecureStorageProvider();
    if (!mounted) return;
    final offset = await prefs.getInt(_keyHijriDayOffset) ?? 0;
    setState(() {
      _offset = offset;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final adjusted = DateTime.now().add(Duration(days: _offset));
    final hijri = HijriCalendar.fromDate(adjusted);
    final hijriDate = '${hijri.longMonthName} ${hijri.hDay}, ${hijri.hYear}';

    return AnimatedOpacity(
      opacity: _loaded ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Text(
        hijriDate.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          letterSpacing: 2.0,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ContextualDuaCard extends StatelessWidget {
  const _ContextualDuaCard({
    super.key,
    required this.dua,
    this.message,
    this.onTap,
  });

  final Dua dua;
  final String? message;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      width: double.infinity,
      onTap: onTap,
      gradientColors: [
        AppColors.accent.withValues(alpha: 0.2),
        AppColors.accent.withValues(alpha: 0.05),
      ],
      borderColor: AppColors.accent.withValues(alpha: 0.3),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message != null && message!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            Text(
              dua.arabic,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontSize: 20,
                height: 1.8,
                fontFamily: 'Amiri',
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              dua.transliteration,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              dua.translationEn,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textPrimary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContextualHadithCard extends StatelessWidget {
  const _ContextualHadithCard({
    super.key,
    required this.hadith,
    this.message,
    this.onTap,
  });

  final Hadith hadith;
  final String? message;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      width: double.infinity,
      onTap: onTap,
      gradientColors: [
        AppColors.accent.withValues(alpha: 0.1),
        AppColors.accent.withValues(alpha: 0.05),
      ],
      borderColor: AppColors.accent.withValues(alpha: 0.2),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message != null && message!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            Text(
              hadith.arabic,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontSize: 18,
                height: 1.6,
                fontFamily: 'Amiri',
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              hadith.translationEn,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textPrimary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '— ${hadith.collection}',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
