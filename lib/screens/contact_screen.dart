import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hablar/controllers/splash_controller.dart';
import 'package:hablar/utils/colors.dart' as utils;

class ContactScreen extends StatelessWidget {
  ContactScreen({super.key});

  final SplashController controller = Get.put(SplashController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              utils.purpleLilac,
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: Text('HABLAR'),
        ),
      ),
    );
  }
}