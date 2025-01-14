import 'dart:convert';
import 'dart:developer';

import 'package:bethel_app_final/BACK_END/Services/Functions/Users.dart';
import 'package:bethel_app_final/FRONT_END/authentications/auth_classes/error_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

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
  get http => null;

  final Map<String, double> appointmentPriorities = {
    'Funeral Service': 10,
    'Wedding Ceremony': 9.4,
    'Sunday Service': 9.3,
    'Christmas Service': 9.2,
    'Easter Service': 9.1,
    'Baptism': 8.4,
    'Communion Service': 8.3,
    'Church Anniversary': 8.2,
    'Infant Dedication': 8.1,
    'Pastoral Visit': 7.4,
    'Prayer Meeting': 7.3,
    'Community Outreach': 7.2,
    'Youth Fellowship': 6.3,
    'Bible Study': 6.2,
    'Fellowship Meal': 5.2,
  };
  double defaultNewAppointmentPriority = 0.0;

  // CLASSIFY priority IF NOT IN THE appointmentPriorities from Flask API
  Future<double> predictPriority(String appointmentType) async {
    const String apiUrl =
        'https://1f98-34-87-30-45.ngrok-free.app/predict_priority_v2';

    Map<String, String> requestPayload = {'appointment_type': appointmentType};

    try {
      print('Sending JSON payload: $requestPayload');

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestPayload),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData != null &&
            responseData.containsKey('predicted_priority')) {
          return responseData['predicted_priority'] as double;
        } else {
          throw Exception('API response missing predicted_priority');
        }
      } else {
        throw Exception('Failed to predict priority: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error making request: $e');
      return defaultNewAppointmentPriority;
    }
  }

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

///////////////////////////////////////////////////////////////////////
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

  double getPriorityForAppointment(String appointmentType) {
    // First check for known types
    Map<String, double> appointmentPriorities = {
      "Funeral": 10.0,
      "Wedding": 9.4,
      "Sunday": 9.3,
      "Christmas": 9.2,
      "Easter": 9.1,
      "Charity": 9.6,
      "Team": 9.6,
      "Camp": 9.5,
      "Lecture": 9.0,
      "Summer": 8.9,
      "Party": 8.9,
      "Hiking": 3.7,
      "Conference": 8.6,
      "Music": 8.6,
      "Film": 7.9,
      "Baptism": 8.4,
      "Leadership": 8.2,
      "Speaking": 8.2,
      "Spiritual": 7.0,
      "Counseling": 6.9,
      "Health": 6.8,
      "Picnic": 6.8,
      "Bible": 6.2,
      "Family": 7.7,
      "Debate": 6.1,
      "Fellowship": 5.2,
      "Anniversary": 5.1,
      "Volunteer": 4.3,
      "Spring": 4.4,
      "Art": 4.4,
      "Graduation": 4.2,
      "Birthday": 4.2,
      "Membership": 4.1,
      "Sports": 4.1,
      "Senior": 3.9,
      "Men": 3.8,
      "Vacation": 3.7,
      "Marriage": 3.7,
      "Community": 7.2,
      "Pastoral": 7.4,
    };

    // Check if the appointment type is in the known priorities map
    // Normalize the input string to lowercase to handle case insensitivity
    String normalizedInput = appointmentType.toLowerCase();

    // Create a fuzzy matcher for the available appointment types
    List<String> appointmentKeys = appointmentPriorities.keys.toList();
    var fuzzy = Fuzzy(appointmentKeys);

    // Perform a fuzzy search to find the closest match paara sa typo ni
    var results = fuzzy.search(normalizedInput);

    if (results.isNotEmpty) {
      // Find the best match
      String bestMatch = results[0].item;
      double priority = appointmentPriorities[bestMatch]!;
      print(
          'Found best match for "$appointmentType" as "$bestMatch": $priority');
      return priority;
    }

    // If no match found, assign a default low priority (e.g., 0.0)
    print(
        'No match found for "$appointmentType", assigning default priority: 0.0');
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    if (_pendingAppointmentsStream == null) {
      return Scaffold(
        body: Center(
          child: LoadingAnimationWidget.staggeredDotsWave(
            color: appGreen, // Customize the color
            size: 50.0, // Customize the size
          ),
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
                    return Center(
                      child: LoadingAnimationWidget.staggeredDotsWave(
                        color: appGreen, // Customize the color
                        size: 50.0, // Customize the size
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No pending appointment.',
                        style: TextStyle(fontSize: 18),
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

                      // Print the appointment types being compared
                      print(
                          'Comparing appointment types: $appointmentTypeA vs $appointmentTypeB');

                      double priorityA =
                          getPriorityForAppointment(appointmentTypeA);
                      double priorityB =
                          getPriorityForAppointment(appointmentTypeB);

                      // Print the priority values for comparison
                      print('Priorities: $priorityA vs $priorityB');

                      return priorityB.compareTo(
                          priorityA); // Sort in descending order of priority
                    });
                    return appointments;
                  }

// Re-prioritize and refresh the appointments
                  void refreshAppointments() {
                    setState(() {
                      _initializeStream(); // Re-fetch appointments
                    });
                  }

                  Future<void> handleAppointmentAction(String appointmentId, String userID, bool isApprove) async {
                    // Determine the action text based on approval status
                    String action = isApprove ? "approve" : "deny";

                    // Show confirmation dialog for approval/denial
                    bool? confirmation = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text("Confirm Action"),
                          content: Text("Are you sure you want to $action this appointment?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),  // Cancel action
                              child: Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),  // Confirm action
                              child: Text("Confirm"),
                            ),
                          ],
                        );
                      },
                    );

                    if (confirmation == true) {
                      try {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  LoadingAnimationWidget.staggeredDotsWave(
                                    color: appGreen,
                                    size: 50.0,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    isApprove ? "Approving appointment..." : "Denying appointment...",
                                    style: const TextStyle(fontSize: 16, color: appWhite),
                                  ),
                                ],
                              ),
                            );
                          },
                        );

                        // Handle the case where the appointment is being approved
                        if (isApprove) {
                          // Call the method to deny appointments on the same date except the approved one
                          // await userStorage.removeSameDateIfAccepted(userID, appointmentId);
                          // Proceed with approving the appointment
                          await _performApprovedAppointment(appointmentId, userID);

                          // Show success message to the user
                          DialogHelper.showSnackBar(context, "Appointment successfully approved.");
                        } else {
                          // Handle denial of the appointment
                          await _performDenyAppointment(appointmentId, userID);
                          DialogHelper.showSnackBar(context, "Appointment successfully denied.");
                        }

                        // Refresh the appointment list after performing the action
                        refreshAppointments();

                        // Dismiss the loading dialog
                        Navigator.of(context).pop();

                      } catch (e) {
                        // Handle any errors that occur during the approval/denial process
                        String errorMessage = isApprove
                            ? "Error approving appointment."
                            : "Error denying appointment.";
                        log("$errorMessage: $e");
                        DialogHelper.showSnackBar(context, errorMessage);

                        // Dismiss the loading dialog if there's an error
                        Navigator.of(context).pop();
                      }
                    }
                  }




                  // Group appointments by date
                  Map<String, List<DocumentSnapshot>> groupedAppointments =
                      groupAppointmentsByDate(sortedAppointments);

                  Map<String, double> highestPriorityByDate = {};

                  // First, calculate the highest priority for each date
                  groupedAppointments.forEach((dateKey, appointments) {
                    double highestPriority = 0.0;

                    // Find the highest priority among the appointments
                    for (var appointment in appointments) {
                      String appointmentType = appointment['appointmenttype'];
                      double appointmentPriority =
                          getPriorityForAppointment(appointmentType);

                      if (appointmentPriority > highestPriority) {
                        highestPriority = appointmentPriority;
                      }
                    }

                    // Store the highest priority for the date
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
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              child: Text(
                                'Date: $dateKey',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            ...appointments.map((DocumentSnapshot document) {
                              Map<String, dynamic> data =
                                  document.data() as Map<String, dynamic>;

                              String appointmentType =
                                  data['appointmenttype'] ?? '';
                              double appointmentPriority =
                                  getPriorityForAppointment(appointmentType);

                              // Check if this appointment is the highest priority for the day
                              bool isHighestPriority = appointmentPriority ==
                                  highestPriorityByDate[dateKey];

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

                              return Draggable<String>(
                                data: document.id,
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: Card(
                                    color: Colors.amber.shade200,
                                    elevation: 5,
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 4, horizontal: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 12, horizontal: 16),
                                      title: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 24,
                                            backgroundColor:
                                                Colors.amber.shade300,
                                            child: getAppointmentIcon(
                                              data['appointmenttype'] ??
                                                  'Unknown Type',
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  data['appointmenttype'] ??
                                                      'Unknown Type',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                                if (isHighestPriority)
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                    child: const Text(
                                                      'High Priority',
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12),
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
                                            borderRadius:
                                                BorderRadius.circular(12),
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
                                                        icon: const Icon(
                                                            Icons.close,
                                                            color:
                                                                Colors.black),
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pop(); // Close the dialog
                                                        },
                                                      ),
                                                    ),
                                                    // Content Section
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            CircleAvatar(
                                                              radius: 24,
                                                              backgroundColor:
                                                                  Colors.amber
                                                                      .shade300,
                                                              child:
                                                                  getAppointmentIcon(
                                                                data['appointmenttype'] ??
                                                                    'Unknown Type',
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 16),
                                                            Expanded(
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Text(
                                                                    data['appointmenttype'] ??
                                                                        'Unknown Type',
                                                                    style:
                                                                        const TextStyle(
                                                                      fontSize:
                                                                          18,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: Colors
                                                                          .black87,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                            height: 4),
                                                        Text(
                                                          'Email: ${data['email'] ?? ''}',
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 14,
                                                                  color: Colors
                                                                      .grey),
                                                        ),
                                                        const SizedBox(
                                                            height: 8),
                                                        Text.rich(
                                                          TextSpan(
                                                            children: [
                                                              const TextSpan(
                                                                text:
                                                                    'Description:  ',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 17,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .black87,
                                                                ),
                                                              ),
                                                              TextSpan(
                                                                text:
                                                                    '${data['description'] ?? ''}',
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize: 14,
                                                                  color: Colors
                                                                      .black87,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 16),

                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [

                                                            Text(
                                                              'Date: $dateKey',
                                                              style: const TextStyle(
                                                                  fontSize: 14,
                                                                  color: Colors
                                                                      .grey),

                                                            ),
                                                            if (isHighestPriority)
                                                              Row(
                                                                mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                                children: [
                                                                  Container(
                                                                    padding: const EdgeInsets
                                                                        .symmetric(
                                                                        horizontal:
                                                                        8,
                                                                        vertical:
                                                                        4),
                                                                    decoration:
                                                                    BoxDecoration(
                                                                      color: appGreen,
                                                                      borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                          20),
                                                                    ),
                                                                    child:
                                                                    const Text(
                                                                      'High Priority',
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .white,
                                                                          fontSize:
                                                                          12),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            if (!isHighestPriority)
                                                              Row(
                                                                mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                                children: [
                                                                  Container(
                                                                    padding: const EdgeInsets
                                                                        .symmetric(
                                                                        horizontal:
                                                                        8,
                                                                        vertical:
                                                                        4),
                                                                    decoration:
                                                                    BoxDecoration(
                                                                      color: Colors.red,
                                                                      borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                          20),
                                                                    ),
                                                                    child:
                                                                    const Text(
                                                                      'Standard Priority',
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .white,
                                                                          fontSize:
                                                                          12),
                                                                    ),
                                                                  ),
                                                                ],
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
                                    color: Colors.amber.shade200,
                                    elevation: 2,
                                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 12, horizontal: 16),
                                      title: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 24,
                                            backgroundColor:
                                                Colors.amber.shade300,
                                            child: getAppointmentIcon(
                                              data['appointmenttype'] ??
                                                  'Unknown Type',
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  data['appointmenttype'] ??
                                                      'Unknown Type',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                                if (isHighestPriority)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green,
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: const Text(
                                                      'High Priority',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  )
                                                else
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red, // Different color for "Reschedule"
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: const Text(
                                                      'Standard Priority',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                const SizedBox(height: 4),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 4),
                                            Text(
                                              'Email: ${data['email'] ?? ''}',
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey),
                                            ),
                                            const SizedBox(height: 4),
                                            Text.rich(
                                              TextSpan(
                                                children: [
                                                  const TextSpan(
                                                    text: 'Description:  ',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text:
                                                        '${data['description'] ?? ''}',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              maxLines: 2, // Limits to 2 lines
                                              overflow: TextOverflow
                                                  .ellipsis, // Adds ellipsis if the text exceeds 2 lines
                                            ),
                                            Row(
                                              children: [

                                              ],
                                            ),
                                            // Display "Suggest to Reschedule" if not high priority

                                          ],
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.check,
                                                color: Colors.green, size: 30),
                                            onPressed: () =>
                                                handleAppointmentAction(
                                                    document.id,
                                                    data['userID'],
                                                    true),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.close,
                                                color: Colors.red, size: 30),
                                            onPressed: () =>
                                                handleAppointmentAction(
                                                    document.id,
                                                    data['userID'],
                                                    false),
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
