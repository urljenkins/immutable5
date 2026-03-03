import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../di/service_locator.dart';
import '../../services/secure_storage_provider.dart';
import '../../shared/app_colors.dart';
import '../../shared/glass_container.dart';
import '../prayer/prayer_times_service.dart';
import 'prayer_tracking_service.dart';

class PrayerStatsPage extends StatefulWidget {
  const PrayerStatsPage({super.key});

  @override
  State<PrayerStatsPage> createState() => _PrayerStatsPageState();
}

class _PrayerStatsPageState extends State<PrayerStatsPage> {
  final PrayerTrackingService _trackingService = PrayerTrackingService();
  late final PrayerTimesService _prayerTimesService;
  Map<DateTime, Map<String, bool>> _history = {};
  Map<String, DateTime> _todayPrayerTimes = {};
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  bool _loading = true;
  String? _highlightPrayerName;

  // ── Hijri / fasting state ──────────────────────────────────────────────────
  bool _hijriPrimary = false;

  Color get _mandatoryFastColor => Colors.redAccent.withValues(alpha: 0.30);
  Color get _optionalFastColor => Colors.orangeAccent.withValues(alpha: 0.25);
  List<int> get _whiteDays => const [13, 14, 15];

  @override
  void initState() {
    super.initState();
    _prayerTimesService = getIt<PrayerTimesServiceFactory>()(
      51.5074, // Default lat, ideally from user location
      -0.1278, // Default lon
      2, // Default method
      0, // Default madhab
    );
    _loadHijriPreference();
    _loadData();
  }

  // ── Hijri preference helpers ───────────────────────────────────────────────

  Future<void> _loadHijriPreference() async {
    final prefs = SecureStorageProvider();
    final val = await prefs.getBool('calendar_hijri_primary') ?? false;
    if (mounted) {
      setState(() => _hijriPrimary = val);
    }
  }

  Future<void> _setHijriPrimary(bool value) async {
    final prefs = SecureStorageProvider();
    await prefs.setBool('calendar_hijri_primary', value);
    setState(() => _hijriPrimary = value);
  }

  String _gregorianMonthYear(DateTime day) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[day.month - 1]} ${day.year}';
  }

  // ── Data loading ───────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    await _trackingService.getStatistics();
    final now = DateTime.now();
    final history = await _trackingService.getHistoryForRange(now, now);

    Map<String, DateTime> times = {};
    String? highlightPrayer;

    try {
      times = await _prayerTimesService.getPrayerTimesForDate(_selectedDay);

      if (isSameDay(_selectedDay, DateTime.now())) {
        final prefs = SecureStorageProvider();
        final showPastPrayer = await prefs.getBool('show_past_prayer') ?? false;

        if (showPastPrayer) {
          final past = await _prayerTimesService.getPastPrayer();
          highlightPrayer = past.key;
        } else {
          final next = await _prayerTimesService.getNextPrayer();
          highlightPrayer = next.key;
        }
      }
    } catch (e) {
      debugPrint('Failed to load prayer times: $e');
    }

    if (mounted) {
      setState(() {
        _history = history;
        _todayPrayerTimes = times;
        _highlightPrayerName = highlightPrayer;
        _loading = false;
      });
    }
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '--:--';
    final hour =
        time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $amPm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Salah',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Stack(
        children: [
          // Atmospheric Background Element
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

          SafeArea(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 16.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _buildTodayPrayers()),
                        const SizedBox(height: 24),
                        _buildCalendarView(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Timing wheel ───────────────────────────────────────────────────────────

  Widget _buildTodayPrayers() {
    return GlassContainer(
      padding: const EdgeInsets.all(12.0),
      borderRadius: 24,
      gradientColors: [
        AppColors.cardSurface.withValues(alpha: 0.5),
        AppColors.cardSurface.withValues(alpha: 0.2),
      ],
      borderColor: Colors.white.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: Text(
              'Timing',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<Map<String, bool>>(
              future: _trackingService.getCompletedPrayersForDate(_selectedDay),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final completions = snapshot.data!;
                final displayPrayers = _trackingService.mainPrayers;

                if (displayPrayers.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                      child: Text(
                        'No prayers available.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  );
                }

                return ListWheelScrollView.useDelegate(
                  itemExtent: 65,
                  physics: const BouncingScrollPhysics(),
                  perspective: 0.005,
                  diameterRatio: 2.5,
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: displayPrayers.length,
                    builder: (context, index) {
                      final prayer = displayPrayers[index];
                      final isCompleted = completions[prayer] ?? false;
                      final prayerTime = _todayPrayerTimes[prayer];
                      final isHighlighted = prayer == _highlightPrayerName;

                      Color bgColor = Colors.transparent;
                      Color borderColor = Colors.white.withValues(alpha: 0.05);
                      Color titleColor = AppColors.textPrimary;
                      Color timeColor = AppColors.textSecondary;
                      FontWeight titleWeight = FontWeight.normal;

                      if (isHighlighted) {
                        bgColor = AppColors.accent.withValues(alpha: 0.15);
                        borderColor = AppColors.accent.withValues(alpha: 0.5);
                        titleColor = AppColors.accent;
                        timeColor = AppColors.accent;
                        titleWeight = FontWeight.bold;
                      }

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Opacity(
                          opacity: isCompleted ? 0.5 : 1.0,
                          child: InkWell(
                            onTap: () async {
                              await _trackingService.togglePrayerCompletion(
                                prayer,
                                _selectedDay,
                              );
                              setState(() => _loading = true);
                              _loadData();
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    prayer,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: titleWeight,
                                      color: titleColor,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (prayerTime != null)
                                    Text(
                                      _formatTime(prayerTime),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        color: timeColor,
                                        fontWeight: titleWeight,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Calendar view ──────────────────────────────────────────────────────────

  Widget _buildCalendarView() {
    return GlassContainer(
      padding: const EdgeInsets.all(16.0),
      borderRadius: 24,
      gradientColors: [
        AppColors.cardSurface.withValues(alpha: 0.5),
        AppColors.cardSurface.withValues(alpha: 0.2),
      ],
      borderColor: Colors.white.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hijri toggle ─────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  'Show Islamic date',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Switch(
                value: _hijriPrimary,
                activeThumbColor: AppColors.accent,
                onChanged: _setHijriPrimary,
              ),
            ],
          ),
          const SizedBox(height: 4),

          // ── Table calendar ────────────────────────────────────────────────
          TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: false,
              headerPadding: EdgeInsets.only(bottom: 4),
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color: AppColors.textPrimary,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: AppColors.textPrimary,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle:
                  GoogleFonts.plusJakartaSans(color: AppColors.textSecondary),
              weekendStyle:
                  GoogleFonts.plusJakartaSans(color: AppColors.textSecondary),
            ),
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _loading = true;
              });
              _loadData();
            },
            calendarBuilders: CalendarBuilders(
              headerTitleBuilder: (context, day) {
                final hijri = HijriCalendar.fromDate(day);
                final primary = _hijriPrimary
                    ? '${hijri.longMonthName} ${hijri.hYear}'
                    : _gregorianMonthYear(day);
                final secondary = _hijriPrimary
                    ? _gregorianMonthYear(day)
                    : '${hijri.longMonthName} ${hijri.hYear}';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      primary,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      secondary,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                );
              },
              defaultBuilder: (context, date, _) =>
                  _buildCalendarDay(context, date),
              selectedBuilder: (context, date, _) =>
                  _buildCalendarDay(context, date, isSelected: true),
              todayBuilder: (context, date, _) =>
                  _buildCalendarDay(context, date, isToday: true),
            ),
          ),

          const SizedBox(height: 12),
          _buildLegend(context),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ── Merged calendar day cell ───────────────────────────────────────────────

  Widget _buildCalendarDay(
    BuildContext context,
    DateTime date, {
    bool isSelected = false,
    bool isToday = false,
  }) {
    // Prayer completion state
    final dateKey = _history.keys.firstWhere(
      (d) => isSameDay(d, date),
      orElse: () => date,
    );
    final completions = _history[dateKey];
    final completedCount = completions?.values.where((v) => v).length ?? 0;
    final total = _trackingService.mainPrayers.length;

    // Hijri info for fasting highlights
    final hijri = HijriCalendar.fromDate(date);
    final isMandatoryFast = hijri.hMonth == 9; // Ramadan
    final isOptionalFast = _whiteDays.contains(hijri.hDay);

    // ── Background colour priority: selected > today > prayer > fasting ──
    Color? bgColor;
    Color borderColor = Colors.transparent;
    Color primaryTextColor = AppColors.textPrimary;

    if (isSelected) {
      bgColor = Colors.white.withValues(alpha: 0.12);
      borderColor = Colors.white.withValues(alpha: 0.35);
    } else if (completedCount == total && completedCount > 0) {
      bgColor = AppColors.success.withValues(alpha: 0.18);
      borderColor = AppColors.success.withValues(alpha: 0.45);
      primaryTextColor = AppColors.success;
    } else if (completedCount > 0) {
      bgColor = AppColors.accent.withValues(alpha: 0.13);
      borderColor = AppColors.accent.withValues(alpha: 0.28);
      primaryTextColor = AppColors.accent;
    } else if (isMandatoryFast) {
      bgColor = _mandatoryFastColor;
    } else if (isOptionalFast) {
      bgColor = _optionalFastColor;
    } else {
      bgColor = Colors.transparent;
    }

    if (isToday && !isSelected && completedCount == 0) {
      bgColor = Colors.white.withValues(alpha: 0.05);
      borderColor = Colors.white.withValues(alpha: 0.20);
    }

    // ── Dual date display ──────────────────────────────────────────────────
    final primaryDate = _hijriPrimary ? hijri.hDay : date.day;
    final secondaryDate = _hijriPrimary ? date.day : hijri.hDay;
    final secondaryLabel = _hijriPrimary ? 'G' : 'H';

    final secondaryTextColor =
        isSelected ? Colors.white70 : AppColors.textSecondary;

    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$primaryDate',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight:
                  isSelected || isToday ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : primaryTextColor,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$secondaryLabel:',
                style: TextStyle(
                  fontSize: 7,
                  color: secondaryTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$secondaryDate',
                style: TextStyle(fontSize: 8, color: secondaryTextColor),
              ),
            ],
          ),
          // Partial completion dot indicator
          if (completedCount > 0 && completedCount < total)
            Container(
              margin: const EdgeInsets.only(top: 1),
              height: 3,
              width: 3,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  // ── Legend ─────────────────────────────────────────────────────────────────

  Widget _buildLegend(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _legendChip(color: _mandatoryFastColor, label: 'Ramadan'),
        _legendChip(color: _optionalFastColor, label: 'Ayyam al-Bid 13–15'),
      ],
    );
  }

  Widget _legendChip({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
