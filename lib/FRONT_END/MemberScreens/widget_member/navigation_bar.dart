import 'package:bethel_app_final/BACK_END/Services/Functions/Authentication.dart';
import 'package:bethel_app_final/BACK_END/Services/Functions/Users.dart';
import 'package:bethel_app_final/FRONT_END/MemberScreens/home_page.dart';
import 'package:bethel_app_final/FRONT_END/MemberScreens/profile_page.dart';
import 'package:bethel_app_final/FRONT_END/MemberScreens/widget_member/Calendar.dart';
import 'package:bethel_app_final/FRONT_END/MemberScreens/eventPage.dart';
import 'package:bethel_app_final/FRONT_END/MemberScreens/NotificationTab.dart';
import 'package:bethel_app_final/FRONT_END/constant/color.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentTab = 0;
  int _notificationCount = 0; // Variable to store notification count

  final List<StatefulWidget> _children = [
    const MemberHomePage(),
    const EventPage(),
    const NotificationTab(), // Add NotificationTab instance here
    const Profile(),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize notification count
    _updateNotificationCount();
  }

  // Method to update notification count
  void _updateNotificationCount() {
    // Subscribe to notification stream and count unread notifications
    UserStorage().getNotification(TapAuth().auth.currentUser!.uid).listen((snapshot) {
      setState(() {
        _notificationCount = snapshot.docs.length;
      });
    });
  }

  //i taga zero sa counter hahahah
  void _resetNotificationCount() {
    setState(() {
      _notificationCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appGreen2,
      body: SafeArea(
        child: _children[_currentTab],
      ),
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        color: appGreen2,
        child: BottomNavigationBar(
          elevation: 6,
          backgroundColor: appGreen2,
          selectedItemColor: appBlack,
          unselectedItemColor: appWhite,
          type: BottomNavigationBarType.fixed,
          iconSize: 20.0,
          selectedFontSize: 12.0,
          unselectedFontSize: 12.0,

          onTap: (int value) {
            setState(() {
              _currentTab = value;
              if (value == 0) {
                _resetNotificationCount();
              }else if(value == 1) {
                _resetNotificationCount();
              }else if(value == 2) {
                _resetNotificationCount();
              }else if(value == 3) {
                _resetNotificationCount();
              }
            });
          },

          currentIndex: _currentTab,
          items: [
            BottomNavigationBarItem(
              icon: Icon(
                Icons.home,
                size: 20,
                color: _currentTab == 0 ? appBlack : appWhite, // Set icon color based on selection
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.event_available,
                size: 20,
                color: _currentTab == 1 ? appBlack : appWhite, // Set icon color based on selection
              ),
              label: 'Appointment',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  Icon(
                    Icons.notifications,
                    size: 20,
                    color: _currentTab == 2 ? appBlack : appWhite, // Set icon color based on selection
                  ),
                  if (_notificationCount > 0)
                    Positioned(
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$_notificationCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              label: 'Notifications',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.person,
                size: 20,
                color: _currentTab == 3 ? appBlack : appWhite, // Set icon color based on selection
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        margin: const EdgeInsets.only(top: 10),
        height: 64,
        width: 64,
        child: FloatingActionButton(
          backgroundColor: appWhite,
          elevation: 0,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CustomCalendar(type: "members")),
            );
          },
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 3, color: appGreen),
            borderRadius: BorderRadius.circular(100),
          ),
          child: const Icon(
            Icons.add,
            color: appGreen,
          ),
        ),
      ),
    );
  }
}
