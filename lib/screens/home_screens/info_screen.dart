import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hablar_clone/controllers/info_controller.dart';
import 'package:hablar_clone/controllers/contact_controller.dart';
import 'package:hablar_clone/models/contact.dart' as model;
import 'package:hablar_clone/screens/home_screens/chat_screens/chat_msgs_screen.dart';
import 'package:hablar_clone/screens/home_screens/contacts_screen.dart';
import 'package:hablar_clone/screens/home_screens/call_screens/join_screen.dart';
import 'package:hablar_clone/utils/colors.dart' as utils;

class InfoScreen extends StatelessWidget {
  final InfoController controller = Get.put(InfoController());
  final ContactsController contactsController = Get.find<ContactsController>();
  final contact = Get.arguments;

  InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Fetch contact details from the ContactsController when the screen is initialized
    _fetchContactDetails();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [utils.purpleLilac, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: utils.darkGrey),
                      onPressed: () => Get.back(),
                    ),
                    SizedBox(width: 60),
                    Text(
                      'Contact Details',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: utils.darkGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: utils.pinkLilac,
                      child: Text(
                        contact.name[0],
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 50,
                          color: utils.darkGrey,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Obx(
                      () => Text(
                        controller.name.value,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: utils.darkGrey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () {
                        // Fetch the current user's ID
                        String currentUserId =
                            FirebaseAuth.instance.currentUser?.uid ?? '';
                        Get.to(
                          () => JoinScreen(
                            callerId: currentUserId,
                            calleeId: contact.id,
                            callType: "audio",
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: utils.pinkLilac,
                            child: Icon(Icons.call, color: utils.darkPurple),
                          ),
                          SizedBox(height: 5),
                          Text('Call', style: TextStyle(color: utils.darkGrey)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Fetch the current user's ID
                        String currentUserId =
                            FirebaseAuth.instance.currentUser?.uid ?? '';
                        Get.to(
                          () => JoinScreen(
                            callerId: currentUserId,
                            calleeId: contact.id,
                            callType: "video",
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: utils.pinkLilac,
                            child: Icon(
                              Icons.videocam,
                              color: utils.darkPurple,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Video',
                            style: TextStyle(color: utils.darkGrey),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        String currentUserId =
                            FirebaseAuth.instance.currentUser?.uid ?? '';

                        List<String> ids = [currentUserId, contact.id];
                        ids.sort();
                        String chatId = ids.join("_");

                        Get.to(
                          () => ChatMsgsScreen(),
                          arguments: {
                            'chatId': chatId,
                            'contactName': contact.name,
                          },
                        );
                      },
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: utils.pinkLilac,
                            child: Icon(Icons.message, color: utils.darkPurple),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Message',
                            style: TextStyle(color: utils.darkGrey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Obx(() => infoTile('Mobile', controller.phone.value)),
                    Obx(() => infoTile('Bio', controller.bio.value)),
                    Obx(() => infoTile('Email', controller.email.value)),
                    SizedBox(height: 20),
                    actionButton('Delete Contact', utils.pinkLilac, () {
                      // Show confirmation dialog for deleting contact
                      _showDeleteDialog(context);
                    }),
                    actionButton('Block Caller', Colors.red.shade800, () {}),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Fetch contact details from ContactsController
  void _fetchContactDetails() {
    var contactDetails = contactsController.contacts.firstWhere(
      (contact) => contact.id == this.contact.id,
      orElse:
          () => model.Contact(id: '', name: '', phone: '', email: '', bio: ''),
    );

    controller.setContactDetails(
      contactDetails.name,
      contactDetails.phone,
      contactDetails.bio,
      contactDetails.email,
    );
  }

  // Show confirmation dialog to delete contact
  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Are you sure you want to delete the contact?",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              color: utils.darkGrey,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _deleteContact();
                Navigator.of(context).pop();
                Get.offAll(() => ContactScreen());
              },
              child: Text(
                "Yes",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: utils.darkPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                // Close the dialog and stay on the current screen
                Navigator.of(context).pop();
              },
              child: Text(
                "No",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: utils.darkPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Delete contact
  void _deleteContact() {
    contactsController.deleteContact(contact.id);
    Get.back();
  }

  Widget infoTile(String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: utils.darkGrey,
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: utils.lightGrey,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(value, style: TextStyle(color: utils.darkGrey)),
          ),
        ],
      ),
    );
  }

  Widget actionButton(String text, Color color, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          minimumSize: Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Poppins',
            color: utils.darkGrey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
