import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hablar_clone/controllers/info_controller.dart';
import 'package:hablar_clone/screens/home_screens/join_screen.dart';
import 'package:hablar_clone/utils/colors.dart' as utils;

class InfoScreen extends StatelessWidget {
  final InfoController controller = Get.put(InfoController());
  final contact = Get.arguments;
  InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    controller.phone.value = contact.phone;
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
                        Get.to(() => JoinScreen(selfCallerId: controller.name.value));
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
                      onTap: () {},
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: utils.pinkLilac,
                            child: Icon(Icons.videocam, color: utils.darkPurple),
                          ),
                          SizedBox(height: 5),
                          Text('Video', style: TextStyle(color: utils.darkGrey)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: utils.pinkLilac,
                            child: Icon(Icons.message, color: utils.darkPurple),
                          ),
                          SizedBox(height: 5),
                          Text('Message', style: TextStyle(color: utils.darkGrey)),
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
                    actionButton('Delete Contact', utils.pinkLilac, () {}),
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

