import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:bethel_app_final/FRONT_END/MemberScreens/screen_pages/profile_screen_pages/changepassword.dart';
import 'package:bethel_app_final/FRONT_END/constant/color.dart';
import 'package:bethel_app_final/BACK_END/Services/Functions/Authentication.dart';

import '../../../constant/color.dart';

class MyProfile extends StatefulWidget {
  const MyProfile({Key? key}) : super(key: key);

  @override
  State<MyProfile> createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  XFile? _image;
  TapAuth tapAuth = TapAuth();

  GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: appWhite, // Optional: AppBar background color
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 1000));
          setState(() {});
        },
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 0, left: 20, right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(color: appGreen),
                const SizedBox(height: 60),
                Center(
                  child: Stack(
                    children: [
                      Builder(
                        builder: (context) => CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage(
                              "${tapAuth.auth.currentUser?.photoURL}"),
                        ),
                      ),
                      Positioned(
                        child: IconButton(
                          onPressed: _addImageField,
                          icon: const Icon(Icons.add_a_photo),
                        ),
                        bottom: -10,
                        left: 65,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 30),
                    _buildInfoCard(
                      icon: Icons.person,
                      label:
                      'Name: ${tapAuth.auth.currentUser?.displayName ?? "No Name Provided"}',
                    ),
                    const SizedBox(height: 30),
                    _buildInfoCard(
                      icon: Icons.email,
                      label: 'Email: ${tapAuth.auth.currentUser?.email}',
                    ),
                    const SizedBox(height: 50),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ChangePassword(),
                            ),
                          );
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(appGreen2),
                        ),
                        child: const Text(
                          'Change Password',
                          style: TextStyle(color: appWhite),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addImageField() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image =
    await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _image = image;
      });
      tapAuth.auth.currentUser?.updatePhotoURL(image.path);
      await Future.delayed(const Duration(seconds: 1));
      _refreshIndicatorKey.currentState?.show();
    }
  }

  Widget _buildInfoCard({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
