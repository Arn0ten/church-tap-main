import 'dart:developer';
import 'package:bethel_app_final/BACK_END/Services/Functions/Users.dart';
import 'package:bethel_app_final/FRONT_END/authentications/auth_classes/error_indicator.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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


  final Map<String, int> appointmentPriorities = {

    'Meeting': 5,
    'Conference': 7,
    'Seminar': 6,
    'Workshop': 6,
    'Webinar': 5,
    'Wedding Ceremony': 10,
    'Funeral Service': 9,
    'Pastoral Visit': 7,
    'Prayer Meeting': 6,
    'Church Anniversary': 8,
    'Choir Practice': 5,
    'Youth Fellowship': 6,
    'Counseling Session': 7,
    'Community Outreach': 8,
    'Infant Dedication': 8,
    'Birthday Service': 4,
    'Birthday Manyanita': 4,
    'Membership Certificate': 3,
    'Baptismal Certificate': 3,

  };

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  Future<void> _initializeStream() async {
    try {
      _pendingAppointmentsStream =
          UserStorage().fetchAllPendingAppointments();
    } catch (e) {
      log("Error initializing stream: $e");
    }
  }

  Future<void> _performApprovedAppointment(String appointmentId,
      String userID) async {
    try {
      await userStorage.approvedAppointment(userID, appointmentId);
    } catch (e) {
      log("Error performing approved appointment: $e");
      throw Exception("Error performing approved appointment.");
    }
  }

  Future<void> _performDenyAppointment(String appointmentId,
      String userID) async {
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
                  "Admin Approval",
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
              color: Colors.green,
            ),
            const SizedBox(height: 10),
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
                  List<
                      DocumentSnapshot> sortedAppointments = sortAppointmentsByMonth(
                      snapshot.data!);
                  // Sort appointments by priority
                  // Sort appointments by priority using the priorities map and date
                  List<DocumentSnapshot> sortAppointmentsByPriority(
                      List<DocumentSnapshot> appointments) {
                    appointments.sort((a, b) {
                      Map<String, dynamic> dataA = a.data() as Map<
                          String,
                          dynamic>;
                      Map<String, dynamic> dataB = b.data() as Map<
                          String,
                          dynamic>;

                      String appointmentTypeA = dataA['appointmenttype'] ?? '';
                      String appointmentTypeB = dataB['appointmenttype'] ?? '';

                      int priorityA = appointmentPriorities[appointmentTypeA] ??
                          100; // Default low priority
                      int priorityB = appointmentPriorities[appointmentTypeB] ??
                          100;

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


                  // Group appointments by date
                  Map<String, List<DocumentSnapshot>> groupedAppointments = groupAppointmentsByDate(sortedAppointments);

                  Map<String, int> highestPriorityByDate = {};

                  groupedAppointments.forEach((dateKey, appointments) {
                    int highestPriority = appointments.map((doc) {
                      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
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
                              int appointmentPriority = appointmentPriorities[appointmentType] ?? 100;

                              bool isHighestPriority = appointmentPriority == highestPriorityByDate[dateKey];

                              return Card(
                                color: Colors.amber.shade100,
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                child: ListTile(
                                  title: Row(
                                    children: [
                                      Expanded(child: Text('Appointment: ${data['appointmenttype'] ?? ''}')),
                                      if (isHighestPriority)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'High Priority',
                                            style: TextStyle(color: Colors.white, fontSize: 12),
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Description: ${data['description'] ?? ''}'),
                                      Text('Name: ${data['name'] ?? ''}'),
                                      Text('Email: ${data['email'] ?? ''}'),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.check, color: Colors.green),
                                        onPressed: () => handleAppointmentAction(document.id, data['userID'], true),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, color: Colors.red),
                                        onPressed: () => handleAppointmentAction(document.id, data['userID'], false),
                                      ),
                                    ],
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
