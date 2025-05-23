import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hablar_clone/models/profile.dart';
import 'package:hablar_clone/modules/auth/screens/login_screen.dart';

class SettingsController extends GetxController {
  var selectedIndex = 4;
  var nameController = TextEditingController();
  var bioController = TextEditingController();
  var emailController = TextEditingController();
  var phoneController = TextEditingController();
  var passwordController = TextEditingController();
  var profile = Profile(name: '', email: '', password: '', bio: '', phone: '').obs;
  var isPasswordVisible = false.obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUserData();
  }

  void fetchUserData() async {
  try {
    isLoading.value = true;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        profile.value = Profile(
          name: doc.data()?['name'] ?? '',
          email: doc.data()?['email'] ?? '',
          password: doc.data()?['password'] ?? '',
          phone: doc.data()?['phone'] ?? '', 
          bio: doc.data()?['bio'] ?? '',
        );
      } else {
        Get.snackbar('Error', 'No user profile found.');
      }
    }
    Get.back();
  } catch (e) {
    Get.snackbar('Error', 'Failed to load user data: $e');
  } finally {
    isLoading.value = false;
  }
}

  Future<void> updateUserData(String name, String email, String password, String phone, String bio) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null){
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          'bio': bio,
        });
        profile.value = Profile(
          name: name,
          email: email,
          password: password,
          phone: phone,
          bio: bio,
        );
      }
    } catch (e){
      Get.snackbar('Error', 'Failed to update profile: $e');
    }
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void signOut() async {
    await FirebaseAuth.instance.signOut();
    Get.toNamed(LoginScreen() as String);
  }
  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    bioController.dispose();
    super.onClose();
  }
}