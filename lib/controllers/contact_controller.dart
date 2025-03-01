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

  /// **Add Contact to Firestore**
  Future<void> addContact({
  required String name,
  required String phone,
}) async {
  if (name.isEmpty || phone.isEmpty) return;

  isLoading.value = true;
  try {
    // Get the current user's ID
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      Get.snackbar("Error", "No user is logged in", backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    
    // Create the contact object
    model.Contact contact = model.Contact(id: '', name: name, phone: phone);
    
    // Fetch the user document
    DocumentReference userRef = _firestore.collection('users').doc(currentUser.uid);

    // Add the contact to the user's contacts list
    await userRef.update({
      'contacts': FieldValue.arrayUnion([contact.toJson()]), // Add the contact to the contacts array
    });

    // Clear input fields
    nameController.clear();
    phoneController.clear();

    // Fetch updated contacts for the user
    getContacts(currentUser.uid);  // Make sure to reload the contacts after adding
  } catch (err) {
    Get.snackbar("Error", err.toString(), backgroundColor: Colors.red, colorText: Colors.white);
  } finally {
    isLoading.value = false;
  }
}


  /// **Fetch Contacts from Firestore**
Future<void> getContacts(String uid) async {
  isLoading.value = true;
  try {
    // Fetch the user's document from Firestore using the UID
    var snapshot = await _firestore.collection('users').doc(uid).get();
    
    // Check if the document exists
    if (!snapshot.exists) {
      Get.snackbar("Error", "User document not found", backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    // Extract the contacts array from the user's document
    var userData = snapshot.data();
    List<dynamic> contactList = userData?['contacts'] ?? [];

    // Convert the contacts data into model.Contact objects
    contacts.value = contactList.map((contactData) => model.Contact.fromJson(contactData)).toList();

    // Apply search filter after fetching contacts
    filterContacts();
  } catch (err) {
    Get.snackbar("Error", err.toString(), backgroundColor: Colors.red, colorText: Colors.white);
  } finally {
    isLoading.value = false;
  }
}

/// **Filter Contacts Based on Search Input**
void filterContacts() {
  filteredContacts.value = contacts
      .where((contact) => contact.name.toLowerCase().contains(search.value.toLowerCase()))
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
