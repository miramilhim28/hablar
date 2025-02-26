import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hablar_clone/utils/colors.dart' as utils;
import 'package:hablar_clone/controllers/favorites_controller.dart';

class FavoritesScreen extends StatelessWidget {
  final FavoritesController controller = Get.put(FavoritesController());

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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Spacer(),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'Edit',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Obx(
                    () => ListView.builder(
                      itemCount: controller.filteredContacts.length,
                      itemBuilder: (context, index) {
                        final contact = controller.filteredContacts[index];
                        return Column(
                          children: [
                            ListTile(
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
                              trailing: Icon(
                                Icons.info,
                                color: utils.darkPurple,
                              ),
                            ),
                            Divider(thickness: 1, color: utils.darkGrey),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: utils.pinkLilac,
        child: Icon(Icons.add),
      ),
    );
  }
}
