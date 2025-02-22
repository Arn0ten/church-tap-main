import 'package:bethel_app_final/FRONT_END/MemberScreens/screen_pages/profile_screen_pages/my_profile.dart';
import 'package:bethel_app_final/FRONT_END/MemberScreens/screen_pages/profile_screen_pages/settings.dart';
import 'package:bethel_app_final/FRONT_END/authentications/admin_auth/admin_register_page.dart';
import 'package:bethel_app_final/FRONT_END/constant/color.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../authentications/option_to_loginform/option_what_account_to_use.dart';


void signUserOut() {
  FirebaseAuth.instance.signOut();
}

class AdminSettings extends StatefulWidget {
  const AdminSettings({super.key});

  @override
  _AdminSettingsState createState() => _AdminSettingsState();
}

class _AdminSettingsState extends State<AdminSettings> {
  final textStyleState = const TextStyle(fontSize: 11.0, color: Colors.white);

  final textStyleTop = const TextStyle(
      fontSize: 22.0, fontWeight: FontWeight.bold, color: Colors.white);

  final textStyle2 = const TextStyle(color: Colors.white);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.only(top: 5, left: 20, right: 20),

        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) =>  MyProfile()
                  ),
                  );
                },
                style: IconButton.styleFrom(
                ),
                icon: const Icon(
                    Icons.person,
                ),
              ),
              const Text(
                "Settings",
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

          Padding(
            padding: const EdgeInsets.all(15),
            child: Text(
              "Account settings".toUpperCase(),
              style: const TextStyle(
                color: appGrey,
                fontSize: 15,

              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>  MyProfile()),
              );
            },
            child: const Padding(
              padding: EdgeInsets.all(15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Text(
                      "Personal informations",
                      style: TextStyle(
                          color: appBlack,
                          fontSize: 17,
                          fontWeight: FontWeight.w300),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.person,
                    color: appBlack,
                  ),
                ],
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 30),
            decoration: const BoxDecoration(
              color: Colors.black12,
            ),
            width: 50,
            height: 1,
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminRegisterPage(onTap: (){
                  Navigator.pop(context);
                }
                )
                ),
              );
            },
            child: const Padding(
              padding: EdgeInsets.all(15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Text(
                      "Create Admin Account",
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 17,
                          fontWeight: FontWeight.w300),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.account_box,
                    color: appBlack,
                  ),
                ],
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 30),
            decoration: const BoxDecoration(
              color: Colors.black12,
            ),
            width: 50,
            height: 1,
          ),


          Container(
            margin: const EdgeInsets.symmetric(horizontal: 30),
            decoration: const BoxDecoration(
              color: Colors.black12,
            ),
            width: 50,
            height: 1,
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Text(
              "Log out".toUpperCase(),
              style: const TextStyle(
                  color: appGrey,
                  fontSize: 15,

              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 30),
            decoration: const BoxDecoration(
              color: Colors.black12,
            ),
            width: 50,
            height: 1,
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Confirm Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close the dialog
                        },
                        child: const Text(
                          'No',
                          style: TextStyle(color: appBlack),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.of(context).pop(); // Close the dialog
                          showDialog(
                            context: context,
                            barrierDismissible: false, // Prevent closing the dialog
                            builder: (BuildContext context) {
                              return Center(
                                child: LoadingAnimationWidget.staggeredDotsWave(
                                  color: appGreen,
                                  size: 50,
                                ),
                              );
                            },
                          );

                          try {
                            await FirebaseAuth.instance.signOut(); // Perform Firebase sign-out
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OptionToPlatformToLogin(),
                              ),
                            ); // Navigate to OptionToPlatformToLogin page
                          } catch (e) {
                            Navigator.of(context).pop(); // Close the loading animation
                            print("Error signing out: $e");
                          }
                        },
                        child: const Text(
                          'Yes',
                          style: TextStyle(color: appRed),
                        ),
                      ),
                    ],
                  );
                },
              );
            },

            child: const Padding(
              padding: EdgeInsets.all(15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Text(
                      "Sign out",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w300,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.exit_to_app,
                    color: Colors.redAccent,
                  ),
                ],
              ),
            ),
          ),



          Container(
            margin: const EdgeInsets.symmetric(horizontal: 30),
            decoration: const BoxDecoration(
              color: Colors.black12,
            ),
            width: 50,
            height: 1,
          ),
          const Padding(
            padding: EdgeInsets.all(15),
            child: Text(
              "Version 2.14.2024",
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
