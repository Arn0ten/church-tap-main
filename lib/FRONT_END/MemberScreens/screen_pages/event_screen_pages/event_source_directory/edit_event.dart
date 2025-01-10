import 'dart:developer';
import 'package:bethel_app_final/BACK_END/Services/Functions/Authentication.dart';
import 'package:bethel_app_final/BACK_END/Services/Functions/Users.dart';
import 'package:bethel_app_final/FRONT_END/constant/color.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class EditEvent extends StatefulWidget {
  final DateTime firstDate;
  final DateTime lastDate;
  final String documentId;
  final bool isAdmin;
  const EditEvent(
      {Key? key,
        required this.firstDate,
        required this.lastDate,
        required this.documentId,
        required this.isAdmin})
      : super(key: key);

  @override
  State<EditEvent> createState() => _EditEventState();
}

class _EditEventState extends State<EditEvent> {
  late Future _getDocument;
  int count = 0;
  DateTime _selectedDate = DateTime.now();
  final _descController = TextEditingController();
  String _selectedEventType = '';
  late List<String> _eventTypes;
  UserStorage storage = UserStorage();
  TapAuth auth = TapAuth();
  bool isCustomAppointment = false;
  final TextEditingController _customAppointmentController = TextEditingController();

  @override
  void dispose() {
    _customAppointmentController.dispose(); // Dispose of the controller to free resources
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchEventTypes().then((types) {
      setState(() {
        _eventTypes = types;
      });
    });
    _getDocument = fetchdocument(widget.documentId);
    _selectedDate = widget.firstDate;
    print("Initial Selected Event Type: $_selectedEventType");
  }
  bool _isDataInitialized = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Event")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FutureBuilder(
          future: _getDocument,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData) {
              final document = snapshot.data as Map<String, dynamic>;

              if (!_isDataInitialized) {
                // Initialize data only once
                _descController.text = document['description'] ?? '';
                final appointmentType = document['appointmenttype'] ?? '';
                if (_eventTypes.contains(appointmentType)) {
                  _selectedEventType = appointmentType;
                } else {
                  isCustomAppointment = true;
                  _customAppointmentController.text = appointmentType;
                }
                _isDataInitialized = true; // Mark data as initialized
              }

              return _buildForm();
            } else {
              return const Center(child: Text('No data found.'));
            }
          },
        ),
      ),
    );
  }



  Future<Map<String,dynamic>> fetchdocument(String documentID) async {
    var map = <String,dynamic>{};
    if (widget.isAdmin == true) {
      await storage.db.collectionGroup("Church Event").get()
          .then((value) {
        for (var element in value.docs) {
          if (element.id == widget.documentId) {
            map = element.data();
          }
        }
      });
    } else {
      await storage.db.collection("users")
          .doc("members")
          .collection(auth.auth.currentUser!.uid)
          .doc("Event")
          .collection("Pending Appointment")
          .get().then((value) {
        for (var element in value.docs) {
          if (element.id == widget.documentId) {
            map = element.data();
          }
        }
      });
    }
    return map;
  }


  Future<String> fetchdisc() async {
    String localdesc = '';
    await storage.db
        .collection('users')
        .doc('members')
        .collection(auth.auth.currentUser!.uid)
        .doc('Event')
        .collection('Pending Appointment')
        .doc(widget.documentId)
        .get()
        .then(
          (value) {
        localdesc = value.data()?['description'];
      },
    );
    return localdesc;
  }

  // Function to get the icon for each appointment type
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
        return Icon(FontAwesomeIcons.skullCrossbones,
            color: Colors.grey.shade800);

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
        return Icon(FontAwesomeIcons.peopleCarryBox,
            color: Colors.purple.shade800);

    // Music and Choir
      case 'Choir Practice':
        return Icon(FontAwesomeIcons.music, color: Colors.green.shade800);

    // Meals and Socials
      case 'Fellowship Meal':
        return Icon(FontAwesomeIcons.utensils, color: Colors.brown.shade800);
      case 'Anniversary Service':
        return Icon(FontAwesomeIcons.cakeCandles,
            color: Colors.yellow.shade800);

    // Certificates
      case 'Membership Certificate':
      case 'Baptismal Certificate':
        return Icon(FontAwesomeIcons.idCard, color: Colors.blueGrey.shade800);

    // Birthday Service
      case 'Birthday Service':
        return Icon(FontAwesomeIcons.cakeCandles, color: Colors.pink.shade600);

    // Default event icon
      default:
        return Icon(FontAwesomeIcons.calendarDays,
            color: Colors.green.shade800);
    }
  }

  Future<Map<String, dynamic>> fetchCount(String type) async {
    int count = 0;
    Icon eventIcon = const Icon(FontAwesomeIcons.calendarDays); // Default icon

    switch (type) {
      case "Sunday Service":
      case "Christmas Service":
        count = 0;
        eventIcon = getAppointmentIcon('Sunday Service');
        break;
      case "Easter Service":
        count = 1;
        eventIcon = getAppointmentIcon('Easter Service');
        break;
      case "Wedding Ceremony":
        count = 2;
        eventIcon = getAppointmentIcon('Wedding Ceremony');
        break;
      case "Funeral Service":
        count = 3;
        eventIcon = getAppointmentIcon('Funeral Service');
        break;
      case "Baptism":
      case "Communion Service":
      case "Infant Dedication":
        count = 4;
        eventIcon = getAppointmentIcon('Baptism');
        break;
      case "Pastoral Visit":
      case "Missionary Work":
        count = 5;
        eventIcon = getAppointmentIcon('Pastoral Visit');
        break;
      case "Prayer Meeting":
        count = 6;
        eventIcon = getAppointmentIcon('Prayer Meeting');
        break;
      case "Youth Fellowship":
      case "Bible Study":
        count = 7;
        eventIcon = getAppointmentIcon('Youth Fellowship');
        break;
      case "Church Anniversary":
      case "Community Outreach":
        count = 8;
        eventIcon = getAppointmentIcon('Church Anniversary');
        break;
      case "Choir Practice":
        count = 9;
        eventIcon = getAppointmentIcon('Choir Practice');
        break;
      case "Fellowship Meal":
        count = 10;
        eventIcon = getAppointmentIcon('Fellowship Meal');
        break;
      case "Anniversary Service":
        count = 11;
        eventIcon = getAppointmentIcon('Anniversary Service');
        break;
      case "Membership Certificate":
        count = 12;
        eventIcon = getAppointmentIcon('Membership Certificate');
        break;
      case "Baptismal Certificate":
        count = 13;
        eventIcon = getAppointmentIcon('Baptismal Certificate');
        break;
      default:
        count = 0;
        eventIcon = getAppointmentIcon('Meeting');
        break;
    }

    return {
      'count': count,
      'icon': eventIcon,
    };
  }

  Widget _buildForm() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Date Picker Section
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Pick a Date",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.all(12.0),
                  backgroundColor: Colors.blueAccent.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onPressed: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                    builder: (BuildContext context, Widget? child) {
                      return Theme(
                        data: ThemeData.light().copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Colors.blue, // Header background color
                            onPrimary: Colors.white, // Header text color
                            onSurface: Colors.black, // Body text color
                          ),
                        ),
                        child: child ?? const SizedBox.shrink(),
                      );
                    },
                  );
                  if (pickedDate != null && pickedDate != _selectedDate) {
                    setState(() {
                      _selectedDate = pickedDate;
                    });
                  }
                },
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.blue),
                    const SizedBox(width: 8.0),
                    Text(
                      "Selected Date: ${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}",
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ],
                ),
              ),
              const Divider(height: 32.0),
              // Section: Appointment Type
              const Text(
                "Appointment Type",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
            ],
          ),
        ),

        const Divider(),

        // Event Type Dropdown
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: DropdownButtonFormField<String>(
            value: _selectedEventType.isNotEmpty ? _selectedEventType : null,
            decoration: const InputDecoration(
              labelText: "Event Type",
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            ),
            items: _eventTypes.map((String value) {
              Icon eventIcon = getAppointmentIcon(value);
              return DropdownMenuItem<String>(
                value: value,
                child: Row(
                  children: [
                    eventIcon,
                    const SizedBox(width: 10),
                    Text(value),
                  ],
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedEventType = newValue ?? '';
                isCustomAppointment = false; // Explicitly set this to false
                print('Dropdown updated to: $_selectedEventType');
              });
            },

          ),
        ),

        const Divider(),

        // Custom Appointment Option
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Custom Appointment',
                style: TextStyle(fontSize: 16),
              ),
              Checkbox(
                value: isCustomAppointment,
                onChanged: (bool? value) {
                  setState(() {
                    isCustomAppointment = value ?? false;
                    if (!isCustomAppointment) {
                      _customAppointmentController.clear();
                    }
                  });
                },
              ),
            ],
          ),
        ),
        if (isCustomAppointment)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: TextFormField(
              controller: _customAppointmentController,
              decoration: const InputDecoration(
                labelText: "Enter Custom Appointment",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              ),
            ),
          ),

        const Divider(),


        // Section: Description
        const Text(
          "Description",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8.0),

        // Description Field
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextFormField(
            controller: _descController,
            maxLines: 4,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(16.0),
            ),
          ),
        ),

        const Divider(),

        // Save Button
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              backgroundColor: appGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            // Save Button
            onPressed: () async {
              final newAppointmentType = isCustomAppointment
                  ? _customAppointmentController.text.trim()
                  : _selectedEventType;

              print('Saving Appointment Type: $newAppointmentType'); // Debug print
              if (newAppointmentType.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please provide an appointment type.")),
                );
                return;
              }

              await _saveChanges(newAppointmentType, _descController.text.trim());
              Navigator.pop(context);
            },
            label: const Text(
              "Save",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

      ],
    );
  }


  Future<List<String>> _fetchEventTypes() async {
    try {
      List<String> eventTypes = [
        'Funeral Service',
        'Wedding Ceremony',
        'Sunday Service',
        'Christmas Service',
        'Easter Service',
        'Baptism',
        'Communion Service',
        'Church Anniversary',
        'Infant Dedication',
        'Pastoral Visit',
        'Prayer Meeting',
        'Community Outreach',
        'Youth Fellowship',
        'Bible Study',
        'Fellowship Meal',
      ];
      return eventTypes;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching event types: $e');
      }
      return [];
    }
  }

  Future<void> _saveChanges(String appointmentType, String description) async {
    try {
      final data = {
        'description': _descController.text,
        'appointmenttype': isCustomAppointment
            ? _customAppointmentController.text
            : _selectedEventType,
        'date': _selectedDate,
      };

      if (widget.isAdmin) {
        await storage.db
            .collectionGroup("Church Event")
            .where(FieldPath.documentId, isEqualTo: widget.documentId)
            .get()
            .then((snapshot) async {
          if (snapshot.docs.isNotEmpty) {
            await snapshot.docs.first.reference.update(data);
          }
        });
      } else {
        await storage.db
            .collection("users")
            .doc("members")
            .collection(auth.auth.currentUser!.uid)
            .doc("Event")
            .collection("Pending Appointment")
            .doc(widget.documentId)
            .update(data);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Appointment updated successfully!")),
      );
    } catch (e) {
      log("Error updating appointment: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update appointment.")),
      );
    }
  }
// void
}
