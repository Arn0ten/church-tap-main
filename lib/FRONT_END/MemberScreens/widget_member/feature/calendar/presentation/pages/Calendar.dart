import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CustomRefactorCalendar extends StatefulWidget {
  const CustomRefactorCalendar({super.key});

  @override
  State<CustomRefactorCalendar> createState() => _CustomRefactorCalendarState();
}

class _CustomRefactorCalendarState extends State<CustomRefactorCalendar> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Padding(
          padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
          child: Column(
            children: [
              CustomRefactorCalendar()
            ],
          ),
        ));
  }
}
