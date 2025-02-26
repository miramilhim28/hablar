import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hablar_clone/controllers/splash_controller.dart';
import 'package:hablar_clone/utils/colors.dart' as utils;

class SplashScreen extends StatelessWidget {
  SplashScreen({super.key});

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
          child: Image.asset(
            'assets/hablar_logo.png',
            width: 270,
            height: 50,
          ),
        ),
      ),
    );
  }
}
