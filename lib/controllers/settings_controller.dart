import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:hablar_clone/models/profile.dart';

class SettingsController extends GetxController{
  var selectedIndex = 4;
  var nameController = TextEditingController();
  var bioController = TextEditingController();
  var emailController = TextEditingController();
  var profile = Profile(name: 'John Doe', email: 'test@gmail.com', password: '123456', bio: 'Test').obs;

  void updateSelectedIndex(int index){
    selectedIndex = index;
  }
}