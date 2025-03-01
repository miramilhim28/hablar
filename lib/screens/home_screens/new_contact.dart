import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hablar_clone/controllers/contact_controller.dart';
import 'package:hablar_clone/screens/home_screens/contacts_screen.dart';
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
                    onPressed: () => Get.to(() => ContactScreen()),
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
                    'New Contact',
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

            Icon(Icons.person, color: utils.darkPurple, size: 100),
            
            const SizedBox(height: 24),

            //name:
            SizedBox(
              width: 300,
              height: 50,
              child: TextField(
                controller: controller.nameController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "Contact's name",
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

            //phone:
            SizedBox(
              width: 300,
              height: 50,
              child: TextField(
                controller: controller.phoneController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Phone Number',
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
            Obx(
              () => ElevatedButton(
                onPressed:
                    controller.isLoading.value
                        ? null
                        : () {
                          controller.addContact(
                            name: controller.nameController.text,
                            phone: controller.phoneController.text,
                          );
                          Get.off(() => ContactScreen());
                        },
                style: ElevatedButton.styleFrom(
                  backgroundColor: utils.darkPurple,
                  foregroundColor: utils.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.all(14),
                ),
                child:
                    controller.isLoading.value
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: utils.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Text(
                          'Save',
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
