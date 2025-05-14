import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hablar_clone/modules/contact/controllers/info_controller.dart';
import 'package:hablar_clone/modules/chat/screens/chat_msgs_screen.dart';
import 'package:hablar_clone/modules/call/screens/join_screen.dart';
import 'package:hablar_clone/utils/colors.dart' as utils;

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  final InfoController controller = Get.put(InfoController());
  late final dynamic contact;

  @override
  void initState() {
    super.initState();
    contact = Get.arguments;

    // Fetch contact data based on id
    if (contact is Map) {
      controller.fetchContactData(contact['id']);
    } else {
      controller.fetchContactData(contact.id);
    }
  }

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
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: utils.darkGrey),
                        onPressed: () => Get.back(),
                      ),
                      const SizedBox(width: 60),
                      const Text(
                        'Contact Details',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: utils.darkGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: utils.pinkLilac,
                        child: Text(
                          (controller.profile.value.name.isNotEmpty
                              ? controller.profile.value.name[0]
                              : 'N'),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 50,
                            color: utils.darkGrey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        controller.profile.value.name.isNotEmpty
                            ? controller.profile.value.name
                            : 'No Name Provided',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: utils.darkGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _actionButton(
                        icon: Icons.call,
                        label: 'Call',
                        onTap: () {
                          String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
                          Get.to(
                            () => JoinScreen(
                              callerId: currentUserId,
                              calleeId: contact is Map ? contact['id'] : contact.id,
                              callType: "audio",
                              isVideo: false, 
                            ),
                          );
                        },
                      ),
                      _actionButton(
                        icon: Icons.videocam,
                        label: 'Video',
                        onTap: () {
                          String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
                          Get.to(
                            () => JoinScreen(
                              callerId: currentUserId,
                              calleeId: contact is Map ? contact['id'] : contact.id,
                              callType: "video",
                            ),
                          );
                        },
                      ),
                      _actionButton(
                        icon: Icons.message,
                        label: 'Message',
                        onTap: () {
                          String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
                          List<String> ids = [
                            currentUserId,
                            contact is Map ? contact['id'] : contact.id,
                          ];
                          ids.sort();
                          String chatId = ids.join("_");

                          Get.to(
                            () => ChatMsgsScreen(),
                            arguments: {
                              'receiverId': contact is Map ? contact['id'] : contact.id,
                              'contactName': controller.profile.value.name,
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _infoTile('Mobile', controller.profile.value.phone),
                      _infoTile('Bio', controller.profile.value.bio),
                      _infoTile('Email', controller.profile.value.email),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _infoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: utils.darkGrey,
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: utils.lightGrey,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              value.isNotEmpty ? value : 'Not Provided',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                color: utils.darkGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: utils.pinkLilac,
            child: Icon(icon, color: utils.darkPurple),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(color: utils.darkGrey)),
        ],
      ),
    );
  }
}
