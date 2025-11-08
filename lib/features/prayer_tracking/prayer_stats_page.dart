import 'package:flutter/material.dart';
import 'prayer_tracking_service.dart';
import 'package:table_calendar/table_calendar.dart';

class PrayerStatsPage extends StatefulWidget {
  const PrayerStatsPage({Key? key}) : super(key: key);

  @override
  _PrayerStatsPageState createState() => _PrayerStatsPageState();
}

class _PrayerStatsPageState extends State<PrayerStatsPage> {
  final PrayerTrackingService _trackingService = PrayerTrackingService();
  Map<String, dynamic>? _stats;
  Map<DateTime, Map<String, bool>> _history = {};
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final stats = await _trackingService.getStatistics();
    final history = await _trackingService.getLast30DaysHistory();

    setState(() {
      _stats = stats;
      _history = history;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prayer Statistics'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatisticsCards(),
                  const SizedBox(height: 24),
                  _buildTodayPrayers(),
                  const SizedBox(height: 24),
                  _buildCalendarView(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatisticsCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Current Streak',
                '${_stats!['currentStreak']} days',
                Icons.local_fire_department,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Longest Streak',
                '${_stats!['longestStreak']} days',
                Icons.emoji_events,
                Colors.amber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Today',
                '${(_stats!['todayCompletion'] * 100).toInt()}%',
                Icons.today,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Prayers',
                '${_stats!['totalPrayers']}',
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayPrayers() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today\'s Prayers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            FutureBuilder<Map<String, bool>>(
              future: _trackingService.getCompletedPrayersForDate(_selectedDay),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final completions = snapshot.data!;
                return Column(
                  children: _trackingService.mainPrayers.map((prayer) {
                    final isCompleted = completions[prayer] ?? false;
                    return CheckboxListTile(
                      title: Text(prayer),
                      value: isCompleted,
                      onChanged: (value) async {
                        await _trackingService.togglePrayerCompletion(prayer, _selectedDay);
                        setState(() {
                          _loadData();
                        });
                      },
                      secondary: Icon(
                        isCompleted ? Icons.check_circle : Icons.circle_outlined,
                        color: isCompleted ? Colors.green : Colors.grey,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarView() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last 30 Days',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 60)),
              lastDay: DateTime.now(),
              focusedDay: _focusedDay,
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
      ),
    );
  }

  Widget _buildCalendarDay(DateTime date, {bool isSelected = false, bool isToday = false}) {
    final dateKey = _history.keys.firstWhere(
      (d) => isSameDay(d, date),
      orElse: () => date,
    );
    final completions = _history[dateKey];
    final completedCount = completions?.values.where((v) => v).length ?? 0;
    final total = _trackingService.mainPrayers.length;

    Color? backgroundColor;
    if (completedCount == total && completedCount > 0) {
      backgroundColor = Colors.green.withOpacity(0.3);
    } else if (completedCount > 0) {
      backgroundColor = Colors.orange.withOpacity(0.3);
    }

    if (isSelected) {
      backgroundColor = Colors.blue.withOpacity(0.5);
    } else if (isToday) {
      backgroundColor = Colors.purple.withOpacity(0.3);
    }

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: const TextStyle(fontSize: 14),
            ),
            if (completedCount > 0)
              Text(
                '$completedCount/$total',
                style: const TextStyle(fontSize: 8),
              ),
          ],
        ),
      ),
    );
  }
}
