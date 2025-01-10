  import 'dart:ui';
  import 'package:bethel_app_final/BACK_END/Services/Functions/Users.dart';
  import 'package:bethel_app_final/FRONT_END/MemberScreens/screen_pages/home_screen_pages/mapstoragescreen.dart';
  import 'package:bethel_app_final/FRONT_END/MemberScreens/screen_pages/home_screen_pages/search_button_details.dart';
  import 'package:bethel_app_final/FRONT_END/MemberScreens/weather_page.dart';
  import 'package:bethel_app_final/FRONT_END/constant/color.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:flutter/cupertino.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
  
  class MemberHomePage extends StatefulWidget {
    const MemberHomePage({Key? key}) : super(key: key);
  
    @override
    State<MemberHomePage> createState() => _MemberHomePageState();
  }
  
  class _MemberHomePageState extends State<MemberHomePage> {
    final UserStorage userStorage = UserStorage();
    String _selectedEventType = 'Upcoming';
    bool _isSearching = false;
    bool sortByMonth = false;
    bool sortByDay = false;
    int clickCount = 0;
  
    String formatDateTime(Timestamp? timeStamp) {
      if (timeStamp == null) {
        return " No date available";
      }
      DateTime dateTime = timeStamp.toDate();
      List<String> months = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
      ];
      return "${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}";
    }
  
    bool isEventCompleted(DocumentSnapshot event) {
      Timestamp timeStamp = event["date"];
      DateTime eventDate = timeStamp.toDate();
      return eventDate.isBefore(DateTime.now().subtract(Duration(days: 1)));
    }
  
    List<DocumentSnapshot> sortEventsByMonth(List<DocumentSnapshot> events) {
      events.sort((a, b) {
        DateTime dateA = (a.data() as Map<String, dynamic>)["date"].toDate();
        DateTime dateB = (b.data() as Map<String, dynamic>)["date"].toDate();
        return dateA.month.compareTo(dateB.month);
      });
      return events;
    }
  
    List<DocumentSnapshot> sortEventsByDay(List<DocumentSnapshot> events) {
      events.sort((a, b) {
        DateTime dateA = (a.data() as Map<String, dynamic>)["date"].toDate();
        DateTime dateB = (b.data() as Map<String, dynamic>)["date"].toDate();
        return dateA.day.compareTo(dateB.day);
      });
      return events;
    }
  
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: 120,
          flexibleSpace: Stack(
            children: [
  
              Positioned(
                left: 20.0,
                right: 20.0,
                top: 40.0,
                child: Row(
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
                      style: IconButton.styleFrom(
                        shape: const CircleBorder(
                          side: BorderSide(color: appGrey, width: 1),
                        ),
                      ),
                      icon: const Icon(Icons.sort),
                    ),
                    //Icon sa weather page
                    IconButton(
                      icon: Icon(Icons.cloud, color: Colors.black),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const WeatherPage()),
                        );
                      },
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MapStorageScreen(),
                          ),
                        );
                      },
                      child: Hero(
                        tag: '',
                        child: SearchButton(
                          isSearching: _isSearching,
                        ),
                      ),
  
                    ),
                  ],
                ),
              ),
              const Positioned(
                left: 20.0,
                right: 20.0,
                top: 110.0,
                child: Divider(
                  color: appGreen,
                ),
              ),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.only(top: 10, left: 20, right: 20),
  
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedEventType,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedEventType = newValue!;
                      });
                    },
                    items: <String>['Upcoming', 'Ongoing', 'Completed']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: const TextStyle(
                            color: appBlack,
                            fontSize: 14,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
  
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Church events',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
  
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: userStorage.fetchCreateMemberEvent(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Scaffold(
                              body: Center(
                                child: LoadingAnimationWidget.staggeredDotsWave(
                                  color: Colors.green, // Customize the color
                                  size: 50.0, // Customize the size
                                ),
                              ),
                            );
                          } else if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          } else if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                            return const Center(
                              child: Text(
                                'No church event available yet!',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          } else {
                            List<DocumentSnapshot> events = snapshot.data!.docs;
  
                            // Filter events based on the selected event type
                            if (_selectedEventType == 'Upcoming') {
                              events = events.where((event) {
                                DateTime eventDate = (event['date'] as Timestamp).toDate();
                                return eventDate.isAfter(DateTime.now());
                              }).toList();
                            } else if (_selectedEventType == 'Ongoing') {
                              events = events.where((event) {
                                DateTime eventDate = (event['date'] as Timestamp).toDate();
                                DateTime currentDate = DateTime.now();
                                return eventDate.year == currentDate.year &&
                                    eventDate.month == currentDate.month &&
                                    eventDate.day == currentDate.day;
                              }).toList();
                            } else {
                              events = events.where((event) {
                                DateTime eventDate = (event['date'] as Timestamp).toDate();
                                return isEventCompleted(event);
                              }).toList();
                            }
  
  
  
  
                            if (sortByMonth) {
                              events = sortEventsByMonth(events);
                            } else if (sortByDay) {
                              events = sortEventsByDay(events);
                            }
  
                            if (events.isEmpty) {
                              return const Center(
                                child: Text(
                                  'No events posted yet...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            } else {
                              return ListView.builder(
                                itemCount: events.length,
                                itemBuilder: (context, index) {
                                  final event = events[index];
                                  Timestamp timeStamp = event["date"];
                                  DateTime dateTime = timeStamp.toDate();
                                  List<String> months = [
                                    "January",
                                    "February",
                                    "March",
                                    "April",
                                    "May",
                                    "June",
                                    "July",
                                    "August",
                                    "September",
                                    "October",
                                    "November",
                                    "December"
                                  ];
                                  String formattedDate =
                                      "${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}";
                                  // Function to return an appropriate icon based on the appointment type
                                  Icon getAppointmentIcon(String appointmentType) {
                                    switch (appointmentType) {
                                    // Religious Services
                                      case 'Sunday Service':
                                      case 'Christmas Service':
                                        return Icon(FontAwesomeIcons.church, color: Colors.pink.shade800);
                                      case 'Easter Service':
                                        return const Icon(FontAwesomeIcons.egg, color: Colors.white);

                                    // Ceremonies
                                      case 'Wedding Ceremony':
                                        return Icon(FontAwesomeIcons.heart, color: Colors.red.shade800);
                                      case 'Funeral Service':
                                        return Icon(FontAwesomeIcons.skullCrossbones, color: Colors.grey.shade800);

                                    // Baptism and Communion
                                      case 'Baptism':
                                      case 'Communion Service':
                                      case 'Infant Dedication':
                                        return Icon(FontAwesomeIcons.dove, color: Colors.grey.shade300);

                                    // Visits and Missionary Work
                                      case 'Pastoral Visit':
                                      case 'Missionary Work':
                                        return Icon(FontAwesomeIcons.businessTime, color: Colors.blue.shade800);

                                    // Prayer and Fellowship
                                      case 'Prayer Meeting':
                                        return Icon(FontAwesomeIcons.handsPraying, color: Colors.teal.shade800);
                                      case 'Youth Fellowship':
                                      case 'Bible Study':
                                        return Icon(FontAwesomeIcons.bookOpen, color: Colors.orange.shade800);

                                    // Church and Community
                                      case 'Church Anniversary':
                                      case 'Community Outreach':
                                        return Icon(FontAwesomeIcons.peopleCarryBox, color: Colors.purple.shade800);

                                    // Music and Choir
                                      case 'Choir Practice':
                                        return Icon(FontAwesomeIcons.music, color: Colors.green.shade800);

                                    // Meals and Socials
                                      case 'Fellowship Meal':
                                        return Icon(FontAwesomeIcons.utensils, color: Colors.brown.shade800);
                                      case 'Anniversary Service':
                                        return Icon(FontAwesomeIcons.cakeCandles, color: Colors.yellow.shade800);

                                    // Certificates
                                      case 'Membership Certificate':
                                      case 'Baptismal Certificate':
                                        return Icon(FontAwesomeIcons.idCard, color: Colors.blueGrey.shade800);

                                    // Birthday Service
                                      case 'Birthday Service':
                                        return Icon(FontAwesomeIcons.cakeCandles, color: Colors.pink.shade600);

                                    // Default event icon
                                      default:
                                        return Icon(FontAwesomeIcons.calendarDays, color: Colors.green.shade800);
                                    }
                                  }
                                  bool completed = isEventCompleted(event); // Check if event is completed
                                  Color cardColor = completed ? Colors.grey.shade200 : Colors.green.shade200; // Set color based on completion

                                  return GestureDetector(
                                    onLongPress: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return Dialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16.0),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Stack(
                                                    children: [
                                                      // Close button in the top-right corner
                                                      Positioned(
                                                        right: 0,
                                                        top: 0,
                                                        child: IconButton(
                                                          icon: const Icon(Icons.close, color: Colors.black),
                                                          onPressed: () {
                                                            Navigator.of(context).pop(); // Close the dialog
                                                          },
                                                        ),
                                                      ),
                                                      // Content Section
                                                      Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              CircleAvatar(
                                                                radius: 24,
                                                                backgroundColor: Colors.green.shade300,
                                                                child: getAppointmentIcon(
                                                                  event['appointmenttype'] ?? 'Unknown Type',
                                                                ),
                                                              ),
                                                              const SizedBox(width: 16),
                                                              Expanded(
                                                                child: Column(
                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                  children: [
                                                                    Text(
                                                                      event['appointmenttype'] ?? 'Unknown Type',
                                                                      style: const TextStyle(
                                                                        fontSize: 18,
                                                                        fontWeight: FontWeight.bold,
                                                                        color: Colors.black87,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(height: 4),
                                                          const Text(
                                                            'By: Admin/Church',
                                                            style: TextStyle(fontSize: 14, color: Colors.grey),
                                                          ),
                                                          const SizedBox(height: 8),
                                                          Text(
                                                            'Description: ${event['description'] ?? ''}',
                                                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                                                          ),
                                                          const SizedBox(height: 4),
                                                          Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,

                                                            children: [
                                                              const SizedBox(height: 4),
                                                              Text(
                                                                'Date: $formattedDate',
                                                                style: const TextStyle(fontSize: 14, color: Colors.grey),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    child: Card(
                                      color: Colors.green.shade200,
                                      elevation: 2,
                                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                        title: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 24,
                                              backgroundColor: Colors.green.shade300,
                                              child: getAppointmentIcon(
                                                event['appointmenttype'] ?? 'Unknown Type',
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    event['appointmenttype'] ?? 'Unknown Type',
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 4),
                                            Text(
                                              'Date: $formattedDate',
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Description: ${event['description'] ?? ''}',
                                              style: const TextStyle(fontSize: 14, color: Colors.black87),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );

                                },
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
  
            ],
          ),
        ),
      );
    }
  }
