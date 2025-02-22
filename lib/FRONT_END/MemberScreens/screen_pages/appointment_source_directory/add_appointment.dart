import 'package:bethel_app_final/BACK_END/Services/Functions/Authentication.dart';
import 'package:bethel_app_final/BACK_END/Services/Functions/Users.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

import '../../../constant/color.dart';

class AddAppointment extends StatefulWidget {
  final String type;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime selectedDate;

  const AddAppointment({
    Key? key,
    required this.firstDate,
    required this.lastDate,
    required this.selectedDate,
    required this.type,
  }) : super(key: key);

  @override
  State<AddAppointment> createState() => _AddAppointmentState();
}

class _AddAppointmentState extends State<AddAppointment> {
  late TapAuth tapAuth;
  late UserStorage userStorage;
  late DateTime _selectedDate;
  final _descController = TextEditingController();
  String _selectedAppointmentType = '';
  late List<Map<String, dynamic>> _appointmentType;
  bool isCustomAppointment = false;
  final _customAppointmentController = TextEditingController();
  late ValueNotifier<bool> isCustomAppointmentNotifier;
  final _descFocusNode = FocusNode(); // Focus node to handle focus and validation
  bool _isDescriptionValid = true; // Track if the description is valid

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    isCustomAppointmentNotifier = ValueNotifier<bool>(false);
    _fetchAppointmentTypes().then((types) {
      setState(() {
        _appointmentType = types;
        _selectedAppointmentType =
        _appointmentType.isNotEmpty ? _appointmentType.first['type'] : '';
      });
    });
  }

  @override
  void dispose() {
    _descController.dispose();
    _customAppointmentController.dispose();
    isCustomAppointmentNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Appointment")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FutureBuilder<List<Map<String, dynamic>>>( // Fetch appointment types
          future: _fetchAppointmentTypes(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              return _buildForm();
            }
          },
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section: Date Picker
          const Text(
            "Pick a Date",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8.0),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
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
                        primary: Colors.blue,
                        onPrimary: Colors.white,
                        onSurface: Colors.black,
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
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
                const SizedBox(width: 10.0),
                Expanded(
                  child: Text(
                    "Selected Date: ${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}",
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                    overflow: TextOverflow.ellipsis,
                  ),
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
          const Divider(),
          DropdownButtonFormField<String>(
            value: isCustomAppointment ? null : _selectedAppointmentType,
            onChanged: (String? newValue) {
              setState(() {
                _selectedAppointmentType = newValue ?? '';
                isCustomAppointment = false;
              });
            },
            items: _appointmentType.map((Map<String, dynamic> value) {
              return DropdownMenuItem<String>(
                value: value['type'],
                child: Row(
                  children: [
                    getAppointmentIcon(value['type']),
                    const SizedBox(width: 10),
                    Text(value['type']),
                  ],
                ),

              );
            }).toList(),

            decoration: InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
            ),
          ),
          const Divider(),
          const SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Or enter custom appointment:",
                style: TextStyle(fontSize: 16),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: isCustomAppointmentNotifier,
                builder: (context, isCustomAppointment, child) {
                  return Checkbox(
                    value: isCustomAppointment,
                    onChanged: (bool? value) {
                      isCustomAppointmentNotifier.value = value ?? false;
                      if (!isCustomAppointmentNotifier.value) {
                        _customAppointmentController.clear();
                      }
                    },
                  );
                },
              ),
            ],
          ),
          ValueListenableBuilder<bool>(
            valueListenable: isCustomAppointmentNotifier,
            builder: (context, isCustomAppointment, child) {
              return isCustomAppointment
                  ? TextField(
                controller: _customAppointmentController,
                decoration: const InputDecoration(
                  labelText: "Custom Appointment",
                  border: OutlineInputBorder(),
                ),
              )
                  : const SizedBox.shrink();
            },
          ),
          const Divider(height: 32.0),

          // Section: Description
          // Section: Description
          const Text(
            "Description",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8.0),
          TextField(
            controller: _descController,
            focusNode: _descFocusNode,
            maxLines: 5,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _isDescriptionValid ? Colors.blue : Colors.red),
              ),
              errorText: !_isDescriptionValid ? 'Description cannot be empty' : null,
            ),
          ),
          const SizedBox(height: 32.0),

          // Save Button
          Align(
            alignment: Alignment.center,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                backgroundColor: appGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 5,
              ),
              onPressed: () async {
                // Show confirmation dialog before saving
                bool shouldSave = await showDialog<bool>(
                  context: context,
                  barrierDismissible: false, // Dialog cannot be dismissed by tapping outside
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("Confirm Save"),
                      content: const Text("Are you sure you want to save this appointment?"),
                      actions: <Widget>[
                        TextButton(
                          child: const Text("Cancel"),
                          onPressed: () {
                            Navigator.of(context).pop(false); // Return false if canceled
                          },
                        ),
                        TextButton(
                          child: const Text("Confirm"),
                          onPressed: () {
                            Navigator.of(context).pop(true); // Return true if confirmed
                          },
                        ),
                      ],
                    );
                  },
                ) ?? false;

                if (shouldSave) {
                  if (isCustomAppointmentNotifier.value) {
                    _selectedAppointmentType = _customAppointmentController.text;
                  }
                  _addAppointment(_selectedDate, _selectedAppointmentType);
                }
              },
              child: const Text(
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
      ),
    );
  }


  Future<List<Map<String, dynamic>>> _fetchAppointmentTypes() async {
    try {
      // Simulate fetching event types with priority scores
      List<Map<String, dynamic>> types = [
        {'type': 'Funeral Service', 'priority': 10},
        {'type': 'Wedding Ceremony', 'priority': 9.4},
        {'type': 'Sunday Service', 'priority': 9.3},
        {'type': 'Christmas Service', 'priority': 9.2},
        {'type': 'Easter Service', 'priority': 9.1},
        {'type': 'Baptism', 'priority': 8.5},
        {'type': 'Communion Service', 'priority': 8.4},
        {'type': 'Church Anniversary', 'priority': 8.3},
        {'type': 'Infant Dedication', 'priority': 8.1},
        {'type': 'Pastoral Visit', 'priority': 7.4},
        {'type': 'Prayer Meeting', 'priority': 7.3},
        {'type': 'Community Outreach', 'priority': 7.2},
        {'type': 'Youth Fellowship', 'priority': 6.3},
        {'type': 'Bible Study', 'priority': 6.2},
        {'type': 'Fellowship Meal', 'priority': 5.5},
      ];
      types.sort((a, b) => b['priority'].compareTo(a['priority']));
      return types;
    } catch (e) {
      print('Error fetching appointment types: $e');
      return [];
    }
  }

  // Function to get the icon for each appointment type
  Icon getAppointmentIcon(String appointmentType) {
    switch (appointmentType) {
    // Religious Services
      case 'Sunday Service':
      case 'Christmas Service':
        return Icon(FontAwesomeIcons.church, color: Colors.pink.shade800);
      case 'Easter Service':
        return const Icon(FontAwesomeIcons.egg, color: Colors.purple);

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
        return Icon(FontAwesomeIcons.dove, color: Colors.purple);

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

  void _addAppointment(DateTime selectedDate, String appointmentType) async {
    // Check if description or appointment type is empty
    if (_descController.text.isEmpty || _selectedAppointmentType.isEmpty) {
      print('Please fill in all fields.');
      return;
    }

    tapAuth = TapAuth();
    userStorage = UserStorage();
    final description = _descController.text;
    if (tapAuth.getCurrentUserUID() == null) {
      print('No user is currently signed in');
      return;
    }

    final selectedAppointment = _appointmentType.firstWhere(
          (element) => element['type'] == _selectedAppointmentType,
      orElse: () => {'type': _selectedAppointmentType, 'priority': 0},
    );

    var page = <String, dynamic>{
      "description": description,
      "date": Timestamp.fromDate(_selectedDate),
      "userID": tapAuth.getCurrentUserUID(),
      "appointmenttype": _selectedAppointmentType,
      "priority": selectedAppointment['priority'],
      "name": tapAuth.auth.currentUser!.displayName,
      "email": tapAuth.auth.currentUser!.email,
    };

    userStorage.createMemberEvent(
        tapAuth.getCurrentUserUID(), page, widget.type);
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: const Text('Appointment saved successfully.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pop(context, true);
                Get.back();

                // Clear the form fields
                _descController.clear();
                setState(() {
                  _selectedAppointmentType = ''; // Reset appointment type
                });
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
