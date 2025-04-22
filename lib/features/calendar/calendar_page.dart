import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hijri/hijri_calendar.dart';

/// A page displaying a combined Gregorian and Hijri calendar.
class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TableCalendar(
          firstDay: DateTime.now().subtract(const Duration(days: 365)),
          lastDay: DateTime.now().add(const Duration(days: 365)),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selected, focused) {
            setState(() {
              _selectedDay = selected;
              _focusedDay = focused;
            });
          },
          calendarBuilders: CalendarBuilders(
            dayBuilder: (context, date, _) {
              final hijri = HijriCalendar.fromDate(date);
              final isMandatoryFast = hijri.hMonth == 9;
              final isOptionalFast = [14, 15, 16].contains(hijri.hDay);
              Color? bg;
              if (isMandatoryFast) {
                bg = Colors.redAccent.withOpacity(0.3);
              } else if (isOptionalFast) {
                bg = Colors.orangeAccent.withOpacity(0.3);
              }
              return Container(
                decoration: bg != null
                    ? BoxDecoration(color: bg, shape: BoxShape.circle)
                    : null,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${date.day}', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 2),
                    Text('${hijri.hDay}', style: const TextStyle(fontSize: 10)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
