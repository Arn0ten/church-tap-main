
import 'package:bethel_app_final/BACK_END/Services/Functions/Users.dart';
import 'package:bethel_app_final/FRONT_END/MemberScreens/screen_pages/event_screen_pages/event_source_directory/edit_event.dart';
import 'package:bethel_app_final/FRONT_END/constant/color.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({Key? key}) : super(key: key);

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

void signUserOut() {
  FirebaseAuth.instance.signOut();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final UserStorage userStorage = UserStorage();
  late Stream<QuerySnapshot> _approvedAppointmentsStream;
  late Stream<QuerySnapshot> _churchEventsStream;
  String _selectedEventType = 'Upcoming';
  bool sortByMonth = false;
  bool sortByDay = false;
  int clickCount = 0;
  Map<String, bool> showOptionsMap = {};


  @override
  void initState() {
    super.initState();
    _initializeStreams();
  }

  Future<void> _initializeStreams() async {
    try {
      _approvedAppointmentsStream = userStorage.fetchAllApprovedAppointments();
      _churchEventsStream = userStorage.fetchCreateMemberEvent();
    } catch (e) {
      print('Error initializing streams: $e');
    }
  }

  String formatDateTime(Timestamp? timeStamp) {
    if (timeStamp == null) {
      return 'No date available';
    }
    DateTime dateTime = timeStamp.toDate();
    List<String> months = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    return "${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}";
  }

  List<DocumentSnapshot> _sortEventsByMonth(List<DocumentSnapshot> events) {
    events.sort((a, b) {
      DateTime dateA = (a.data() as Map<String, dynamic>)["date"].toDate();
      DateTime dateB = (b.data() as Map<String, dynamic>)["date"].toDate();
      return dateA.month.compareTo(dateB.month);
    });
    return events;
  }

  List<DocumentSnapshot> _sortEventsByDay(List<DocumentSnapshot> events) {
    events.sort((a, b) {
      DateTime dateA = (a.data() as Map<String, dynamic>)["date"].toDate();
      DateTime dateB = (b.data() as Map<String, dynamic>)["date"].toDate();
      return dateA.day.compareTo(dateB.day);
    });
    return events;
  }

  bool isEventCompleted(DocumentSnapshot event) {
    Timestamp timeStamp = event["date"];
    DateTime eventDate = timeStamp.toDate();
    return eventDate.isBefore(DateTime.now().subtract(Duration(days: 1)));
  }

  String getCurrentUserId() {
    final currentUser = FirebaseAuth.instance.currentUser;
    return currentUser?.uid ?? '';
  }

  Future<void> deletePendingRequest(String uid, String documentId) async {
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc("admins")
          .collection(uid)
          .doc("Event")
          .collection("Church Event")
          .doc(documentId)
          .delete();
    } catch (e) {
      print('Error deleting document: $e');
    }
  }



  @override
  Widget build(BuildContext context) {
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
                  "Admin Events",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 50),
              ],
            ),
            const SizedBox(height: 15),
            const Divider(
              color: appGreen,
            ),
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
                'Members approved appointments',
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
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'No ${_selectedEventType.toLowerCase()} yet...',
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    );
                  }
                  List<DocumentSnapshot> events = snapshot.data!.docs;
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
                    events = _sortEventsByMonth(events);
                  } else if (sortByDay) {
                    events = _sortEventsByDay(events);
                  }
                  return ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      return _buildApprovedAppointmentCard(events[index]);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
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
              child: StreamBuilder<QuerySnapshot>(
                stream: _churchEventsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'No ${_selectedEventType.toLowerCase()} yet...',
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    );
                  }
                  List<DocumentSnapshot> events = snapshot.data!.docs;
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
                    events = _sortEventsByMonth(events);
                  } else if (sortByDay) {
                    events = _sortEventsByDay(events);
                  }
                  return ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      return _buildChurchEventCard(events[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovedAppointmentCard(DocumentSnapshot event) {
    Map<String, dynamic> data = event.data() as Map<String, dynamic>;
    Timestamp timeStamp = data["date"];
    String formattedDate = formatDateTime(timeStamp);
    bool completed = isEventCompleted(event);
    Color cardColor = completed ? Colors.grey.shade200 : Colors.green.shade200;
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
    return Card(
      color: cardColor,
      elevation: 2,
      margin: const EdgeInsets.symmetric(
          vertical: 8, horizontal: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        title: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.green.shade300,
              child: getAppointmentIcon(
                data['appointmenttype'] ?? 'Unknown Type',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['appointmenttype'] ?? 'Unknown Type',
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
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Email: ${data['email'] ?? ''}',
            ),
            const SizedBox(height: 4),
            Text(
              'Date: $formattedDate',
            ),
            const SizedBox(height: 4),
            Text(
              'Description: ${data['description'] ?? ''}',
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChurchEventCard(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    Timestamp timeStamp = data["date"];
    String formattedDate = formatDateTime(timeStamp);

    String id = document.id;
    bool completed = isEventCompleted(document); // Check if event is completed
    Color cardColor = completed ? Colors.grey.shade200 : Colors.green.shade200; // Set color based on completion

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

    return Card(
      color: cardColor,
      elevation: 2,
      margin: const EdgeInsets.symmetric(
          vertical: 8, horizontal: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        title: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.green.shade300,
              child: getAppointmentIcon(
                data['appointmenttype'] ?? 'Unknown Type',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['appointmenttype'] ?? 'Unknown Type',
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
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Email: ${data['email'] ?? ''}',
            ),
            const SizedBox(height: 4),
            Text(
              'Date: $formattedDate',
            ),
            const SizedBox(height: 4),
            Text(
              'Description: ${data['description'] ?? ''}',
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
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
                    const SizedBox(width: 8.0),
                    IconButton(
                      icon: const Icon(Icons.delete,
                          color: Colors.red,
                          size: 24.0),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder:
                              (BuildContext context) {
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
                                      "Cancel" ,
                                    style: TextStyle(
                                    color: appBlack
                                  ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    final uid =
                                    getCurrentUserId();
                                    if (uid.isNotEmpty) {
                                      deletePendingRequest(
                                          uid,
                                          document.id);
                                      Navigator.of(context)
                                          .pop();
                                    } else {
                                      print(
                                          'User is not logged in.');
                                    }
                                  },
                                  child: const Text(
                                    "Delete",
                                    style: TextStyle(
                                        color: appRed),
                                  ),
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
  }

}
