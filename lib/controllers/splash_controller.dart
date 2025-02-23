import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:hablar/screens/login_screen.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _navigateToHome();
  }

  void _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3));
    Get.off(() => LoginScreen()); // Navigate to HomeScreen after splash
  }
}
