import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hablar_clone/models/user.dart' as model;
import 'package:hablar_clone/screens/landing_screen.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final isLoading = false.obs;

  Future<model.User?> getUserDetails(String uid) async {
    DocumentSnapshot snap = await _firestore.collection('users').doc(uid).get();
    if (snap.exists) {
      return model.User.fromSnap(snap);
    }
    return null;
  }

  Future<void> signUpUser() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill in all fields',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;
    try {
      // Check if user already exists
      QuerySnapshot querySnapshot =
          await _firestore
              .collection('users')
              .where('email', isEqualTo: emailController.text)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        Get.snackbar(
          'Error',
          'User already exists. Please log in.',
          snackPosition: SnackPosition.BOTTOM,
        );
        isLoading.value = false;
        return;
      }

      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      // ✅ Initialize WebRTC info as empty
      Map<String, dynamic> werbRtcInfo = {'offerSDP': '', 'iceCandidates': []};

      model.User user = model.User(
        name: nameController.text,
        email: emailController.text,
        photoUrl: '',
        password: passwordController.text,
        phone: '',
        uid: cred.user!.uid,
        bio: '',
        werbRtcInfo: werbRtcInfo,
        calls: [],
        favorites: [],
        contacts: [],
      );

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(cred.user!.uid)
          .set(user.toJson());

      Get.snackbar(
        'Success',
        'Signed up successfully!',
        snackPosition: SnackPosition.BOTTOM,
      );
      nameController.clear();
      emailController.clear();
      passwordController.clear();
      Get.to(LandingScreen());
    } catch (err) {
      Get.snackbar(
        'Error',
        err.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  //LogIn:
  Future<void> loginUser() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'All fields are required',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;
    try {
      // Check if user exists before logging in
      QuerySnapshot querySnapshot =
          await _firestore
              .collection('users')
              .where('email', isEqualTo: emailController.text)
              .get();

      if (querySnapshot.docs.isEmpty) {
        Get.snackbar(
          'Error',
          'User not found. Please sign up first.',
          snackPosition: SnackPosition.BOTTOM,
        );
        isLoading.value = false;
        return;
      }

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      // Retrieve WebRTC data from Firestore
      DocumentSnapshot userDoc =
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();
      //Map<String, dynamic>? webrtcData = userDoc['werbRtcInfo'];

      Get.snackbar(
        'Success',
        'Logged in successfully!',
        snackPosition: SnackPosition.BOTTOM,
      );
      nameController.clear();
      emailController.clear();
      passwordController.clear();
      Get.to(LandingScreen());
    } catch (err) {
      Get.snackbar(
        'Error',
        err.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
