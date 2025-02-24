import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hablar/screens/contact_screen.dart';
import '../resources/auth_methods.dart';

class OtpController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String verificationId;
  var isLoading = false.obs;

  get otpController => null;

  void setVerificationId(String id){
    verificationId = id;
  }

  //verify otp:
  Future<void> verifyOtp(String smsCode) async {
    isLoading.value = true;
    try {
      PhoneAuthCredential cred = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await _auth.signInWithCredential(cred);
      Get.snackbar('Success', 'Phone number is verified');
      Get.offAllNamed(ContactScreen as String);
    }
    catch (e){
      Get.snackbar('Error', 'Invalid OTP. Please try again');
    }
    finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose(){
    otpController.dispose();
    super.onClose();
  }
}