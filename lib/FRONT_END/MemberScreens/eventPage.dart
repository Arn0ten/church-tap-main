import 'dart:developer';
import 'package:bethel_app_final/BACK_END/Services/Functions/Authentication.dart';
import 'package:bethel_app_final/BACK_END/Services/Functions/Users.dart';
import 'package:bethel_app_final/FRONT_END/MemberScreens/screen_pages/event_screen_pages/event_source_directory/edit_event.dart';
import 'package:bethel_app_final/FRONT_END/MemberScreens/screen_pages/event_screen_pages/history.dart';
import 'package:bethel_app_final/FRONT_END/constant/color.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeStream();

  }

  Future<void> _initializeStream() async {
    try {
      final currentUser = tapAuth.getCurrentUser();
      if (currentUser != null) {
        _approvedAppointmentsStream =
            UserStorage().fetchApprovedAppointments(currentUser.uid);
        _pendingAppointmentsStream =
            UserStorage().fetchPendingAppointments(currentUser.uid);
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

  List<DocumentSnapshot> sortAppointmentsByMonth(
      QuerySnapshot snapshot) {
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

  // Check if appointment is completed (occurred before current date)
  bool isAppointmentCompleted(DateTime eventDate) {
    return eventDate.isBefore(DateTime.now().subtract(Duration(days: 1)));
  }
  @override
    Widget build(BuildContext context) {
      if (_pendingAppointmentsStream == null || _approvedAppointmentsStream == null) {
        return Scaffold(
          body: Center(
            child: LoadingAnimationWidget.staggeredDotsWave(
              color: Colors.green,
              size: 50,
            ),
          ),
        );
      }
      return Scaffold(
        body: Padding(
          padding: const EdgeInsets.only(top: 25, left: 20, right: 20),
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
                    "Requests",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(context,
                        MaterialPageRoute(
                            builder: (context) =>
                            const HistoryPage()
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
              const SizedBox(height: 50,
                child: Padding(
                  padding: EdgeInsets.only(top: 2,bottom: 2),
                  child: Text(
                    'Approved Appointment',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _approvedAppointmentsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Scaffold(
                        body: Center(
                          child: LoadingAnimationWidget.staggeredDotsWave(
                            color: appGreen, // Customize the color
                            size: 50.0, // Customize the size
                          ),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No approved appointment...',
                          style: TextStyle(fontSize: 18, color: appGrey),
                        ),
                      );
                    }

                    List<DocumentSnapshot> sortedAppointments = snapshot.data!.docs;
                    if (sortByMonth) {
                      sortedAppointments = sortAppointmentsByMonth(snapshot.data!);
                    } else if (sortByDay) {
                      sortedAppointments = sortAppointmentsByDay(snapshot.data!.docs);
                    }
                    sortedAppointments = sortedAppointments.where((document) =>
                    !isAppointmentCompleted((document.data() as Map<String, dynamic>)["date"].toDate()))
                        .toList();

                    return ListView.builder(
                      itemCount: sortedAppointments.length,
                      itemBuilder: (context, index) {
                        final document = sortedAppointments[index];
                        final id = document.id;
                        Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                        Timestamp timeStamp = data["date"];
                        DateTime dateTime = timeStamp.toDate();
                        List<String> months = [
                          "January", "February", "March", "April", "May", "June", "July",
                          "August", "September", "October", "November", "December"
                        ];
                        String formattedDate = "${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}";

                        // Function to return an appropriate icon based on the appointment type
                        Icon getAppointmentIcon(String appointmentType) {
                          switch (appointmentType) {
                          // Religious Services
                            case 'Sunday Service':
                            case 'Christmas Service':
                              return Icon(FontAwesomeIcons.church,
                                  color: Colors.pink.shade800);
                            case 'Easter Service':
                              return const Icon(FontAwesomeIcons.egg,
                                  color: Colors.white);

                          // Ceremonies
                            case 'Wedding Ceremony':
                              return Icon(FontAwesomeIcons.heart,
                                  color: Colors.red.shade800);
                            case 'Funeral Service':
                              return Icon(
                                  FontAwesomeIcons.skullCrossbones,
                                  color: Colors.grey.shade800);

                          // Baptism and Communion
                            case 'Baptism':
                            case 'Communion Service':
                            case 'Infant Dedication':
                              return Icon(FontAwesomeIcons.dove,
                                  color: Colors.grey.shade300);

                          // Visits and Missionary Work
                            case 'Pastoral Visit':
                            case 'Missionary Work':
                              return Icon(FontAwesomeIcons.businessTime,
                                  color: Colors.blue.shade800);

                          // Prayer and Fellowship
                            case 'Prayer Meeting':
                              return Icon(FontAwesomeIcons.handsPraying,
                                  color: Colors.teal.shade800);
                            case 'Youth Fellowship':
                            case 'Bible Study':
                              return Icon(FontAwesomeIcons.bookOpen,
                                  color: Colors.orange.shade800);

                          // Church and Community
                            case 'Church Anniversary':
                            case 'Community Outreach':
                              return Icon(FontAwesomeIcons.peopleCarryBox,
                                  color: Colors.purple.shade800);

                          // Music and Choir
                            case 'Choir Practice':
                              return Icon(FontAwesomeIcons.music,
                                  color: Colors.green.shade800);

                          // Meals and Socials
                            case 'Fellowship Meal':
                              return Icon(FontAwesomeIcons.utensils,
                                  color: Colors.brown.shade800);
                            case 'Anniversary Service':
                              return Icon(FontAwesomeIcons.cakeCandles,
                                  color: Colors.yellow.shade800);

                          // Certificates
                            case 'Membership Certificate':
                            case 'Baptismal Certificate':
                              return Icon(FontAwesomeIcons.idCard,
                                  color: Colors.blueGrey.shade800);

                          // Birthday Service
                            case 'Birthday Service':
                              return Icon(FontAwesomeIcons.cakeCandles,
                                  color: Colors.pink.shade600);

                          // Default event icon
                            default:
                              return Icon(FontAwesomeIcons.calendarDays,
                                  color: Colors.green.shade800);
                          }
                        }
// Function to determine if the appointment is ongoing or expired
                        String getAppointmentStatus(DateTime appointmentDate) {
                          DateTime currentDate = DateTime.now();
                          // Normalize the current date to remove the time component, so we only compare the dates
                          DateTime normalizedCurrentDate = DateTime(currentDate.year, currentDate.month, currentDate.day);

                          // If the appointment is before the current date, it's expired
                          if (appointmentDate.isBefore(normalizedCurrentDate)) {
                            return "Expired";
                          } else {
                            return "Ongoing"; // If the appointment is today or in the future, it's ongoing
                          }
                        }



// Function to return an appropriate badge widget
                        Widget getStatusBadge(String status) {
                          Color badgeColor = status == "Expired" ? Colors.red : Colors.green;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return Card(
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
                                  child: getAppointmentIcon(data['appointmenttype'] ?? 'Unknown Type'),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['appointmenttype'] ?? 'Unknown Type',
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                ),
                                getStatusBadge(getAppointmentStatus(dateTime)),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('Date: $formattedDate'),
                                const SizedBox(height: 4),
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: 'Description:  ',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                      ),
                                      TextSpan(
                                        text: '${data['description'] ?? ''}',
                                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
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
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 24,
                                                        backgroundColor: Colors.green.shade300,
                                                        child: getAppointmentIcon(data['appointmenttype'] ?? 'Unknown Type'),
                                                      ),
                                                      const SizedBox(width: 16),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              data['appointmenttype'] ?? 'Unknown Type',
                                                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),

                                                  const SizedBox(height: 8),
                                                  SingleChildScrollView(
                                                    child: Text.rich(
                                                      TextSpan(
                                                        children: [
                                                          const TextSpan(
                                                            text: 'Description:  ',
                                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                                          ),
                                                          TextSpan(
                                                            text: '${data['description'] ?? ''}',
                                                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      getStatusBadge(getAppointmentStatus(dateTime)),

                                                      Text('Date: $formattedDate', style: const TextStyle(fontSize: 14, color: Colors.grey)),
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
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.only(top: 2,bottom: 2),
            child: Text(
              'Pending Requests',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),


              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _pendingAppointmentsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Scaffold(
                        body: Center(
                          child: LoadingAnimationWidget.staggeredDotsWave(
                            color: appGreen, // Customize the color
                            size: 50.0, // Customize the size
                          ),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                          child: Text('Error: ${snapshot.error}'));
                    }
                    if (snapshot.data == null ||
                        snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No pending requests...',
                          style: TextStyle(fontSize: 18, color: appGrey),
                        ),

                      );
                    }
                    List<DocumentSnapshot> sortedAppointments =
                        snapshot.data!.docs;
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

                        ),
                        ...sortedAppointments.map((
                            DocumentSnapshot document,
                            ) {
                          final id = document.id;
                          Map<String, dynamic> data =
                          document.data() as Map<String, dynamic>;
                          Timestamp timeStamp = data["date"];
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
                          return Card(
                            color: Colors.amber.shade200,
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              title: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Colors.amber.shade300,
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
                                    'Date: $formattedDate',
                                  ),
                                  const SizedBox(height: 4),
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        const TextSpan(
                                          text: 'Description:  ',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        TextSpan(
                                          text: '${data['description'] ?? ''}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    maxLines: 2,  // Limits to 2 lines
                                    overflow: TextOverflow.ellipsis,  // Adds ellipsis if the text exceeds 2 lines
                                  ),
                                ],
                              ),


                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [

                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade300,
                                      borderRadius:
                                      BorderRadius.circular(8.0),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(FontAwesomeIcons.penToSquare,
                                              color: appGreen, size: 24.0),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    EditEvent(
                                                      documentId: document.id,
                                                      firstDate: DateTime.now(),
                                                      lastDate: DateTime.now(), isAdmin: false,
                                                    ),
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 8.0),
                                        IconButton(
                                          icon: const Icon(FontAwesomeIcons.trashCan, color: Colors.red, size: 24.0),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: const Text("Confirm Delete"),
                                                  content: const Text("Are you sure you want to delete this request?"),
                                                  actions: <Widget>[
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context).pop();
                                                      },
                                                      child: const Text("Cancel"),
                                                    ),
                                                    TextButton(
                                                      onPressed: () async {
                                                        final uid = getCurrentUserId();
                                                        if (uid.isNotEmpty) {
                                                          // Delete the request
                                                          await deletePendingRequest(uid, document.id);

                                                          // Show the snackbar after deletion
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(
                                                              content: Text("Appointment deleted successfully"),
                                                              backgroundColor: Colors.red,
                                                                duration: Duration(seconds: 2),
                                                            ),
                                                          );

                                                          // Close the dialog and return
                                                          Navigator.of(context).pop();
                                                        } else {
                                                          print('User is not logged in.');
                                                        }
                                                      },
                                                      child: const Text(
                                                        "Delete",
                                                        style: TextStyle(color: appRed),
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