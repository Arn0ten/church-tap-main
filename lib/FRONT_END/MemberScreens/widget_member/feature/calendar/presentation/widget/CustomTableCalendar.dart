import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class Customtablecalendar extends StatefulWidget {
  const Customtablecalendar({super.key});

  @override
  State<Customtablecalendar> createState() => _CustomtablecalendarState();
}

class _CustomtablecalendarState extends State<Customtablecalendar> {
  @override
  Widget build(BuildContext context) {
    DateTime _selectedDay = DateTime.now();
    DateTime _focusedDay = DateTime.now();

    return TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime.utc(
                DateTime.now().year, DateTime.now().month, DateTime.now().day),
            lastDay: DateTime.utc(DateTime.now().year + 1, 2, 1),
          );

  }
}
