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
  final String documentId; // Change this line
  final bool isAdmin;
  const EditEvent({Key? key,
    required this.firstDate,
    required this.lastDate,
    required this.documentId,
    required this.isAdmin}) : super(key: key); // Change this line

  @override
  State<EditEvent> createState() => _EditEventState();
}

class _EditEventState extends State<EditEvent> {
  late Future _getDocument;
  int count = 0;
  late DateTime _selectedDate;
  final _descController = TextEditingController();
  String _selectedEventType = '';
  late List<String> _eventTypes;
  UserStorage storage = UserStorage();
  TapAuth auth = TapAuth();
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Edit")
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FutureBuilder(
          future: _getDocument,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
                fetchCount(snapshot.data['appointmenttype']);
              _descController.text = snapshot.data['description'];
              return _buildForm();
            }
          },
        ),
      ),

    );
  }
  Future<Map<String,dynamic>> fetchdocument(String documentID) async{
    var map = <String,dynamic>{};
    if(widget.isAdmin == true){
      await storage.db.collectionGroup("Church Event").get()
          .then((value) {
            for (var element in value.docs) {
              if(element.id == widget.documentId){
                map = element.data();
              }
            }
          },);
    }
  else{
    await storage.db.collection("users")
        .doc("members")
        .collection(auth.auth.currentUser!.uid)
        .doc("Event")
        .collection("Pending Appointment")
        .get().then((value) {
         for(var element in value.docs) {
           if(element.id == widget.documentId){
             map = element.data();
           }
         }
        },);
    }
  return map;
  }

  Future<String> fetchdisc() async{
    String localdesc = '';
    await storage.db.collection('users')
        .doc('members')
        .collection(auth.auth.currentUser!.uid)
        .doc('Event')
        .collection('Pending Appointment')
        .doc(widget.documentId)
        .get().then((value) {
      localdesc = value.data()?['description'];
    },);
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
        // Date Picker
        TextButton(
          onPressed: () async {
            final DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: widget.firstDate,
              lastDate: widget.lastDate,
            );
            if (pickedDate != null && pickedDate != _selectedDate) {
              setState(() {
                _selectedDate = pickedDate;
              });
            }
          },
          child: Text(
            "Selected Date: ${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}",
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),
        ),

        // Dropdown for Event Type
        DropdownButtonFormField<String>(
          value: _eventTypes[count],
          onChanged: (String? newValue) {
            setState(() {
              _selectedEventType = newValue ?? 'Meeting'; // Default value
            });
          },
          items: _eventTypes.map((String value) {
            // Get the corresponding icon for the event type
            Icon eventIcon = getAppointmentIcon(value);
            return DropdownMenuItem<String>(
              value: value,
              child: Row(
                children: [
                  eventIcon,
                  const SizedBox(width: 10), // Adds spacing between icon and text
                  Text(value),
                ],
              ),
            );
          }).toList(),
        ),

        // Description TextField
        TextField(
          controller: _descController,
          maxLines: 5,
          decoration: const InputDecoration(labelText: 'Description'),
        ),
        const SizedBox(height: 15),

        // Save Button
        ElevatedButton(
          onPressed: () {
            _updatePendingRequest();
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            backgroundColor: appGreen, // Adjust color as needed
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 5, // Adds a shadow effect for depth
          ),
          child: const Text(
            "Save",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Cancel Button
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            backgroundColor: Colors.red, // Adjust color as needed
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 5, // Adds a shadow effect for depth
          ),
          child: const Text(
            "Cancel",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Future<List<String>> _fetchEventTypes() async {
    try {
      List<String> eventTypes = [
        "Sunday Service",
        "Christmas Service",
        "Easter Service",
        "Wedding Ceremony",
        "Funeral Service",
        "Baptism",
        "Communion Service",
        "Infant Dedication",
        "Pastoral Visit",
        "Missionary Work",
        "Prayer Meeting",
        "Youth Fellowship",
        "Bible Study",
        "Church Anniversary",
        "Community Outreach",
        "Choir Practice",
        "Fellowship Meal",
        "Anniversary Service",
        "Membership Certificate",
        "Baptismal Certificate",
      ];
      return eventTypes;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching event types: $e');
      }
      return [];
    }
  }

  Future<void> _updatePendingRequest() async {
    try {
      final description = _descController.text;
      final selectedDate = _selectedDate;
      final selectedEventType = _selectedEventType;

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('No user is currently signed in');
        return;
      }


       final eventDocRef = FirebaseFirestore.instance
            .collection("users")
            .doc("members")
            .collection(currentUser.uid)
            .doc("Event")
            .collection("Pending Appointment")
            .doc(widget.documentId);

      
      await eventDocRef.update({
        "description": description,
        "date": Timestamp.fromDate(selectedDate),
        "appointmenttype": selectedEventType,
      });

      _showSuccessDialogEventEdit();
    } catch (e) {
      print('Error updating pending request: $e');
    }
  }


  void _showSuccessDialogEventEdit() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: const Text('Pending request updated successfully.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pop(context, true);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
 // void
}

