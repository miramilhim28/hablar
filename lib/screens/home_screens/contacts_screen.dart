import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hablar_clone/controllers/contact_controller.dart';
import 'package:hablar_clone/utils/colors.dart' as utils;

class ContactScreen extends StatelessWidget {
  final ContactsController controller = Get.put(ContactsController());

   ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              utils.purpleLilac,
              Colors.white,
            ],
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
                      color: utils.darkGrey
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
                    border:OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: Obx(() => ListView.builder(
                  itemCount: controller.contacts.length,
                  itemBuilder: (context, index) {
                    final contact = controller.filteredContacts[index];
                    return Column(
                      children: [
                        ListTile(
                          title: Text(
                            contact.name,
                            style: TextStyle(color: utils.darkGrey),
                          ),
                        ),
                        Divider(thickness: 1, color: utils.darkGrey),
                      ],
                    );
                  },
                ),),
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