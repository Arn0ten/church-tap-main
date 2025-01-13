import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class UserStorage {
  //TODO write database for all users
  final FirebaseFirestore db = FirebaseFirestore.instance;


  Future<void> createUser(String uniqueID,
      Map<String, String> userInformation, String type) async {
    try {
      db.collection("users")
          .doc(type)
          .collection(uniqueID)
          .doc("About User")
          .set(userInformation);
    }
    catch (e) {
      log("Error code STORAGE: $e");
    }
  }


  Future<void> createMemberEvent(String uniqueID, Map<String, dynamic> dateTime,
      String type) async {
    try {
      if (type == "members") {
        db.collection("users")
            .doc("members")
            .collection(uniqueID)
            .doc("Event")
            .collection("Pending Appointment")
            .doc().set(dateTime);
      }
      else {
        db.collection("users")
            .doc("admins")
            .collection(uniqueID)
            .doc("Event")
            .collection("Church Event")
            .doc().set(dateTime);
      }
    } catch (e) {
      log("Error code STORAGE: $e");
    }
  }

  Future<List<DateTime>> getApprovedDate(String uid, String type) async {
    List<DateTime> documents = [];
    try {
      if (type == "members") {
        await db.collection("users")
            .doc("members")
            .collection(uid)
            .doc("Event")
            .collection("Approved Appointment")
            .get()
            .then((value) {
          for (var element in value.docs) {
            Timestamp t = element.data()["date"];
            DateTime dats = t.toDate();
            documents.add(dats);
          }
        });
      }
      else {
        await db.collectionGroup("Church Event")
            .get()
            .then((value) {
          for (var element in value.docs) {
            Timestamp t = element.data()["date"];
            DateTime dats = t.toDate();
            documents.add(dats);
          }
        });
      }
    }
    catch (e) {

    }
    return documents;
  }

  Future<List<DateTime>> getPendingDate(String uid) async {
    List<DateTime> documents = [];
    await db.collection("users")
        .doc("members")
        .collection(uid)
        .doc("Event")
        .collection("Pending Appointment")
        .get()
        .then((value) {
      for (var element in value.docs) {
        Timestamp t = element.data()["date"];
        DateTime dats = t.toDate();
        documents.add(dats);
      }
    });
    return documents;
  }

  Future<void> setDisableDay(Map<String, dynamic> dateTime, String uid) async {
    try {
      db.collection("users")
          .doc("admins")
          .collection(uid)
          .doc("Event")
          .collection("Disabled Days")
          .doc()
          .set(dateTime);
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> unsetDisableDay(int day, int month, int year) async {
    db.collectionGroup("Disabled Days")
        .get()
        .then((value) {
      for (var element in value.docs) {
        var a = element.data()['date'];
        Timestamp timestamp = a;
        DateTime dateTime = timestamp.toDate();
        if (dateTime.day == day && dateTime.month == month &&
            dateTime.year == year) {
          db.runTransaction((Transaction transaction) async {
            transaction.delete(element.reference);
          },);
          // Remove Break due to duplicate disabled dates
        }
        else {
          continue;
        }
      }
    },);
  }

  Future<List<DateTime>> getDisableDay() async {
    List<DateTime> documents = [];
    try {
      await db.collectionGroup("Disabled Days")
          .get()
          .then((value) {
        for (var element in value.docs) {
          Timestamp t = element.data()["date"];
          DateTime dats = t.toDate();
          documents.add(dats);
        }
      },);
    } catch (e) {}
    return documents;
  }

  Stream<QuerySnapshot> fetchPendingAppointments(String uid) {
    return db
        .collection("users")
        .doc("members")
        .collection(uid)
        .doc("Event")
        .collection("Pending Appointment")
        .snapshots();
  }


  Stream<QuerySnapshot> fetchAllPendingAppointments() {
    return db
        .collectionGroup("Pending Appointment")
        .snapshots();
  }

  Stream<QuerySnapshot> fetchApprovedAppointments(String uid) {
    return db
        .collection("users")
        .doc("members")
        .collection(uid)
        .doc("Event")
        .collection("Approved Appointment")
        .snapshots();
  }

  Stream<QuerySnapshot> fetchAllApprovedAppointments() {
    return db
        .collectionGroup("Approved Appointment")
        .snapshots();
  }

  Future<void> approvedAppointment(String userID, String appointmentId) async {
    try {
      DocumentSnapshot appointmentDoc = await db
          .collection("users")
          .doc("members")
          .collection(userID)
          .doc("Event")
          .collection("Pending Appointment")
          .doc(appointmentId)
          .get();

      // Get the date of the approved appointment
      DateTime appointmentDate = (appointmentDoc.data() as Map<String, dynamic>)['date'].toDate();

      // Deny all other appointments on the same date
      await denyOtherAppointmentsOnSameDate(userID, appointmentId, appointmentDate);

      // Update status field to 'Approved'
      await db
          .collection("users")
          .doc("members")
          .collection(userID)
          .doc("Event")
          .collection("Pending Appointment")
          .doc(appointmentId)
          .update({'status': 'Approved'});

      log("Appointment $appointmentId approved for user $userID.");

      await setNotification(userID, appointmentId);

      // Move appointment to 'Approved Appointment' collection
      await db
          .collection("users")
          .doc("members")
          .collection(userID)
          .doc("Event")
          .collection("Approved Appointment")
          .doc(appointmentId) // Use the same appointmentId
          .set(appointmentDoc.data() as Map<String, dynamic>);

      // Delete from 'Pending Appointment' collection
      await db
          .collection("users")
          .doc("members")
          .collection(userID)
          .doc("Event")
          .collection("Pending Appointment")
          .doc(appointmentId)
          .delete();

    } catch (e) {
      log("Error approving appointment: $e");
    }
  }

  /////////// gi strip nalang nako ang date
  Future<void> denyOtherAppointmentsOnSameDate(String userID, String approvedAppointmentId, DateTime appointmentDate) async {
    try {
      // Strip the time from the appointmentDate (set the time to midnight)
      DateTime startOfDay = DateTime(appointmentDate.year, appointmentDate.month, appointmentDate.day);
      DateTime endOfDay = startOfDay.add(Duration(days: 1)).subtract(Duration(milliseconds: 1));

      // Fetch all pending appointments for the same user on the same date
      QuerySnapshot pendingAppointments = await db
          .collection("users")
          .doc("members")
          .collection(userID)
          .doc("Event")
          .collection("Pending Appointment")
          .where('date', isGreaterThanOrEqualTo: startOfDay)
          .where('date', isLessThanOrEqualTo: endOfDay)
          .get();

      // Check if there are pending appointments for the same date
      log("Found ${pendingAppointments.docs.length} appointments on the same date.");

      // Deny all other appointments except the approved one
      for (var doc in pendingAppointments.docs) {
        String appointmentId = doc.id;
        log("Checking appointment: $appointmentId");

        if (appointmentId != approvedAppointmentId) {
          log("Denying appointment $appointmentId for user $userID because it conflicts with the approved appointment.");
          await denyAppointment(userID, appointmentId);
        } else {
          log("Skipping appointment $appointmentId as it is the approved one.");
        }
      }

    } catch (e) {
      log("Error denying other appointments on the same date: $e");
    }
  }



  Future<void> denyAppointment(String userID, String appointmentId) async {
    try {
      DocumentSnapshot appointmentDoc = await db
          .collection("users")
          .doc("members")
          .collection(userID)
          .doc("Event")
          .collection("Pending Appointment")
          .doc(appointmentId)
          .get();

      // Update status field to 'Denied'
      await db
          .collection("users")
          .doc("members")
          .collection(userID)
          .doc("Event")
          .collection("Pending Appointment")
          .doc(appointmentId)
          .update({'status': 'Denied'});
      await setNotification(userID, appointmentId);

      // Move appointment to 'Denied Appointment' collection
      await db
          .collection("users")
          .doc("members")
          .collection(userID)
          .doc("Event")
          .collection("Denied Appointment")
          .doc(appointmentId)
          .set(appointmentDoc.data() as Map<String, dynamic>);

      // Delete from 'Pending Appointment' collection
      await db
          .collection("users")
          .doc("members")
          .collection(userID)
          .doc("Event")
          .collection("Pending Appointment")
          .doc(appointmentId)
          .delete();
    } catch (e) {
      log("Error denying appointment: $e");
    }
  }


  Stream<QuerySnapshot> fetchDenyAppointment() {
    return db
        .collectionGroup("Denied Appointment")
        .snapshots();
  }


  Stream<QuerySnapshot> fetchCreateMemberEvent() {
    return db
        .collectionGroup("Church Event")
        .snapshots();
  }

  Future<void> setNotification(String uid, String appointmentId) async {
    DocumentSnapshot documentSnapshot = await db
        .collection("users")
        .doc("members")
        .collection(uid)
        .doc("Event")
        .collection("Pending Appointment")
        .doc(appointmentId)
        .get();
    await db.
    collection("users")
        .doc('members')
        .collection(uid)
        .doc('Event')
        .collection('Notification')
        .doc(appointmentId)
        .set(documentSnapshot.data() as Map<String, dynamic>);
  }

  Stream<QuerySnapshot> getNotification(String uid) {
    return db
        .collection('users')
        .doc('members')
        .collection(uid)
        .doc('Event')
        .collection('Notification')
        .snapshots();
  }

  // Future<void> UnreadNotification(String uid, String appointmentId) async {
  //   DocumentSnapshot documentSnapshot = await db
  //       .collection("users")
  //       .doc("members")
  //       .collection(uid)
  //       .doc("Event")
  //       .collection("Notification")
  //       .doc(appointmentId)
  //       .get();
  //   await db.
  //   collection("users")
  //       .doc('members')
  //       .collection(uid)
  //       .doc('Event')
  //       .collection('Unread')
  //       .doc(appointmentId)
  //       .set(documentSnapshot.data() as Map<String, dynamic>);
  // }

  Future<bool> checkAdmin(String uid) async {
    bool a = false;
    var test = db.collection('users')
        .doc('admins').get();
    test.then((value) {
      if (uid == value.id) {
        a = true;
      }
      else {
        a = false;
      }
    },);
    return a;
  }

  Future<bool> checkAdmins(String uid) async {
    bool check = false;
    await db.collection('users').doc('admins').collection(uid).get().then((
        value) {
      if (value.size > 0) {
        check = true;
      }
      else {
        check = false;
      }
    },);
    return check;
  }

  Future<void> deleteOldDates() async{
  //disabled Days
   db.collectionGroup('Church Event').where('date',isLessThan: DateTime.now()).get().then((value) {
     value.docs.clear();
   },);
  }




}