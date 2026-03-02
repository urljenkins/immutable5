import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../di/service_locator.dart';
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
  Map<String, dynamic>? _stats;
  Map<DateTime, Map<String, bool>> _history = {};
  Map<String, DateTime> _todayPrayerTimes = {};
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _prayerTimesService = getIt<PrayerTimesServiceFactory>()(
      51.5074, // Default lat, ideally from user location
      -0.1278, // Default lon
      2, // Default method
      0, // Default madhab
    );
    _loadData();
  }

  Future<void> _loadData() async {
    final stats = await _trackingService.getStatistics();
    final history = await _trackingService.getLast30DaysHistory();

    Map<String, DateTime> times = {};
    try {
      times = await _prayerTimesService.getPrayerTimesForDate(_selectedDay);
    } catch (e) {
      debugPrint('Failed to load prayer times: $e');
    }

    if (mounted) {
      setState(() {
        _stats = stats;
        _history = history;
        _todayPrayerTimes = times;
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
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 16.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTodayPrayers(),
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
              'Prayers',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<Map<String, bool>>(
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

              return SizedBox(
                height: 200,
                child: ListWheelScrollView.useDelegate(
                  itemExtent: 65,
                  physics: const BouncingScrollPhysics(),
                  perspective: 0.005,
                  diameterRatio: 1.5,
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: displayPrayers.length,
                    builder: (context, index) {
                      final prayer = displayPrayers[index];
                      final isCompleted = completions[prayer] ?? false;
                      final prayerTime = _todayPrayerTimes[prayer];

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppColors.success.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCompleted
                                ? AppColors.success.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: CheckboxListTile(
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                prayer,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: isCompleted
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isCompleted
                                      ? AppColors.success
                                      : AppColors.textPrimary,
                                ),
                              ),
                              if (prayerTime != null)
                                Text(
                                  _formatTime(prayerTime),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: isCompleted
                                        ? AppColors.success
                                        : AppColors.textSecondary,
                                    fontWeight: isCompleted
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                            ],
                          ),
                          value: isCompleted,
                          onChanged: (value) async {
                            await _trackingService.togglePrayerCompletion(
                              prayer,
                              _selectedDay,
                            );
                            setState(() {
                              _loading = true;
                            });
                            _loadData();
                          },
                          secondary: Icon(
                            isCompleted
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: isCompleted
                                ? AppColors.success
                                : AppColors.textSecondary,
                          ),
                          checkboxShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView() {
    return GlassContainer(
      padding: const EdgeInsets.all(20.0),
      borderRadius: 24,
      gradientColors: [
        AppColors.cardSurface.withValues(alpha: 0.5),
        AppColors.cardSurface.withValues(alpha: 0.2),
      ],
      borderColor: Colors.white.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last 30 Days',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 60)),
            lastDay: DateTime.now(),
            focusedDay: _focusedDay,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: GoogleFonts.plusJakartaSans(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              leftChevronIcon:
                  const Icon(Icons.chevron_left, color: AppColors.textPrimary),
              rightChevronIcon:
                  const Icon(Icons.chevron_right, color: AppColors.textPrimary),
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
              });
            },
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, date, _) {
                return _buildCalendarDay(date);
              },
              selectedBuilder: (context, date, _) {
                return _buildCalendarDay(date, isSelected: true);
              },
              todayBuilder: (context, date, _) {
                return _buildCalendarDay(date, isToday: true);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarDay(
    DateTime date, {
    bool isSelected = false,
    bool isToday = false,
  }) {
    final dateKey = _history.keys.firstWhere(
      (d) => isSameDay(d, date),
      orElse: () => date,
    );
    final completions = _history[dateKey];
    final completedCount = completions?.values.where((v) => v).length ?? 0;
    final total = _trackingService.mainPrayers.length;

    Color? backgroundColor;
    Color? borderColor;
    Color textColor = AppColors.textPrimary;

    if (completedCount == total && completedCount > 0) {
      backgroundColor = AppColors.success.withValues(alpha: 0.2);
      borderColor = AppColors.success.withValues(alpha: 0.5);
      textColor = AppColors.success;
    } else if (completedCount > 0) {
      backgroundColor = AppColors.accent.withValues(alpha: 0.15);
      borderColor = AppColors.accent.withValues(alpha: 0.3);
      textColor = AppColors.accent;
    } else {
      backgroundColor = Colors.transparent;
      borderColor = Colors.transparent;
    }

    if (isSelected) {
      backgroundColor = Colors.white.withValues(alpha: 0.1);
      borderColor = Colors.white.withValues(alpha: 0.3);
      textColor = AppColors.textPrimary;
    } else if (isToday && completedCount == 0) {
      backgroundColor = Colors.white.withValues(alpha: 0.05);
      borderColor = Colors.white.withValues(alpha: 0.2);
    }

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight:
                    isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                color: textColor,
              ),
            ),
            if (completedCount > 0 && completedCount < total)
              Container(
                margin: const EdgeInsets.only(top: 2),
                height: 4,
                width: 4,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
