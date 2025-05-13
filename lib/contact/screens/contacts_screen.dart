import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hablar_clone/contact/screens/info_screen.dart';
import 'package:hablar_clone/contact/controllers/contact_controller.dart';
import 'package:hablar_clone/contact/controllers/favorites_controller.dart';
import 'package:hablar_clone/models/favorite.dart';
import 'package:hablar_clone/contact/screens/search_contact.dart';
import 'package:hablar_clone/utils/colors.dart' as utils;

class ContactScreen extends StatelessWidget {
  final ContactsController controller = Get.put(ContactsController());
  final FavoritesController favoritesController = Get.put(
    FavoritesController(),
  );

  ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [utils.purpleLilac, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'Contacts',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: utils.darkGrey,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: controller.updateSearch,
                  decoration: InputDecoration(
                    hintText: 'Search',
                    prefixIcon: Icon(Icons.search),
                    filled: true,
                    fillColor: utils.lightGrey,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: Obx(
                  () =>
                      controller.isLoading.value
                          ? Center(
                            child: CircularProgressIndicator(
                              color: utils.darkPurple,
                            ),
                          )
                          : controller.filteredContacts.isEmpty
                          ? Center(
                            child: Text(
                              'No contacts found',
                              style: TextStyle(
                                color: utils.darkGrey,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          )
                          : ListView.builder(
                            itemCount: controller.filteredContacts.length,
                            itemBuilder: (context, index) {
                              final contact =
                                  controller.filteredContacts[index];
                              bool isFav = favoritesController.isFavorite(
                                contact.id,
                              );

                              return Column(
                                children: [
                                  ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: utils.pinkLilac,
                                      child: Text(contact.name[0]),
                                    ),
                                    title: Text(
                                      contact.name,
                                      style: TextStyle(
                                        color: utils.darkGrey,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(
                                        isFav
                                            ? Icons.favorite
                                            : Icons.favorite_border_rounded,
                                        color: utils.darkPurple,
                                      ),
                                      onPressed: () {
                                        favoritesController.toggleFavorite(
                                          Favorite(
                                            id: contact.id,
                                            name: contact.name,
                                            phone: contact.phone,
                                          ),
                                        );
                                      },
                                    ),
                                    onTap: () {
                                      Get.to(
                                        () => InfoScreen(),
                                        arguments: contact,
                                      );
                                    },
                                  ),
                                  Divider(thickness: 1, color: utils.darkGrey),
                                ],
                              );
                            },
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => NewContactScreen()),
        backgroundColor: utils.pinkLilac,
        child: Icon(Icons.add),
      ),
    );
  }
}
