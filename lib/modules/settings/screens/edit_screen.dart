import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hablar_clone/modules/settings/controllers/settings_controller.dart';
import 'package:hablar_clone/modules/home/screens/landing_screen.dart';
import 'package:hablar_clone/utils/colors.dart' as utils;

class EditScreen extends StatelessWidget {
  final SettingsController controller = Get.put(SettingsController());

  EditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [utils.purpleLilac, utils.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 40, bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: utils.darkPurple,
                        ),
                        onPressed: () => Get.back(),
                      ),
                      const Text(
                        'Edit User',
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

                // Name
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

                // Email
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

                SizedBox(
                  width: 300,
                  height: 50,
                  child: TextField(
                    controller:
                        controller.phoneController
                          ..text = controller.profile.value.phone,
                    keyboardType: TextInputType.phone,
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

                // Password
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

                // Bio
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

                // Save button
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
                              Get.off(() => LandingScreen());
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
        ),
      ),
    );
  }
}
