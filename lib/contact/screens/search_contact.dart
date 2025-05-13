import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hablar_clone/contact/controllers/contact_controller.dart';
import 'package:hablar_clone/modules/home/screens/landing_screen.dart';
import 'package:hablar_clone/utils/colors.dart' as utils;

class NewContactScreen extends StatelessWidget {
  final ContactsController controller = Get.put(ContactsController());
  NewContactScreen({super.key});

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Get.to(() => LandingScreen()),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                  Text(
                    'Search',
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

            // search:
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: controller.phoneController,
                onChanged: (value) {
                  controller.updateSearch(value);
                  controller.phoneController.text = value;
                },
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Search by phone number',
                  prefixIcon: Icon(Icons.search),
                  filled: true,
                  fillColor: utils.lightGrey,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // search button:
            Obx(
              () => ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : () async {
                        await controller.searchContact(
                          controller.phoneController.text,
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: utils.darkPurple,
                  foregroundColor: utils.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.all(14),
                ),
                child: controller.isLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: utils.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Search',
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
