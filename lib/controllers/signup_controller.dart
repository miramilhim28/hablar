import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hablar/resources/auth_methods.dart';
import 'package:hablar/screens/otp_screen.dart';


class SignupController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final isLoading = false.obs;

  Future<void> signUpUser() async {
    if (nameController.text.isEmpty ||
        phoneController.text.isEmpty ||
        passwordController.text.isEmpty) {
      Get.snackbar('Error', 'Please fill in all fields');
      return;
    }

    isLoading.value = true;

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneController.text.trim(),
        verificationCompleted: (credential) async {
          await _auth.signInWithCredential(credential);
          Get.snackbar('Success', 'Phone number automatically verified!');
        },
        verificationFailed: (FirebaseAuthException e) {
          Get.snackbar('Error', e.message ?? 'Verification failed.');
        },
        codeSent: (String verificationId, int? resendToken) {
          Get.toNamed('/otp', arguments: {'verificationId': verificationId});
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }

    @override
    void onClose() {
      nameController.dispose();
      phoneController.dispose();
      passwordController.dispose();
      super.onClose();
    }
  }
}
