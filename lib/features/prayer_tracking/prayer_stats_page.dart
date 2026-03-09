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
  Map<String, bool> _selectedDayCompletions = {};
  FixedExtentScrollController? _scrollController;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  bool _loading = true;
  String? _highlightPrayerName;

  // ── Fasting state ─────────────────────────────────────────────────────────

  Color get _mandatoryFastColor => Colors.redAccent.withValues(alpha: 0.30);
  Color get _optionalFastColor => Colors.orangeAccent.withValues(alpha: 0.25);
  List<int> get _whiteDays => const [13, 14, 15];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
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
    final prefs = SecureStorageProvider();
    final latitude = await prefs.getDouble('location_latitude') ?? 21.3891;
    final longitude = await prefs.getDouble('location_longitude') ?? 39.8579;
    final method = await prefs.getInt('calculation_method') ?? 2;
    final madhab = await prefs.getInt('madhab') ?? 0;

    _prayerTimesService = getIt<PrayerTimesServiceFactory>()(
      latitude,
      longitude,
      method,
      madhab,
    );

    await _trackingService.getStatistics();

    final start = DateTime(_focusedDay.year, _focusedDay.month - 1);
    final end = DateTime(_focusedDay.year, _focusedDay.month + 2, 0);
    final history = await _trackingService.getHistoryForRange(start, end);

    final completions =
        await _trackingService.getCompletedPrayersForDate(_selectedDay);

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
        _selectedDayCompletions = completions;

        final displayPrayers = _trackingService.mainPrayers;
        final highlightIndex =
            displayPrayers.indexOf(_highlightPrayerName ?? '');
        final targetIndex = highlightIndex >= 0 ? highlightIndex : 0;

        if (_scrollController == null || !_scrollController!.hasClients) {
          _scrollController?.dispose();
          _scrollController = FixedExtentScrollController(
            initialItem: targetIndex,
          );
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController!.hasClients) {
              _scrollController!.animateToItem(
                targetIndex,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          });
        }

        _loading = false;
      });
    }
  }

  Future<void> _togglePrayer(String prayer) async {
    final wasCompleted = _selectedDayCompletions[prayer] ?? false;
    setState(() {
      _selectedDayCompletions[prayer] = !wasCompleted;
    });

    await _trackingService.togglePrayerCompletion(prayer, _selectedDay);

    final newCompletions =
        await _trackingService.getCompletedPrayersForDate(_selectedDay);

    if (mounted) {
      setState(() {
        _selectedDayCompletions = newCompletions;
        final dateKey = _history.keys.firstWhere(
          (d) => isSameDay(d, _selectedDay),
          orElse: () => _selectedDay,
        );
        _history[dateKey] = newCompletions;
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
            child: _trackingService.mainPrayers.isEmpty
                ? const Padding(
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
                  )
                : ListWheelScrollView.useDelegate(
                    controller: _scrollController,
                    itemExtent: 75,
                    physics: const FixedExtentScrollPhysics(),
                    perspective: 0.005,
                    diameterRatio: 1.5,
                    useMagnifier: true,
                    magnification: 1.2,
                    overAndUnderCenterOpacity: 0.5,
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: _trackingService.mainPrayers.length,
                      builder: (context, index) {
                        final prayer = _trackingService.mainPrayers[index];
                        final isCompleted =
                            _selectedDayCompletions[prayer] ?? false;
                        final prayerTime = _todayPrayerTimes[prayer];
                        final isHighlighted = prayer == _highlightPrayerName;

                        Color bgColor = Colors.transparent;
                        Color borderColor =
                            Colors.white.withValues(alpha: 0.05);
                        Color titleColor = AppColors.textPrimary;
                        Color timeColor = AppColors.textSecondary;
                        FontWeight titleWeight = FontWeight.normal;

                        if (isHighlighted) {
                          bgColor = AppColors.accent.withValues(alpha: 0.25);
                          borderColor = AppColors.accent;
                          titleColor = AppColors.accent;
                          timeColor = AppColors.accent;
                          titleWeight = FontWeight.bold;
                        }

                        return Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor, width: isHighlighted ? 2 : 1),
                              boxShadow: isHighlighted ? [
                                BoxShadow(
                                  color: AppColors.accent.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                )
                              ] : null,
                            ),
                            child: Opacity(
                              opacity: isCompleted ? 0.5 : 1.0,
                              child: InkWell(
                                onTap: () => _togglePrayer(prayer),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0,
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
                                          fontSize: 18,
                                        ),
                                      ),
                                      if (prayerTime != null)
                                        Text(
                                          _formatTime(prayerTime),
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 16,
                                            color: timeColor,
                                            fontWeight: titleWeight,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
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
      gradientColors: [
        AppColors.cardSurface.withValues(alpha: 0.5),
        AppColors.cardSurface.withValues(alpha: 0.2),
      ],
      borderColor: Colors.white.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Table calendar ────────────────────────────────────────────────
          TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
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
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _gregorianMonthYear(day),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${hijri.longMonthName} ${hijri.hYear}',
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

    final secondaryTextColor =
        isSelected ? Colors.white70 : AppColors.textSecondary;

    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${date.day}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight:
                  isSelected || isToday ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : primaryTextColor,
            ),
          ),
          Text(
            '${hijri.hDay}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              color: secondaryTextColor,
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
