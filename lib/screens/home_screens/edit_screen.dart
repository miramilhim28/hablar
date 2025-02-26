import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:hablar_clone/controllers/settings_controller.dart';
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
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: utils.darkPurple,
                    ),
                    onPressed: () {
                      Get.back();
                    },
                  ),
                  Expanded(
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
                controller: SettingsController().nameController,
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

            //bio
            SizedBox(
              width: 300,
              height: 50,
              child: TextField(
                controller: SettingsController().bioController,
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

            //phone number
            SizedBox(
              width: 300,
              height: 50,
              child: TextField(
                controller: SettingsController().bioController,
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

            //save button:
            SizedBox(
              width: 150,
              child: ElevatedButton(
                onPressed: () async {
                  if (await confirm(
                    context,
                    title: const Text('Confirm', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: utils.darkPurple),),
                    content:const Text('Your changes have been saved successfully!', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: utils.darkGrey),),
                    textOK: const Text('Ok', style: TextStyle(fontFamily: 'Poppins', color: utils.darkPurple),),
                    textCancel: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins', color: utils.darkGrey),),
                  )) {
                  return log('Saved');
                  }
                  return log('Canceled');
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
