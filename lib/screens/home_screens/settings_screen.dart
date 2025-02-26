import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hablar_clone/controllers/settings_controller.dart';
import 'package:hablar_clone/screens/home_screens/edit_screen.dart';
import 'package:hablar_clone/utils/colors.dart' as utils;

class SettingsScreen extends StatelessWidget {
  final SettingsController controller = Get.put(SettingsController());

   SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [utils.purpleLilac, utils.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 24,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      color: utils.darkGrey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Icon(Icons.person, color: utils.darkPurple, size: 100),

              const SizedBox(height: 24),

              //name
              SizedBox(
                width: 300,
                height: 50,
                child: TextField(
                  controller: SettingsController().nameController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: utils.lightGrey,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              //bio
              SizedBox(
                width: 300,
                height: 50,
                child: TextField(
                  controller: SettingsController().bioController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: utils.lightGrey,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              //phoe number
              SizedBox(
                width: 300,
                height: 50,
                child: TextField(
                  controller: SettingsController().bioController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: utils.lightGrey,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              //edit button:
              SizedBox(
                width: 150,
                child: ElevatedButton(
                    onPressed: () {
                      Get.to(() => EditScreen());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: utils.pinkLilac,
                      foregroundColor: utils.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.all(14),
                    ),
                    child: const Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        color: utils.white,
                      ),
                    ),
                  ),
              ),
              const SizedBox(height: 24),

              //sign out button:
              SizedBox(
                width: 150,
                child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: utils.darkPurple,
                      foregroundColor: utils.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.all(14),
                    ),
                    child: const Text(
                      'Sign Out',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        color: utils.white,
                      ),
                    ),
                  ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
