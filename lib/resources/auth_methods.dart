import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:hablar/screens/otp_screen.dart';
import 'package:hablar/controllers/otp_controller.dart';

class AuthMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  //send otp to phone number:
  Future<void> SignUpWithPhone({
    required String phone,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (AuthCredential credential) async {
        //user is signed up:
        UserCredential result = await _auth.signInWithCredential(credential);
        Get.snackbar('Success', 'Phone number automatically verified and signed up');
      },
      //failed:
      verificationFailed: (FirebaseAuthException e) {
        Get.snackbar('Error', e.message ?? 'Verification failed');
      },
      codeSent: (String verificationId, int? resendToken) {
        //navigate to otp screen:
        Get.to(() => OtpScreen(verificationId: verificationId));
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
      timeout: const Duration(seconds: 60),
    );
  }

  //verify otp code:
  Future<void> VerifyOtpCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      PhoneAuthCredential cred = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await _auth.signInWithCredential(cred);
      Get.snackbar('Success', 'Phone number verified and signed in');
    } catch (e) {
      Get.snackbar('Error', 'Invalid OTP. Please try again.');
    }
  }
}
