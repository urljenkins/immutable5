import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:immutable5/services/secure_storage_provider.dart';
import 'package:table_calendar/table_calendar.dart';

/// A page displaying a combined Gregorian and Hijri calendar.
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _hijriPrimary = false;

  Color get _mandatoryFastColor => Colors.redAccent.withValues(alpha: 0.3);
  Color get _optionalFastColor => Colors.orangeAccent.withValues(alpha: 0.3);
  List<int> get _whiteDays => const [13, 14, 15];

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final prefs = SecureStorageProvider();
    final val = await prefs.getBool('calendar_hijri_primary') ?? false;
    setState(() {
      _hijriPrimary = val;
    });
  }

  Future<void> _setHijriPrimary(bool value) async {
    final prefs = SecureStorageProvider();
    await prefs.setBool('calendar_hijri_primary', value);
    setState(() {
      _hijriPrimary = value;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Use Islamic date as primary'),
              subtitle: const Text(
                'Show Hijri day/month prominently in the calendar',
              ),
              value: _hijriPrimary,
              onChanged: _setHijriPrimary,
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 4.0),
            ),
            const SizedBox(height: 4),
            _buildLegend(context),
            const SizedBox(height: 8),
            Expanded(
              child: TableCalendar(
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                headerStyle: const HeaderStyle(formatButtonVisible: false),
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
                      children: [
                        Text(
                          primary,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          secondary,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    );
                  },
                  defaultBuilder: (context, date, focusedDay) => _buildDayCell(
                    context,
                    date,
                    isSelected: false,
                    isToday: false,
                  ),
                  selectedBuilder: (context, date, focusedDay) => _buildDayCell(
                    context,
                    date,
                    isSelected: true,
                    isToday: false,
                  ),
                  todayBuilder: (context, date, focusedDay) => _buildDayCell(
                    context,
                    date,
                    isSelected: false,
                    isToday: true,
                  ),
                ),
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    final secondaryLabel = _hijriPrimary ? 'Gregorian' : 'Hijri';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Highlights',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _legendChip(color: _mandatoryFastColor, label: 'Ramadan'),
            _legendChip(
              color: _optionalFastColor,
              label: 'Ayyam al-Bid (13-15)',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${_hijriPrimary ? "H" : "G"} = ${_hijriPrimary ? "Hijri" : "Gregorian"} (primary)  •  ${_hijriPrimary ? "G" : "H"} = $secondaryLabel',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
                fontSize: 11,
              ),
        ),
      ],
    );
  }

  Widget _legendChip({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    DateTime date, {
    required bool isSelected,
    required bool isToday,
  }) {
    final hijri = HijriCalendar.fromDate(date);
    final isMandatoryFast = hijri.hMonth == 9;
    final isOptionalFast = _whiteDays.contains(hijri.hDay);

    // Determine background color based on fasting days
    Color? fastingBg;
    if (isMandatoryFast) {
      fastingBg = _mandatoryFastColor;
    } else if (isOptionalFast) {
      fastingBg = _optionalFastColor;
    }

    // Primary and secondary dates based on preference
    final primaryDate = _hijriPrimary ? hijri.hDay : date.day;
    final secondaryDate = _hijriPrimary ? date.day : hijri.hDay;
    final secondaryLabel = _hijriPrimary ? 'G' : 'H';

    // Styling for selected/today states
    final primaryColor = isSelected || isToday
        ? Colors.white
        : Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryColor =
        isSelected || isToday ? Colors.white70 : Colors.grey[500];

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : isToday
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                : fastingBg,
        shape: BoxShape.circle,
        border: isToday && !isSelected
            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
            : null,
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$primaryDate',
            style: TextStyle(
              fontSize: 14,
              fontWeight:
                  isToday || isSelected ? FontWeight.bold : FontWeight.normal,
              color: primaryColor,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$secondaryLabel:',
                style: TextStyle(
                  fontSize: 8,
                  color: secondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$secondaryDate',
                style: TextStyle(fontSize: 9, color: secondaryColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
