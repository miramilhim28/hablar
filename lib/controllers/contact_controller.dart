import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hablar_clone/controllers/favorites_controller.dart';
import 'package:hablar_clone/models/contact.dart' as model;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hablar_clone/models/favorite.dart';

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

      print("Current User UID: ${currentUser.uid}");

      // Fetch all users except the current user
      var snapshot =
          await _firestore
              .collection('users')
              .where('uid', isNotEqualTo: currentUser.uid)
              .orderBy('uid')
              .get();

      print("Fetched ${snapshot.docs.length} user documents");

      // Convert Firestore data to Contact objects
      List<model.Contact> fetchedContacts =
          snapshot.docs.map((doc) {
            var data = doc.data();
            return model.Contact(
              id: doc.id, // Store Firestore document ID as the contact's ID
              name: data['name'] ?? '',
              phone: data['phone'] ?? '',
              email: data['email'] ?? '',
              bio: data['bio'] ?? '',
            );
          }).toList();

      // Update local contacts list
      contacts.value = fetchedContacts;
      filterContacts(); // Apply search filter

      // Convert contacts to JSON format for Firestore storage
      List<Map<String, dynamic>> contactJsonList =
          fetchedContacts.map((contact) => contact.toJson()).toList();

      // Update Firestore with new contacts list under the current user's document
      var userRef = _firestore.collection('users').doc(currentUser.uid);
      await userRef.update({'contacts': contactJsonList});

      print("Contacts updated in Firestore!");
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

      // Create a new contact object with a unique ID.
      model.Contact newContact = model.Contact(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        phone: phone,
        email: "",
        bio: "",
      );

      // Fetch the current user's document from Firestore
      var userRef = _firestore.collection('users').doc(currentUser.uid);
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

      // Get the current contacts from Firestore (if any)
      List<dynamic> currentContacts = userSnapshot.data()?['contacts'] ?? [];

      // Add the new contact to the contacts list
      currentContacts.add(newContact.toJson());

      // Update the user's document with the new contacts list
      await userRef.update({'contacts': currentContacts});

      // Update local list
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

  void toggleFavorite(model.Contact contact) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    var userRef = _firestore.collection('users').doc(currentUser.uid);
    var favoritesController = Get.find<FavoritesController>();

    try {
      bool isFavorite = favoritesController.favorites.any(
        (c) => c.id == contact.id,
      );

      if (isFavorite) {
        // Remove from favorites
        favoritesController.favorites.removeWhere((c) => c.id == contact.id);
      } else {
        // Add to favorites
        Favorite newFavorite = Favorite(
          id: contact.id,
          name: contact.name,
          phone: contact.phone,
        );
        favoritesController.favorites.add(newFavorite);
      }

      // Update Firestore
      await userRef.update({
        'favorites':
            favoritesController.favorites.map((c) => c.toJson()).toList(),
      });

      favoritesController.favorites.refresh(); // Update UI
    } catch (e) {
      print("Error updating favorite status: $e");
    }
  }

  // Delete Contact
  Future<void> deleteContact(String contactId) async {
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

      // Fetch the current user's document
      var userRef = _firestore.collection('users').doc(currentUser.uid);
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

      // Get the current contacts from Firestore (if any)
      List<dynamic> currentContacts = userSnapshot.data()?['contacts'] ?? [];

      // Remove the contact from the list
      currentContacts.removeWhere((contact) => contact['id'] == contactId);

      // Update Firestore with the new contacts list
      await userRef.update({'contacts': currentContacts});

      // Remove the contact from the local list
      contacts.removeWhere((contact) => contact.id == contactId);
      contacts.refresh(); // Refresh the contacts list to notify the UI

      Get.snackbar(
        "Success",
        "Contact deleted successfully!",
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
}
