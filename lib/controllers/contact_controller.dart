import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hablar_clone/controllers/favorites_controller.dart';
import 'package:hablar_clone/models/contact.dart' as model;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hablar_clone/models/favorite.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

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
        Get.snackbar("Error", "No user is logged in");
        return;
      }

      // 1. Get local phone numbers from device
      List<String> localNumbers = await getNormalizedPhoneNumbersFromDevice();

      if (localNumbers.isEmpty) {
        contacts.clear();
        return;
      }

      // 2. Fetch matching users from Firestore in batches of 10
      List<model.Contact> matchedContacts = [];

      for (int i = 0; i < localNumbers.length; i += 10) {
        final batch = localNumbers.sublist(
          i,
          i + 10 > localNumbers.length ? localNumbers.length : i + 10,
        );
        final querySnapshot =
            await _firestore
                .collection('users')
                .where('phone', whereIn: batch)
                .get();

        final batchContacts =
            querySnapshot.docs.map((doc) {
              var data = doc.data();
              return model.Contact(
                id: doc.id,
                name: data['name'] ?? '',
                phone: data['phone'] ?? '',
                email: data['email'] ?? '',
                bio: data['bio'] ?? '',
              );
            }).toList();

        matchedContacts.addAll(batchContacts);
      }

      contacts.value = matchedContacts;
      filterContacts(); // Apply search filter
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<String>> getNormalizedPhoneNumbersFromDevice() async {
    List<String> numbers = [];

    if (await FlutterContacts.requestPermission()) {
      final contacts = await FlutterContacts.getContacts(withProperties: true);

      for (var contact in contacts) {
        for (var phone in contact.phones) {
          try {
            // Parse using region code
            final parsed = PhoneNumber.parse(
              phone.number,
              destinationCountry: IsoCode.JO,
            );
            final e164 = parsed.getFormattedNsn();

            // Get full E.164 format
            final fullNumber = '+${parsed.countryCode}$e164';

            numbers.add(fullNumber);
          } catch (e) {
            // Skip invalid numbers
          }
        }
      }
    }

    return numbers.toSet().toList(); // Remove duplicates
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

      // Normalize the phone number to E.164 format
      String normalizedPhone;
      try {
        final parsed = PhoneNumber.parse(
          phone,
          destinationCountry: IsoCode.JO,
        ); // replace with your country code
        normalizedPhone = '+${parsed.countryCode}${parsed.getFormattedNsn()}';
      } catch (e) {
        Get.snackbar(
          "Error",
          "Invalid phone number format",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Create a new contact object with normalized phone
      model.Contact newContact = model.Contact(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        phone: normalizedPhone,
        email: "",
        bio: "",
      );

      // Firestore operations
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

      List<dynamic> currentContacts = userSnapshot.data()?['contacts'] ?? [];
      currentContacts.add(newContact.toJson());

      await userRef.update({'contacts': currentContacts});

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
