import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hablar_clone/models/user.dart' as model;
import 'package:hablar_clone/screens/landing_screen.dart';
import 'package:hablar_clone/screens/auth_screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final isLoading = false.obs;

  // Save User Data Locally
  Future<void> _saveUserLocally(String uid) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('uid', uid);
  }

  // Sign Up
  Future<void> signUpUser() async {
    if (nameController.text.isEmpty || emailController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar('Error', 'Please fill in all fields', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isLoading.value = true;
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('users').where('email', isEqualTo: emailController.text).get();

      if (querySnapshot.docs.isNotEmpty) {
        Get.snackbar('Error', 'User already exists. Please log in.', snackPosition: SnackPosition.BOTTOM);
        isLoading.value = false;
        return;
      }

      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      Map<String, dynamic> werbRtcInfo = {'offerSDP': '', 'iceCandidates': []};

      model.User user = model.User(
        name: nameController.text,
        email: emailController.text,
        password: passwordController.text,
        phone: '',
        uid: cred.user!.uid,
        bio: '',
        werbRtcInfo: werbRtcInfo,
        calls: [],
        favorites: [],
        contacts: [],
      );

      await _firestore.collection('users').doc(cred.user!.uid).set(user.toJson());

      await _saveUserLocally(cred.user!.uid);

      Get.snackbar('Success', 'Signed up successfully!', snackPosition: SnackPosition.BOTTOM);
      nameController.clear();
      emailController.clear();
      passwordController.clear();
      Get.offAll(() => LandingScreen());
    } catch (err) {
      Get.snackbar('Error', err.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  // Log In
  Future<void> loginUser() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar('Error', 'All fields are required', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isLoading.value = true;
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('users').where('email', isEqualTo: emailController.text).get();

      if (querySnapshot.docs.isEmpty) {
        Get.snackbar('Error', 'User not found. Please sign up first.', snackPosition: SnackPosition.BOTTOM);
        isLoading.value = false;
        return;
      }

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      await _saveUserLocally(userCredential.user!.uid);

      Get.snackbar('Success', 'Logged in successfully!', snackPosition: SnackPosition.BOTTOM);
      nameController.clear();
      emailController.clear();
      passwordController.clear();
      Get.offAll(() => LandingScreen());
    } catch (err) {
      Get.snackbar('Error', err.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  // Log Out
  Future<void> logoutUser() async {
    await _auth.signOut();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Get.offAll(() => LoginScreen());
  }

  // Get User Details
  Future<model.User?> getUserDetails(String uid) async {
    DocumentSnapshot snap = await _firestore.collection('users').doc(uid).get();
    if (snap.exists) {
      return model.User.fromSnap(snap);
    }
    return null;
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
