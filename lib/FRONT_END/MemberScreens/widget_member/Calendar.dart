import 'dart:async';

import 'package:bethel_app_final/BACK_END/Services/Functions/Authentication.dart';
import 'package:bethel_app_final/BACK_END/Services/Functions/Users.dart';
import 'package:bethel_app_final/BACK_END/models/Weather.dart';
import 'package:bethel_app_final/FRONT_END/MemberScreens/screen_pages/appointment_source_directory/add_appointment.dart';
import 'package:bethel_app_final/FRONT_END/MemberScreens/widget_member/Calendar_Controller/Controller.dart';
import 'package:bethel_app_final/FRONT_END/constant/WeatherBottomSheet.dart';
import 'package:bethel_app_final/FRONT_END/constant/color.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class CustomCalendar extends StatefulWidget {
  final String type;
  const CustomCalendar({super.key, required this.type});

  @override
  State<CustomCalendar> createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<CustomCalendar> {
  late TableCalendar _tableCalendar;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  int currentYear = DateTime.now().year;
  UserStorage storage = UserStorage();
  TapAuth tapAuth = TapAuth();
  late Future _pendingDate;
  late Future _disabledDate;
  late Future _approvedDate;

  late Future<List<Weather>> _weatherCondition;
  List<DateTime> disabledDays = [];
  List<DateTime> pendingDays = [];
  List<DateTime> approvedDate = [];
  List<Weather> weatherContionList = [];

  @override
  void initState() {
    Controllers weatherController = Controllers();
    _weatherCondition = weatherController
        .loadWeather()
        .then((_) => weatherController.getWeather());
    _pendingDate = storage.getPendingDate(tapAuth.auth.currentUser!.uid);
    _disabledDate = storage.getDisableDay();
    _approvedDate =
        storage.getApprovedDate(tapAuth.auth.currentUser!.uid, widget.type);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(automaticallyImplyLeading: false),
        body: Padding(
          padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
          child: Column(
            children: [
              if (widget.type == "members")
                const Text(
                  "Request Appointment", // The more you know ;)
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                const Text(
                  "Calendar",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 15),
              const Divider(
                color: appGreen,
              ),
              FutureBuilder(
                future: Future.wait([
                  _pendingDate,
                  _disabledDate,
                  _approvedDate,
                  _weatherCondition
                ]),
                builder: (context, snapshot) {
                  var screen = MediaQuery.of(context).size;
                  double screenX = screen.width;
                  double screenY = screen.height;

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: Colors.green.shade100,
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text("SOMETHING HAPPENED X_X"),
                    );
                  } else {
                    disabledDays = snapshot.data![1];
                    pendingDays = snapshot.data![0];
                    approvedDate = snapshot.data![2];
                    weatherContionList = snapshot.data![3];
                    return TableCalendar(
                      rowHeight: screenY / 10,
                      focusedDay: _focusedDay,
                      firstDay: DateTime.utc(DateTime.now().year,
                          DateTime.now().month, DateTime.now().day),
                      lastDay: DateTime.utc(DateTime.now().year + 1, 2, 1),
                      selectedDayPredicate: (day) {
                        return isSameDay(_selectedDay, day);
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      calendarFormat: _calendarFormat,
                      onFormatChanged: (format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      },
                      calendarStyle: const CalendarStyle(
                          // selectedDecoration: BoxDecoration(
                          //     shape: BoxShape.circle, color: Colors.blueAccent),
                          weekendTextStyle: TextStyle(color: Colors.red),
                          outsideDaysVisible: false,
                          weekNumberTextStyle: TextStyle(color: Colors.blue)),
                      onDayLongPressed: (selectedDay, focusedDay) {
                        if (widget.type == "admins") {
                          var setDisableDays = <String, dynamic>{
                            "date": Timestamp.fromDate(_selectedDay),
                            "userID": tapAuth.getCurrentUserUID(),
                            "name": tapAuth.auth.currentUser!.displayName
                          };
                          storage.setDisableDay(
                              setDisableDays, tapAuth.auth.currentUser!.uid);
                        }
                      },
                      headerStyle: const HeaderStyle(
                          leftChevronIcon: Icon(Icons.chevron_left_rounded),
                          rightChevronIcon: Icon(Icons.chevron_right_rounded),
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w400)),
                      pageAnimationEnabled: true,
                      pageAnimationCurve: Curves.decelerate,
                      onDisabledDayLongPressed: (day) {
                        if (widget.type == "admins") {
                          for (var disableDay in disabledDays) {
                            if (day.month == disableDay.month &&
                                day.day == disableDay.day &&
                                day.year == disableDay.year) {
                              storage.unsetDisableDay(
                                  day.day, day.month, day.year);
                              break; // Stops the loop for no more unecesarry checks
                            }
                          }
                        }
                      },
                      onCalendarCreated: (pageController) {},
                      enabledDayPredicate: (day) {
                        for (int i = 0; i < disabledDays.length; i++) {
                          if (disabledDays[i].month == day.month &&
                              disabledDays[i].day == day.day &&
                              disabledDays[i].year == day.year) {
                            return false;
                          }
                        }
                        return true;
                      },
                      calendarBuilders: CalendarBuilders(
                        todayBuilder: (context, day, focusedDay) =>
                            todayBuilder(day),
                        selectedBuilder: (context, day, focusedDay) {
                          // Gi try nakog method ni sila and its a fucking mistake fuck this calendar and gl sa pag basa ani
                          for (int i = 0; i < 14; i++) {
                            if (focusedDay.day ==
                                    weatherContionList[i].dateTime.day &&
                                focusedDay.month ==
                                    weatherContionList[i].dateTime.month &&
                                focusedDay.year ==
                                    weatherContionList[i].dateTime.year) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(50),
                                    child: Container(
                                        height: 35,
                                        width: 35,
                                        color: calendarSelected,
                                        child: Center(
                                            child: Text(
                                          '${focusedDay.day}',
                                          style: selectedText(),
                                        ))),
                                  ),
                                  SizedBox(
                                    height: 30,
                                    child: IconUpButton(
                                        focusedDay, weatherContionList[i]),
                                  )
                                ],
                              );
                            }
                          }
                        },
                        markerBuilder: (context, day, events) =>
                            marketBuilder(day),
                        disabledBuilder: (context, day, focusedDay) =>
                            disabledBuilder(day),
                        defaultBuilder: (context, day, focusedDay) {
                          for (int i = 0; i < pendingDays.length; i++) {
                            if (pendingDays[i].month == day.month &&
                                pendingDays[i].day == day.day &&
                                pendingDays[i].year == day.year) {
                              return Container(
                                decoration: BoxDecoration(
                                    color: Colors.yellow.shade200,
                                    border: Border.all(
                                        color: Colors.black26,
                                        strokeAlign:
                                            BorderSide.strokeAlignInside)),
                                child: Center(
                                  child: Text(
                                    "${day.day}",
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ),
                              );
                            }
                          }
                          for (int i = 0; i < approvedDate.length; i++) {
                            if (approvedDate[i].month == day.month &&
                                approvedDate[i].day == day.day &&
                                approvedDate[i].year == day.year) {
                              return Container(
                                decoration: BoxDecoration(
                                    color: Colors.lightGreen.shade200,
                                    border: Border.all(
                                        color: Colors.black26,
                                        strokeAlign:
                                            BorderSide.strokeAlignInside)),
                                child: Center(
                                  child: Text(
                                    "${day.day}",
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ),
                              );
                            }
                          }
                          //fuck me nganong dle nako ni mahimog method nalang. old calendar guro ang gamit lmao
                          //for NON-focused days ni
                          for (int i = 0; i < 14; i++) {
                            if (day.day == weatherContionList[i].dateTime.day &&
                                day.month ==
                                    weatherContionList[i].dateTime.month &&
                                day.year ==
                                    weatherContionList[i].dateTime.year) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    '${day.day}',
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                  IconUpButton(day, weatherContionList[i])
                                ],
                              );
                            }
                          }
                        },
                        dowBuilder: (context, day) {
                          final red = DateFormat.E().format(day);
                          final blue = DateFormat.E().format(day);
                          if (day.weekday == DateTime.sunday ||
                              day.weekday == DateTime.saturday) {
                            return Center(
                              child: Text(
                                red,
                                style: const TextStyle(color: Colors.red),
                              ),
                            );
                          } else {
                            return Center(
                              child: Text(
                                blue,
                                style: const TextStyle(color: Colors.blue),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  }
                },
              ),
              if (widget.type == 'members')
                AppointmentMakerButton()
              else
                EventMakerButton(context),
            ],
          ),
        ));
  }

  Widget IconUpButton(DateTime date, Weather weather) {
    return IconButton(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
        iconSize: 18,
        onPressed: () => showModalBottomSheet(
            context: context,
            builder: (context) => WeatherSheetTab(
                  weather: weather,
                )),
        icon: const Icon(
          Icons.keyboard_arrow_up,
        ));
  }

  Widget disabledBuilder(DateTime day) {
    return Container(
      decoration: const BoxDecoration(color: Colors.black26),
      child: Center(
        child: Text(
          "${day.day}",
          style: const TextStyle(color: Colors.black),
        ),
      ),
    );
  }

  Widget marketBuilder(DateTime day) {
    for (int i = 0; i < 14; i++) {
      if (day.day == weatherContionList[i].dateTime.day &&
          day.month == weatherContionList[i].dateTime.month &&
          day.year == weatherContionList[i].dateTime.year) {
        return Positioned(
          top: 1,
          child: Image.asset(
            determineWeather(weatherContionList[i].weatherCode),
            height: 15,
            width: 15,
          ),
        );
      }
    }
    return Center();
  }

// TODO MAKE THE SHOWMODAL SHIT
  Widget todayBuilder(DateTime day) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: Container(
              height: 35,
              width: 35,
              color: calendarSelected,
              child: Center(
                  child: Text(
                '${day.day}',
                style: selectedText(),
              ))),
        ),
        SizedBox(
          height: 30,
          child: IconUpButton(day, weatherContionList[0]),
        )
      ],
    );
  }

  TextStyle selectedText() {
    return const TextStyle(color: Colors.white);
  }

  Widget AppointmentMakerButton() {
    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        backgroundColor: appGreen5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddAppointment(
                firstDate: DateTime.utc(currentYear, 1, 1),
                lastDate: DateTime(currentYear + 1, 1, 1, 0),
                selectedDate: _selectedDay,
                type: 'members'),
          ),
        );
      },
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 10),
          Center(
            child: Text(
              "  Appointment",
              style: TextStyle(color: appBlack, fontSize: 14),
            ),
          )
        ],
      ),
    );
  }

  Widget EventMakerButton(BuildContext context) {
    final DateTime currentDate = DateTime.now();
    final DateTime firstDate = DateTime(currentDate.year - 1);
    final DateTime lastDate = DateTime(currentDate.year + 1);
    final DateTime selectedDate = currentDate;

    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        backgroundColor: appGreen5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddAppointment(
              firstDate: DateTime.utc(currentYear, 1, 1),
              lastDate: DateTime(currentYear + 1, 1, 1, 0),
              selectedDate: _selectedDay,
              type: 'admins', // Provide a church event value
            ),
          ),
        );
      },
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 10),
          Center(
            child: Text(
              "  Events",
              style: TextStyle(color: Colors.black, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

// Method nani kay kapoy naaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
  String determineWeather(int weatherCodeNumber) {
    //Pwede rani sila sa json file pero kapoy naman mag himog async functions haha
    try {
      Map<int, String> weatherCodeMap = {
        0: 'assets/icon/sunny.png',
        1: 'assets/icon/sunny.png',
        2: 'assets/icon/cloud.png',
        3: 'assets/icon/cloud.png',
        45: 'assets/icon/cloud.png',
        48: 'assets/icon/cloud.png',
        51: 'assets/icon/drizzle.png',
        53: 'assets/icon/drizzle.png',
        55: 'assets/icon/drizzle.png',
        56: 'assets/icon/drizzle.png',
        57: 'assets/icon/drizzle.png',
        61: 'assets/icon/rain.png',
        63: 'assets/icon/rain.png',
        65: 'assets/icon/rain.png',
        66: 'assets/icon/rain.png',
        67: 'assets/icon/rain.png',
        80: 'assets/icon/rain.png',
        81: 'assets/icon/rain.png',
        82: 'assets/icon/rain.png',
        95: 'assets/icon/thunderstorm.png',
        96: 'assets/icon/thunderstorm.png'
      };
      return weatherCodeMap[weatherCodeNumber]!;
    } catch (e) {
      return 'Weather not found';
    }
  }
} //
