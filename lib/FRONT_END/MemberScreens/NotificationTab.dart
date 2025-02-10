import 'package:bethel_app_final/BACK_END/Services/Functions/Authentication.dart';
import 'package:bethel_app_final/BACK_END/Services/Functions/Users.dart';
import 'package:bethel_app_final/FRONT_END/constant/color.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class NotificationTab extends StatefulWidget {
  const NotificationTab({Key? key});

  @override
  State<NotificationTab> createState() => _NotificationTabState();
}

class _NotificationTabState extends State<NotificationTab> {
  late Stream<QuerySnapshot> _notificationStream;
  Map<String, bool> showOptionsMap = {};
  Set<String> clickedNotificationIds = {};
  int _notificationCount = 0;

  @override
  void initState() {
    _notificationStream = UserStorage()
        .getNotification(TapAuth()
        .auth.currentUser!
        .uid);
    _notificationStream = _getNotificationStream();
    super.initState();
  }
  Stream<QuerySnapshot> _getNotificationStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return FirebaseFirestore.instance
        .collection("users")
        .doc("members")
        .collection(uid)
        .doc("Event")
        .collection("Notification")
        .snapshots();
  }
  void _markAllAsRead() async {
    try {
      final snapshot = await _notificationStream.first; // Get the current notifications
      final notifications = snapshot.docs;

      for (var doc in notifications) {
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(doc.id)
            .update({'isRead': true});
      }
      // Optionally show a confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read.')),
      );
    } catch (e) {
      // Handle errors
      print('Error marking notifications as read: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error marking notifications as read.')),
      );
    }
  }

  Future<void> _markAsRead(String documentId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc("members")
          .collection(uid)
          .doc("Event")
          .collection("Notification")
          .doc(documentId)
          .update({"isRead": true});
    } catch (e) {
      print("Error marking notification as read: $e");
    }
  }

  Future<void> _deleteNotification(String documentId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc("members")
          .collection(uid)
          .doc("Event")
          .collection("Notification")
          .doc(documentId)
          .delete();
    } catch (e) {
      print("Error deleting notification: $e");
    }
  }

  Future<void> deleteNotifications(String uid, String documentId) async {
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc("members")
          .collection(uid)
          .doc("Event")
          .collection("Notification")
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



  Future<void> markNotificationAsRead(String uid, String documentId) async {
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc("members")
          .collection(uid)
          .doc("Event")
          .collection("Notification")
          .doc(documentId)
          .update({"isRead": true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 25, left: 20, right: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 15),
            const Divider(color: Colors.green),
            const SizedBox(height: 5),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _notificationStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: LoadingAnimationWidget.staggeredDotsWave(
                        color: appGreen,
                        size: 50.0,
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No notifications...',
                        style: TextStyle(fontSize: 18, color: appGrey),
                      ),
                    );
                  }

                  final notifications = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final doc = notifications[index];
                      final notif = doc.data() as Map<String, dynamic>;
                      final isRead = notif['isRead'] ?? false;
                      final date = (notif['date'] as Timestamp).toDate();
                      final formattedDate = DateFormat('MMM dd, yyyy').format(date);

                      // Define badge color based on status
                      Color badgeColor;
                      switch (notif['status']) {
                        case 'Approved':
                          badgeColor = Colors.green;
                          break;
                        case 'Denied':
                          badgeColor = Colors.red;
                          break;
                        default:
                          badgeColor = Colors.blue;
                      }

                      return GestureDetector(
                        onTap: isRead ? null : () => _markAsRead(doc.id),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: isRead
                                ? Colors.grey[300] // Color for read notifications
                                : Colors.green[200], // Color for unread notifications
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                blurRadius: 8,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notif['appointmenttype'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 20,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    if (!isRead)
                                      Container(
                                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          "New",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: badgeColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    notif['status'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                Row(
                                  children: [
                                    const Text(
                                      'Date: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      '$formattedDate',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),

                                Row(
                                  children: [
                                    const Text(
                                      'Time: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      notif['status'] == 'Denied'
                                          ? 'Admin suggests you to reschedule'
                                          : '9:30 AM onwards', // Default value
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: notif['status'] == 'Denied' ? FontWeight.bold : FontWeight.normal,
                                        color: notif['status'] == 'Denied' ? Colors.red : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),


                                const SizedBox(height: 2),
                                if (notif['status'] == 'Denied')
                                  GestureDetector(
                                    onTap: () {
                                      // Navigate to the edit appointment page
                                      Navigator.pushNamed(context, '/editAppointment', arguments: doc.id);
                                    },
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [

                                        Text(
                                          'Reason:  ',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),

                                        ),
                                        Text(
                                          '"Conflicts with higher priority appointment."',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 2),

                                Text.rich(
                                  TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: 'Description:  ',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '${notif['description'] ?? ''}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        FontAwesomeIcons.trashCan,
                                        color: Colors.red,
                                        size: 20.0,
                                      ),
                                      onPressed: () => _deleteNotification(doc.id),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
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


}
