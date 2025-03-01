import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:hablar_clone/controllers/settings_controller.dart';
import 'package:hablar_clone/screens/home_screens/settings_screen.dart';
import 'package:hablar_clone/utils/colors.dart' as utils;

class EditScreen extends StatelessWidget {
  final SettingsController controller = Get.put(SettingsController());

  EditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [utils.purpleLilac, utils.white],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 40, bottom: 16), 
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: utils.darkPurple,
                    ),
                    onPressed: () => Get.to(() => SettingsScreen()),
                  ),
                  Text(
                    'Edit Contact',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: utils.darkGrey,
                    ),
                  ),
                  Container(width: 60),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Icon(Icons.add_a_photo, color: utils.darkPurple, size: 100),

            const SizedBox(height: 24),

            //name
            SizedBox(
              width: 300,
              height: 50,
              child: TextField(
                controller:
                    controller.nameController
                      ..text = controller.profile.value.name,
                decoration: InputDecoration(
                  hintText: 'Edit Name',
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

            //email
            SizedBox(
              width: 300,
              height: 50,
              child: TextField(
                controller:
                    controller.emailController
                      ..text = controller.profile.value.email,
                decoration: InputDecoration(
                  hintText: 'Edit Email',
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

            //phone number
            SizedBox(
              width: 300,
              height: 50,
              child: TextField(
                controller:
                    controller.phoneController
                      ..text = controller.profile.value.phone,
                decoration: InputDecoration(
                  hintText: 'Edit Phone Number',
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

            //password
            SizedBox(
              width: 300,
              height: 50,
              child: TextField(
                controller:
                    controller.passwordController
                      ..text = controller.profile.value.password,
                decoration: InputDecoration(
                  hintText: 'Edit Password',
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
                controller:
                    controller.bioController
                      ..text = controller.profile.value.bio,
                decoration: InputDecoration(
                  hintText: 'Edit Bio',
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

            //save button:
            SizedBox(
              width: 150,
              child: ElevatedButton(
                onPressed:
                    controller.isLoading.value
                        ? null
                        : () {
                          controller.updateUserData(
                            controller.nameController.text,
                            controller.emailController.text,
                            controller.passwordController.text,
                            controller.phoneController.text,
                            controller.bioController.text,
                          );
                          Get.off(() => SettingsScreen());
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
                  'Save Changes',
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
    );
  }
}
