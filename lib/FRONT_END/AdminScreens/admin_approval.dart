import 'dart:developer';
import 'package:bethel_app_final/BACK_END/Services/Functions/Users.dart';
import 'package:bethel_app_final/FRONT_END/authentications/auth_classes/error_indicator.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../constant/color.dart';


class AdminApproval extends StatefulWidget {
  const AdminApproval({Key? key}) : super(key: key);

  @override
  State<AdminApproval> createState() => _AdminApprovalState();
}

class _AdminApprovalState extends State<AdminApproval> {
  late Stream<QuerySnapshot> _pendingAppointmentsStream;
  Map<String, bool> showOptionsMap = {};
  final UserStorage userStorage = UserStorage();
  bool sortByMonth = false;
  bool sortByDay = false;
  int clickCount = 0;

  final Map<String, double> appointmentPriorities = {
    'Sunday Service': 10,
    'Wedding Ceremony': 9.4,
    'Funeral Service': 9.3,
    'Christmas Service': 9.2,
    'Easter Service': 9.1,
    'Baptism': 8.4,
    'Communion Service': 8.3,
    'Church Anniversary': 8.2,
    'Infant Dedication': 8.1,
    'Pastoral Visit': 7.4,
    'Prayer Meeting': 7.3,
    'Community Outreach': 7.2,
    'Missionary Work': 7.1,
    'Youth Fellowship': 6.3,
    'Bible Study': 6.2,
    'Choir Practice': 6.1,
    'Fellowship Meal': 5.2,
    'Anniversary Service': 5.1,
    'Baptismal Certificate': 5.1,
    'Birthday Service': 4.2,
    'Membership Certificate': 4.1
  };

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  Future<void> _initializeStream() async {
    try {
      _pendingAppointmentsStream = UserStorage().fetchAllPendingAppointments();
    } catch (e) {
      log("Error initializing stream: $e");
    }
  }

  Future<void> _performApprovedAppointment(
      String appointmentId, String userID) async {
    try {
      await userStorage.approvedAppointment(userID, appointmentId);
    } catch (e) {
      log("Error performing approved appointment: $e");
      throw Exception("Error performing approved appointment.");
    }
  }

  Future<void> _performDenyAppointment(
      String appointmentId, String userID) async {
    try {
      await userStorage.denyAppointment(userID, appointmentId);
    } catch (e) {
      log("Error performing denied appointment: $e");
      throw Exception("Error performing denied appointment.");
    }
  }

  Future<void> approvedAppointment(String appointmentId, String userID) async {
    try {
      await DialogHelper.showLoadingDialog(context, "Approving appointment...");
      await _performApprovedAppointment(userID, appointmentId);
      DialogHelper.showSnackBar(context, "Appointment successfully approved.");
    } catch (e) {
      log("Error approving appointment: $e");
      DialogHelper.showSnackBar(context, "Error approving appointment.");
    }
  }

  Future<void> denyAppointment(String appointmentId, String userID) async {
    try {
      await DialogHelper.showLoadingDialog(context, "Denying appointment...");
      await _performDenyAppointment(userID, appointmentId);
      DialogHelper.showSnackBar(context, "Appointment successfully denied.");
    } catch (e) {
      log("Error denying appointment: $e");
      DialogHelper.showSnackBar(context, "Error denying appointment.");
    }
  }

  List<DocumentSnapshot> sortAppointmentsByMonth(QuerySnapshot snapshot) {
    List<DocumentSnapshot> appointments = snapshot.docs;
    if (sortByMonth) {
      appointments.sort((a, b) {
        DateTime dateA = (a.data() as Map<String, dynamic>)["date"].toDate();
        DateTime dateB = (b.data() as Map<String, dynamic>)["date"].toDate();
        return dateA.month.compareTo(dateB.month);
      });
    }
    return appointments;
  }

  List<DocumentSnapshot> sortAppointmentsEventsByDay(
      List<DocumentSnapshot> appointments) {
    appointments.sort((a, b) {
      DateTime dateA = (a.data() as Map<String, dynamic>)["date"].toDate();
      DateTime dateB = (b.data() as Map<String, dynamic>)["date"].toDate();
      return dateA.day.compareTo(dateB.day);
    });
    return appointments;
  }

// Group appointments by date
  Map<String, List<DocumentSnapshot>> groupAppointmentsByDate(
      List<DocumentSnapshot> appointments) {
    Map<String, List<DocumentSnapshot>> groupedAppointments = {};

    for (var appointment in appointments) {
      Map<String, dynamic> data = appointment.data() as Map<String, dynamic>;
      Timestamp timeStamp = data['date'];
      DateTime dateTime = timeStamp.toDate();
      String formattedDate = DateFormat('yyyy-MM-dd').format(dateTime);

      if (!groupedAppointments.containsKey(formattedDate)) {
        groupedAppointments[formattedDate] = [];
      }
      groupedAppointments[formattedDate]!.add(appointment);
    }
    return groupedAppointments;
  }

  @override
  Widget build(BuildContext context) {
    if (_pendingAppointmentsStream == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 5, left: 20, right: 20),
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
                  "Admin Approval",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 50),
              ],
            ),
            const SizedBox(height: 7),
            const Divider(
              color: appGreen,
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
                        'No pending appointment.',
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    );
                  }
                  // Sort appointments by month
                  List<DocumentSnapshot> sortedAppointments =
                      sortAppointmentsByMonth(snapshot.data!);
                  // Sort appointments by priority
                  // Sort appointments by priority using the priorities map and date
                  List<DocumentSnapshot> sortAppointmentsByPriority(
                      List<DocumentSnapshot> appointments) {
                    appointments.sort((a, b) {
                      Map<String, dynamic> dataA =
                          a.data() as Map<String, dynamic>;
                      Map<String, dynamic> dataB =
                          b.data() as Map<String, dynamic>;

                      String appointmentTypeA = dataA['appointmenttype'] ?? '';
                      String appointmentTypeB = dataB['appointmenttype'] ?? '';

                      double priorityA = appointmentPriorities[appointmentTypeA] ??
                          100; // Default low priority
                      double priorityB =
                          appointmentPriorities[appointmentTypeB] ?? 100;

                      // If priorities are the same, compare by date
                      if (priorityA == priorityB) {
                        DateTime dateA = dataA['date'].toDate();
                        DateTime dateB = dataB['date'].toDate();
                        return dateA.compareTo(dateB);
                      }

                      // Higher priority should come first
                      return priorityB.compareTo(priorityA);
                    });
                    return appointments;
                  }

// Re-prioritize and refresh the appointments
                  void refreshAppointments() {
                    setState(() {
                      _initializeStream(); // Re-fetch appointments
                    });
                  }

                  Future<void> handleAppointmentAction(String appointmentId,
                      String userID, bool isApprove) async {
                    String action = isApprove ? "approve" : "deny";
                    bool? confirmation = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text("Confirm Action"),
                          content: Text(
                              "Are you sure you want to $action this appointment?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              // Cancel
                              child: Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              // Confirm
                              child: Text("Confirm"),
                            ),
                          ],
                        );
                      },
                    );

                    if (confirmation == true) {
                      try {
                        String actionMessage = isApprove
                            ? "Approving appointment..."
                            : "Denying appointment...";
                        await DialogHelper.showLoadingDialog(
                            context, actionMessage);

                        if (isApprove) {
                          await _performApprovedAppointment(
                              appointmentId, userID);
                          DialogHelper.showSnackBar(
                              context, "Appointment successfully approved.");
                        } else {
                          await _performDenyAppointment(appointmentId, userID);
                          DialogHelper.showSnackBar(
                              context, "Appointment successfully denied.");
                        }

                        // Refresh the priority list after an action
                        refreshAppointments();
                      } catch (e) {
                        String errorMessage = isApprove
                            ? "Error approving appointment."
                            : "Error denying appointment.";
                        log("$errorMessage: $e");
                        DialogHelper.showSnackBar(context, errorMessage);
                      }
                    }
                  }

                  // Group appointments by date
                  Map<String, List<DocumentSnapshot>> groupedAppointments =
                      groupAppointmentsByDate(sortedAppointments);

                  Map<String, double> highestPriorityByDate = {};

                  groupedAppointments.forEach((dateKey, appointments) {
                    double highestPriority = appointments.map((doc) {
                      Map<String, dynamic> data =
                          doc.data() as Map<String, dynamic>;
                      String appointmentType = data['appointmenttype'] ?? '';
                      return appointmentPriorities[appointmentType] ?? 100;
                    }).reduce((a, b) => a > b ? a : b);

                    highestPriorityByDate[dateKey] = highestPriority;
                  });

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
                      ...groupedAppointments.entries.map((entry) {
                        String dateKey = entry.key;
                        List<DocumentSnapshot> appointments = entry.value;

                        appointments = sortAppointmentsByPriority(appointments);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Text(
                                'Date: $dateKey',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            ...appointments.map((DocumentSnapshot document) {
                              Map<String, dynamic> data = document.data() as Map<String, dynamic>;

                              String appointmentType = data['appointmenttype'] ?? '';
                              double appointmentPriority = appointmentPriorities[appointmentType] ?? 100;

                              bool isHighestPriority = appointmentPriority == highestPriorityByDate[dateKey];

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


                              return Draggable<String>(
                                data: document.id,
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: Card(
                                    color: Colors.amber.shade200,
                                    elevation: 5,
                                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
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
                                    ),
                                  ),
                                ),
                                childWhenDragging: Container(),
                                child: GestureDetector(
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
                                                        Text(
                                                          data['appointmenttype'] ?? 'Unknown Type',
                                                          style: const TextStyle(
                                                            fontSize: 20,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.black87,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 12),
                                                        Text(
                                                          'Email: ${data['email'] ?? ''}',
                                                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                                                        ),
                                                        const SizedBox(height: 8),
                                                        Text(
                                                          'Description: ${data['description'] ?? ''}',
                                                          style: const TextStyle(fontSize: 14, color: Colors.black87)
                                                        ),
                                                        const SizedBox(height: 16),
                                                        if (isHighestPriority)
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                            decoration: BoxDecoration(
                                                              color: Colors.red,
                                                              borderRadius: BorderRadius.circular(20),
                                                            ),
                                                            child: const Text(
                                                              'High Priority',
                                                              style: TextStyle(color: Colors.white, fontSize: 12),
                                                            ),
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
                                    color: Colors.amber.shade200,
                                    elevation: 5,
                                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
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
                                                const SizedBox(height: 5),
                                                if (isHighestPriority)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red,
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: const Text(
                                                      'High Priority',
                                                      style: TextStyle(color: Colors.white, fontSize: 12),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 4),
                                            Text(
                                              'Email: ${data['email'] ?? ''}',
                                              style: const TextStyle(fontSize: 14, color: Colors.grey),
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
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.check, color: Colors.green, size: 30),
                                            onPressed: () => handleAppointmentAction(document.id, data['userID'], true),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.close, color: Colors.red, size: 30),
                                            onPressed: () => handleAppointmentAction(document.id, data['userID'], false),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );

                            }).toList(),
                          ],
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
