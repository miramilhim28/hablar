import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hablar_clone/resources/auth_methods.dart';
import 'package:hablar_clone/screens/landing_screen.dart';

class AuthController extends GetxController {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final isLoading = false.obs;

  void loginUser() {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar('Error', 'All fields are required',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isLoading.value = true;

    Future.delayed(const Duration(seconds: 2), () {
      isLoading.value = false;
      Get.snackbar('Success', 'Logged in successfully!',
          snackPosition: SnackPosition.BOTTOM);
          Get.to(LandingScreen());
    });
  }

  Future<void> signUpUser() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      Get.snackbar('Error', 'Please fill in all fields',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isLoading.value = true;

    Future.delayed(const Duration(seconds: 2), () {
      isLoading.value = false;
      Get.snackbar('Success', 'Signed up successfully!',
          snackPosition: SnackPosition.BOTTOM);
    });
    await AuthMethods().signUpUser(name: nameController.text, email: emailController.text, password: passwordController.text,);
    Get.to(LandingScreen());
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
