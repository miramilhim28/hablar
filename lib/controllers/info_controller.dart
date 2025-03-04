import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hablar_clone/models/contact.dart' as model;

class InfoController extends GetxController {
  var selectedIndex = 5;
  var name = ''.obs;
  var phone = ''.obs;
  var bio = ''.obs;
  var email = ''.obs;

  void setContactDetails(String newName, String newMobile, String newBio, String newEmail) {
    name.value = newName;
    phone.value = newMobile;
    bio.value = newBio;
    email.value = newEmail;
  }

  void updateSelectedIndex(int index){
    selectedIndex = index;
  }
}
