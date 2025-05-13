import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hablar_clone/contact/screens/info_screen.dart';
import 'package:hablar_clone/utils/colors.dart' as utils;
import 'package:hablar_clone/contact/controllers/favorites_controller.dart';

class FavoritesScreen extends StatelessWidget {
  final FavoritesController favoritesController = Get.put(
    FavoritesController(),
  );

  FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [utils.purpleLilac, utils.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'Favorites',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: utils.darkGrey,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Obx(() {
                    final favorites = favoritesController.favorites;

                    return favorites.isEmpty
                        ? Center(
                          child: Text(
                            'No favorites yet',
                            style: TextStyle(
                              color: utils.darkGrey,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        )
                        : ListView.builder(
                          itemCount: favorites.length,
                          itemBuilder: (context, index) {
                            final contact = favorites[index];

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
                                      Icons.favorite,
                                      color: utils.darkPurple,
                                    ),
                                    onPressed: () {
                                      favoritesController.toggleFavorite(
                                        contact,
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
                        );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
