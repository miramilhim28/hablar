import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hablar_clone/models/contact.dart' as model;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ContactsController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  var search = ''.obs;
  var selectedIndex = 2;
  var nameController = TextEditingController();
  var phoneController = TextEditingController();
  var contacts = <model.Contact>[].obs;
  var filteredContacts = <model.Contact>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    getContacts(); // Fetch all users except the current user
  }

  // Fetch all users from Firestore (excluding the current user)
  Future<void> getContacts() async {
    isLoading.value = true;
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        Get.snackbar(
          "Error",
          "No user is logged in",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Fetch all users from Firestore
      var snapshot = await _firestore.collection('users').get();

      contacts.value =
          snapshot.docs
              .map((doc) => model.Contact.fromJson(doc.data()))
              .where(
                (contact) =>
                    contact.email != null &&
                    contact.email!.isNotEmpty &&
                    contact.id != currentUser.uid,
              ) // Exclude current user
              .toList();

      filterContacts(); // Apply search filter
    } catch (err) {
      Get.snackbar(
        "Error",
        err.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Add a new contact to Firestore and update the current user's contact list
  Future<void> addContact({required String name, required String phone}) async {
    if (name.isEmpty || phone.isEmpty) {
      Get.snackbar(
        "Error",
        "Please enter both name and phone number",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        Get.snackbar(
          "Error",
          "No user is logged in",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Create a new contact object
      model.Contact newContact = model.Contact(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Using timestamp for a unique ID
        name: name,
        phone: phone,
        email: "", // Email is optional
      );

      // Fetch the current user's document from Firestore
      var userRef = _firestore.collection('users').doc(currentUser.uid);

      // Fetch the current user to get their contacts list
      var userSnapshot = await userRef.get();
      if (!userSnapshot.exists) {
        Get.snackbar(
          "Error",
          "User not found",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Get the current contacts from Firestore
      List<dynamic> currentContacts = userSnapshot.data()?['contacts'] ?? [];

      // Add the new contact to the user's contacts list
      currentContacts.add(newContact.toJson());

      // Update the user's contacts in Firestore
      await userRef.update({
        'contacts': currentContacts,
      });

      // Add the new contact to the local contacts list and refresh the display
      contacts.add(newContact);
      filterContacts();

      Get.back(); // Close the screen after adding
      Get.snackbar(
        "Success",
        "Contact added successfully!",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (err) {
      Get.snackbar(
        "Error",
        err.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Filter Contacts Based on Search Input
  void filterContacts() {
    filteredContacts.value =
        contacts
            .where(
              (contact) => contact.name.toLowerCase().contains(
                search.value.toLowerCase(),
              ),
            )
            .toList();
  }

  void updateSearch(String s) {
    search.value = s;
    filterContacts();
  }

  void updateSelectedIndex(int index) {
    selectedIndex = index;
  }
}






