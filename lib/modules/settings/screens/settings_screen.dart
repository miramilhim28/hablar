import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hablar_clone/modules/settings/controllers/settings_controller.dart';
import 'package:hablar_clone/modules/auth/screens/login_screen.dart';
import 'package:hablar_clone/modules/settings/screens/edit_screen.dart';
import 'package:hablar_clone/utils/colors.dart' as utils;

class SettingsScreen extends StatelessWidget {
  final SettingsController controller = Get.put(SettingsController());

  SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        } else if (controller.profile.value == null) {
          return const Center(child: Text('Failed to load user data'));
        } else {
          final profile = controller.profile.value!;
          return Container(
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

                  const SizedBox(height: 16),

                  //name
                  infoTile('Name', profile.name),
                  const SizedBox(height: 16),

                  //email
                  infoTile('Email', profile.email),
                  const SizedBox(height: 16),

                  //phone number:
                  infoTile('Phone Number', profile.phone),
                  const SizedBox(height: 16),

                  //password:
                  infoTile(
                    'Password',
                    controller.isPasswordVisible.value ? profile.password : '******',
                    trailing: IconButton(
                      icon: Icon(
                        controller.isPasswordVisible.value ? Icons.visibility : Icons.visibility_off,
                        color: utils.darkPurple,
                      ),
                      onPressed: controller.togglePasswordVisibility,
                    ),
                  ),
                  const SizedBox(height: 16),

                  //bio
                  infoTile('Bio', profile.bio),
                  const SizedBox(height: 16),

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
                  const SizedBox(height: 16),

                  //sign out button:
                  SizedBox(
                    width: 150,
                    child: ElevatedButton(
                      onPressed: () =>
                      Get.to(() => LoginScreen()),
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
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        }
      }),
    );
  }
}

Widget infoTile(String label, String value, {Widget? trailing}){
  return Container(
    width: 320,
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    decoration: BoxDecoration(
      color: utils.lightGrey,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: utils.darkGrey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                color: utils.darkPurple,
              ),
            ),
          ],
        ),
        if (trailing != null) trailing,
      ],
    ),
  );
}