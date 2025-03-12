import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InfoController extends GetxController {
  var selectedIndex = 5;
  var name = ''.obs;
  var phone = ''.obs;
  var bio = ''.obs;
  var email = ''.obs;

  // Method to set contact details
  void setContactDetails(String newName, String newMobile, String newBio, String newEmail) {
    name.value = newName;
    phone.value = newMobile;
    bio.value = newBio;
    email.value = newEmail;
  }

  // Fetch contact details from Firestore based on contact ID
  Future<void> fetchContactDetails(String contactId) async {
    try {
      DocumentSnapshot contactSnapshot = await FirebaseFirestore.instance
          .collection('contacts')
          .doc(contactId)
          .get();

      if (contactSnapshot.exists) {
        var contactData = contactSnapshot.data() as Map<String, dynamic>;
        name.value = contactData['name'] ?? 'No name';
        phone.value = contactData['mobile'] ?? 'No mobile';
        bio.value = contactData['bio'] ?? 'No bio';
        email.value = contactData['email'] ?? 'No email';
      } else {
        print('Contact not found');
      }
    } catch (e) {
      print('Error fetching contact details: $e');
    }
  }

  void updateSelectedIndex(int index) {
    selectedIndex = index;
  }

  @override
  void onClose() {
    super.onClose();
  }
}
