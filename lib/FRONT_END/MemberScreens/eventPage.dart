import 'dart:convert';
import 'dart:developer';
import 'package:bethel_app_final/BACK_END/Services/Functions/Authentication.dart';
import 'package:bethel_app_final/BACK_END/Services/Functions/Users.dart';
import 'package:bethel_app_final/FRONT_END/MemberScreens/screen_pages/event_screen_pages/event_source_directory/edit_event.dart';
import 'package:bethel_app_final/FRONT_END/MemberScreens/screen_pages/event_screen_pages/history.dart';
import 'package:bethel_app_final/FRONT_END/constant/color.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class EventPage extends StatefulWidget {
  const EventPage({Key? key}) : super(key: key);

  @override
  State<EventPage> createState() => _EventPageState();
}

void signUserOut() {
  FirebaseAuth.instance.signOut();
}

class _EventPageState extends State<EventPage> {
  final TapAuth tapAuth = TapAuth();
  late Stream<QuerySnapshot> _approvedAppointmentsStream;
  late Stream<QuerySnapshot> _pendingAppointmentsStream;
  Map<String, bool> showOptionsMap = {};
  bool sortByMonth = false;
  bool sortByDay = false;
  int clickCount = 0;
  List<String> weatherAlertsQueue = [];
  bool isAlertShowing = false;
  bool isNavigatingToEditEvent = false;
  @override
  void initState() {
    super.initState();
    _initializeStream();



  }

  Future<void> _initializeStream() async {
    try {
      final currentUser  = tapAuth.getCurrentUser ();
      if (currentUser  != null) {
        _approvedAppointmentsStream =
            UserStorage().fetchApprovedAppointments(currentUser .uid);
        _pendingAppointmentsStream =
            UserStorage().fetchPendingAppointments(currentUser .uid);
      } else {
        throw ArgumentError("Current user not found.");
      }
    } catch (e) {
      log("Error initializing stream: $e");
    }
  }

  Future<void> deletePendingRequest(String uid, String documentId) async {
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc("members")
          .collection(uid)
          .doc("Event")
          .collection("Pending Appointment")
          .doc(documentId)
          .delete();
    } catch (e) {
      print('Error deleting document: $e');
    }
  }

  String getCurrentUserId() {
    final currentUser = FirebaseAuth.instance.currentUser;
    return currentUser?.uid ?? '';
  }

  //Mo check sa weather condition sa specific date
  Future<void> checkWeatherForEvent(String appointmentType, DateTime date, String documentId) async {
    String apiKey = '8f3a453d50754f8180720342240111';
    String formattedDate = '${date.year}-${date.month}-${date.day}';
    String url = 'https://api.weatherapi.com/v1/forecast.json?key=$apiKey&q=Tagum City,Davao del Norte&days=7&dt=$formattedDate';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        log("Weather API Response: $data");

        // Get the forecast for the specified date
        String forecastDate = DateFormat('yyyy-MM-dd').format(date);
        var forecast = data['forecast']['forecastday'].firstWhere(
              (day) => day['date'] == forecastDate,
          orElse: () => null,
        );

        if (forecast != null) {
          String weatherCondition = forecast['day']['condition']['text'];
          bool badWeatherPredicted =  weatherCondition.toLowerCase().contains('rain') ||
                                      weatherCondition.toLowerCase().contains('thunderstorm') ||
                                      weatherCondition.toLowerCase().contains('snow') ||
                                      weatherCondition.toLowerCase().contains('sunny') ||
                                      weatherCondition.toLowerCase().contains('mist') ||
                                      weatherCondition.toLowerCase().contains('fog') ||
                                      weatherCondition.toLowerCase().contains('windy') ||
                                      weatherCondition.toLowerCase().contains('extreme heat') ||
                                      weatherCondition.toLowerCase().contains('extreme cold');

          if (badWeatherPredicted) {
            enqueueWeatherAlert(appointmentType, date, weatherCondition, documentId);
          }
        } else {
          log("No forecast data available for the specified date.");
        }
      } else {
        throw Exception('Failed to load weather data with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error checking weather: $e');
    }
  }

  //Ibutang sa Queue and mga dialog para dli magsabay og show
  void enqueueWeatherAlert(String appointmentType, DateTime date, String weatherCondition, String documentId) {
    String formattedDate = DateFormat('MMMM d, y').format(date);
    String alertMessage = 'Your $appointmentType on $formattedDate may be affected by $weatherCondition. Consider rescheduling your event.';

    weatherAlertsQueue.add(alertMessage);
    if (!isAlertShowing) {
      showNextWeatherAlert(documentId, date);
    }
  }

  //dri gi store ang next sa queue na dialog
  Future<void> showNextWeatherAlert(String documentId, DateTime date) async {
    if (weatherAlertsQueue.isNotEmpty && !isNavigatingToEditEvent) {
      isAlertShowing = true;
      String alertMessage = weatherAlertsQueue.removeAt(0);
      await showWeatherAlertDialog(alertMessage, documentId, date);
      await Future.delayed(Duration(milliseconds: 100));
      await showNextWeatherAlert(documentId, date);
    } else {
      isAlertShowing = false;
    }
  }

  //alert Dialog
  Future<void> showWeatherAlertDialog(String alertMessage, String documentId, DateTime date) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.blue[50],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 30),
              SizedBox(width: 10),
              Text('Weather Alert'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                alertMessage,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Dismiss', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                isNavigatingToEditEvent = true; // ma dismiss ang mga previous dialog sa queue
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditEvent(
                      documentId: documentId,
                      firstDate: date,
                      lastDate: date,
                      isAdmin: false,
                    ),
                  ),
                );
              },
              child: Text('Reschedule', style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }


  List<DocumentSnapshot> sortAppointmentsByMonth(QuerySnapshot snapshot) {
    List<DocumentSnapshot> appointments = snapshot.docs;
    if (sortByMonth) {
      appointments.sort((a, b) {
        DateTime dateA =
        (a.data() as Map<String, dynamic>)["date"].toDate();
        DateTime dateB =
        (b.data() as Map<String, dynamic>)["date"].toDate();
        return dateA.month.compareTo(dateB.month);
      });
    }
    return appointments;
  }


  List<DocumentSnapshot> sortAppointmentsByDay(
      List<DocumentSnapshot> appointments) {
    appointments.sort((a, b) {
      DateTime dateA =
      (a.data() as Map<String, dynamic>)["date"].toDate();
      DateTime dateB =
      (b.data() as Map<String, dynamic>)["date"].toDate();
      return dateA.day.compareTo(dateB.day);
    });
    return appointments;
  }


  bool isAppointmentCompleted(DateTime eventDate) {
    return eventDate.isBefore(DateTime.now().subtract(Duration(days: 1)));
  }

  @override
  Widget build(BuildContext context) {
    if (_pendingAppointmentsStream == null ||
        _approvedAppointmentsStream == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 40, left: 20, right: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      clickCount++;
                      if (clickCount % 2 == 1) {
                        sortByMonth = true;
                        sortByDay = false;
                      } else {
                        sortByMonth = false;
                        sortByDay = true;
                      }
                    });
                  },
                  icon: const Icon(Icons.sort),
                ),
                const Text(
                  "Events",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.push(context,
                      MaterialPageRoute(
                          builder: (context) => const HistoryPage()
                      ),
                    );
                  },
                  icon: const Icon(Icons.history),
                ),
              ],
            ),
            const SizedBox(height: 15),
            const Divider(
              color: Colors.green,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Approved requests',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _approvedAppointmentsStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text(
                              'Error: ${snapshot.error}'));
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text(
                              'No approved appointment...',
                              style: TextStyle(fontSize: 18, color: appGrey),
                            ),
                          );
                        }
                        List<DocumentSnapshot> sortedAppointments = snapshot
                            .data!.docs;
                        if (sortByMonth) {
                          sortedAppointments = sortAppointmentsByMonth(snapshot
                              .data!);
                        } else if (sortByDay) {
                          sortedAppointments = sortAppointmentsByDay(
                              snapshot.data!.docs);
                        }
                        sortedAppointments = sortedAppointments
                            .where((document) =>
                        !isAppointmentCompleted(
                            (document.data() as Map<String, dynamic>)["date"]
                                .toDate()))
                            .toList();

                        return ListView.builder(
                          itemCount: sortedAppointments.length,
                          itemBuilder: (context, index) {
                            final document = sortedAppointments[index];
                            final id = document.id;
                            Map<String, dynamic> data = document.data() as Map<
                                String,
                                dynamic>;
                            Timestamp timeStamp = data["date"];
                            String formattedDate = DateFormat('MMMM d, y')
                                .format(timeStamp.toDate());

                            return Card(
                              color: Colors.green.shade200,
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 4),
                              child: ListTile(
                                title: Text(
                                    'Appointment: ${data['appointmenttype'] ??
                                        ''}'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Description: ${data['description'] ??
                                        ''}'),
                                    Text('Date: $formattedDate'),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _pendingAppointmentsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No pending appointment...',
                        style: TextStyle(fontSize: 18, color: appGrey),
                      ),
                    );
                  }
                  List<DocumentSnapshot> sortedAppointments = snapshot.data!
                      .docs;
                  if (sortByMonth) {
                    sortedAppointments =
                        sortAppointmentsByMonth(snapshot.data!);
                  } else if (sortByDay) {
                    sortedAppointments =
                        sortAppointmentsByDay(snapshot.data!.docs);
                  }
                  return ListView(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Pending requests',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      ...sortedAppointments.map((DocumentSnapshot document) {
                        final id = document.id;
                        Map<String, dynamic> data = document.data() as Map<
                            String,
                            dynamic>;
                        Timestamp timeStamp = data["date"];
                        DateTime dateTime = timeStamp.toDate();
                        String formattedDate = DateFormat('MMMM d, y').format(
                            dateTime);

                        // Check ang weather sa appointment date pero yawa  di mo ganaaaaa
                        checkWeatherForEvent(data['appointmenttype'], dateTime, document.id);

                        return Card(
                          color: Colors.amber.shade200,
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 4),
                          child: ListTile(
                            title: Text(
                                'Appointment: ${data['appointmenttype'] ??
                                    ''}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Description: ${data['description'] ??
                                    ''}'),
                                Text('Date: $formattedDate'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.info_outline),
                                  onPressed: () {
                                    setState(() {
                                      showOptionsMap[id] =
                                      !(showOptionsMap[id] ?? false);
                                    });
                                  },
                                ),
                                if (showOptionsMap[id] ?? false)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                              Icons.edit, color: appGreen,
                                              size: 24.0),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    EditEvent(
                                                      documentId: document.id,
                                                      firstDate: DateTime.now(),
                                                      lastDate: DateTime.now(),
                                                      isAdmin: false,
                                                    ),
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 8.0),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.delete, color: Colors.red,
                                              size: 24.0),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: const Text(
                                                      "Confirm Delete"),
                                                  content: const Text(
                                                      "Are you sure you want to delete this request?"),
                                                  actions: <Widget>[
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                      child: const Text(
                                                          "Cancel"),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        final uid = getCurrentUserId();
                                                        if (uid.isNotEmpty) {
                                                          deletePendingRequest(
                                                              uid, document.id);
                                                          Navigator.of(context)
                                                              .pop();
                                                        } else {
                                                          print(
                                                              'User  is not logged in.');
                                                        }
                                                      },
                                                      child: const Text(
                                                          "Delete",
                                                          style: TextStyle(
                                                              color: appRed)),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}