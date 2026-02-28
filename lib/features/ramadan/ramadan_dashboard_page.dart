import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:immutable5/services/secure_storage_provider.dart';
import '../../di/service_locator.dart';
import '../prayer/prayer_times_service.dart';
import '../prayer_tracking/prayer_tracking_service.dart';
import '../../shared/app_colors.dart';
import '../../shared/glass_container.dart';

class RamadanDashboardPage extends StatefulWidget {
  const RamadanDashboardPage({super.key});

  @override
  State<RamadanDashboardPage> createState() => _RamadanDashboardPageState();
}

class _RamadanDashboardPageState extends State<RamadanDashboardPage> {
  PrayerTimesService? _prayerTimesService;
  late final PrayerTrackingService _trackingService;

  bool _loading = true;
  String _error = '';

  // Data
  DateTime? _fajrToday;
  DateTime? _maghribToday;
  DateTime? _fajrTomorrow;

  // Timer
  Timer? _timer;
  Duration _countdown = Duration.zero;
  bool _isFastingHours = false; // true if between Fajr and Maghrib

  // Taraweeh
  bool _taraweehCompleted = false;

  @override
  void initState() {
    super.initState();
    _trackingService = getIt<PrayerTrackingService>();
    _initServiceAndLoadData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initServiceAndLoadData() async {
    try {
      final prefs = SecureStorageProvider();
      final latitude = await prefs.getDouble('location_latitude') ?? 21.3891;
      final longitude = await prefs.getDouble('location_longitude') ?? 39.8579;
      final method = await prefs.getInt('calculation_method') ?? 2;
      final madhab = await prefs.getInt('madhab') ?? 0;

      final factory = getIt<PrayerTimesServiceFactory>();
      _prayerTimesService = factory(latitude, longitude, method, madhab);

      await _loadData();
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to initialize: $e';
      });
    }
  }

  Future<void> _loadData() async {
    if (_prayerTimesService == null) return;

    try {
      final now = DateTime.now();

      // Get today's prayer times
      final todayTimes = await _prayerTimesService!.getPrayerTimesForDate(now);

      // Get tomorrow's prayer times (need Fajr for Suhoor countdown)
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowTimes = await _prayerTimesService!.getPrayerTimesForDate(
        tomorrow,
      );

      // Check Taraweeh status
      final taraweehCompleted = await _trackingService.isPrayerCompleted(
        'Taraweeh',
        now,
      );

      if (mounted) {
        setState(() {
          _fajrToday = todayTimes['Fajr'];
          _maghribToday = todayTimes['Maghrib'];
          _fajrTomorrow = tomorrowTimes['Fajr'];
          _taraweehCompleted = taraweehCompleted;
          _loading = false;
        });
        _startTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load prayer times: $e';
        });
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _updateCountdown(); // Initial update
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateCountdown(),
    );
  }

  void _updateCountdown() {
    if (_fajrToday == null || _maghribToday == null || _fajrTomorrow == null) {
      return;
    }

    final now = DateTime.now();
    DateTime targetTime;
    bool isFasting;

    if (now.isBefore(_fajrToday!)) {
      // Before Fajr: Counting down to Fajr (Suhoor time)
      targetTime = _fajrToday!;
      isFasting = false;
    } else if (now.isBefore(_maghribToday!)) {
      // Between Fajr and Maghrib: Counting down to Maghrib (Iftar time)
      targetTime = _maghribToday!;
      isFasting = true;
    } else {
      // After Maghrib: Counting down to tomorrow's Fajr (Suhoor time)
      targetTime = _fajrTomorrow!;
      isFasting = false;
    }

    final diff = targetTime.difference(now);

    // If diff is negative, we might have just crossed a boundary, reload data
    if (diff.isNegative) {
      _loadData();
      return;
    }

    if (mounted) {
      setState(() {
        _countdown = diff;
        _isFastingHours = isFasting;
      });
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final h = twoDigits(d.inHours);
    final m = twoDigits(d.inMinutes.remainder(60));
    final s = twoDigits(d.inSeconds.remainder(60));
    return "$h:$m:$s";
  }

  String _formatHoursMinutes(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return "${h}h ${m}m";
  }

  Future<void> _toggleTaraweeh() async {
    final now = DateTime.now();
    await _trackingService.togglePrayerCompletion('Taraweeh', now);
    setState(() {
      _taraweehCompleted = !_taraweehCompleted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hijriDate = HijriCalendar.now();
    final hijriString =
        '${hijriDate.longMonthName} ${hijriDate.hDay}, ${hijriDate.hYear}';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Ramadan Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),

          // Decorative Orb
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.1),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 80,
                    color: AppColors.accent.withValues(alpha: 0.15),
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                    ? Center(
                        child: Text(
                          _error,
                          style: TextStyle(color: AppColors.error),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Hijri Date
                            Text(
                              hijriString.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Countdown Card
                            GlassContainer(
                              padding: const EdgeInsets.symmetric(
                                vertical: 40,
                                horizontal: 24,
                              ),
                              borderRadius: 24,
                              gradientColors: [
                                AppColors.accent.withValues(alpha: 0.1),
                                AppColors.accent.withValues(alpha: 0.05),
                              ],
                              borderColor:
                                  AppColors.accent.withValues(alpha: 0.2),
                              child: Column(
                                children: [
                                  Icon(
                                    _isFastingHours
                                        ? Icons.wb_sunny_outlined
                                        : Icons.nights_stay_outlined,
                                    size: 32,
                                    color: AppColors.accent,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _isFastingHours
                                        ? 'IFTAR COUNTDOWN'
                                        : 'SUHOOR COUNTDOWN',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      letterSpacing: 2.0,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _formatDuration(_countdown),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                      fontFeatures: [
                                        const FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Fasting Duration
                            if (_fajrToday != null && _maghribToday != null)
                              GlassContainer(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Fasting Duration',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatHoursMinutes(
                                            _maghribToday!
                                                .difference(_fajrToday!),
                                          ),
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Icon(
                                      Icons.timer_outlined,
                                      color: AppColors.accent.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 16),

                            // Taraweeh Tracker
                            GlassContainer(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _taraweehCompleted
                                          ? Colors.green.withValues(alpha: 0.1)
                                          : Colors.grey.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.mosque,
                                      color: _taraweehCompleted
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Taraweeh',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          _taraweehCompleted
                                              ? 'Completed'
                                              : 'Not completed yet',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            color: _taraweehCompleted
                                                ? Colors.green
                                                : AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: _taraweehCompleted,
                                    onChanged: (val) => _toggleTaraweeh(),
                                    activeThumbColor: AppColors.accent,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
