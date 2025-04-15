import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hablar_clone/controllers/call_signalling_controller.dart';
import 'package:hablar_clone/controllers/home_controller.dart';
import 'package:hablar_clone/utils/colors.dart' as utils;

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final HomeController controller = Get.put(HomeController());

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final callController = Get.find<CallSignallingController>();
      callController.listenForIncomingCalls(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<HomeController>(
        builder: (controller) => controller.pages[controller.selectedIndex],
      ),
      bottomNavigationBar: GetBuilder<HomeController>(
        builder: (controller) {
          return BottomNavigationBar(
            currentIndex: controller.selectedIndex,
            onTap: controller.updateSelectedIndex,
            backgroundColor: utils.white,
            selectedItemColor: utils.darkPurple,
            unselectedItemColor: utils.pinkLilac,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite),
                label: 'Favorites',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.call), label: 'Calls'),
              BottomNavigationBarItem(
                icon: Icon(Icons.contacts),
                label: 'Contacts',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_rounded),
                label: 'Chats',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          );
        },
      ),
    );
  }
}
