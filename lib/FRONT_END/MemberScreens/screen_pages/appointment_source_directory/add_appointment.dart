import 'package:bethel_app_final/BACK_END/Services/Functions/Authentication.dart';
import 'package:bethel_app_final/BACK_END/Services/Functions/Users.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

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

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    _fetchAppointmentTypes().then((types) {
      setState(() {
        _appointmentType = types;
        _selectedAppointmentType = _appointmentType.isNotEmpty
            ? _appointmentType.first['type']
            : '';
      });
    });
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Appointment")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
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
    );
  }

  Widget _buildForm() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        TextFormField(
          enabled: false,
          readOnly: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            disabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
            ),
          ),
          style: const TextStyle(color: Colors.black),
          initialValue:
          "${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}",
        ),
        const SizedBox(height: 16.0),
        DropdownButtonFormField<String>(
          value: _selectedAppointmentType,
          onChanged: (String? newValue) {
            setState(() {
              _selectedAppointmentType = newValue!;
            });
          },
          items: _appointmentType.map((Map<String, dynamic> value) {
            return DropdownMenuItem<String>(
              value: value['type'],
              child: Text('${value['type']} (Priority: ${value['priority']})'),
            );
          }).toList(),
        ),

        const SizedBox(height: 16.0),
        TextField(
          controller: _descController,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16.0),
        ElevatedButton(
          onPressed: () {
            _addAppointment(_selectedDate);
          },
          child: const Text("Save"),
        ),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> _fetchAppointmentTypes() async {
    try {
      // Simulate fetching event types with priority scores
      List<Map<String, dynamic>> types = [
        {'type': 'Meeting', 'priority': 5},
        {'type': 'Conference', 'priority': 7},
        {'type': 'Seminar', 'priority': 6},
        {'type': 'Workshop', 'priority': 6},
        {'type': 'Webinar', 'priority': 5},
        {'type': 'Wedding Ceremony', 'priority': 10},
        {'type': 'Funeral Service', 'priority': 9},
        {'type': 'Pastoral Visit', 'priority': 7},
        {'type': 'Prayer Meeting', 'priority': 6},
        {'type': 'Church Anniversary', 'priority': 8},
        {'type': 'Choir Practice', 'priority': 5},
        {'type': 'Youth Fellowship', 'priority': 6},
        {'type': 'Counseling Session', 'priority': 7},
        {'type': 'Community Outreach', 'priority': 8},
        {'type': 'Infant Dedication', 'priority': 8},
        {'type': 'Birthday Service', 'priority': 4},
        {'type': 'Birthday Manyanita', 'priority': 4},
        {'type': 'Membership Certificate', 'priority': 3},
        {'type': 'Baptismal Certificate', 'priority': 3},
      ];
      types.sort((a, b) => b['priority'].compareTo(a['priority'])); // Sort by priority
      return types;
    } catch (e) {
      print('Error fetching appointment types: $e');
      return [];
    }
  }


  void _addAppointment(DateTime selectedDate) async {
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

    userStorage.createMemberEvent(tapAuth.getCurrentUserUID(), page, widget.type);
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
                  _selectedAppointmentType = ''; // Reset selected appointment type
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