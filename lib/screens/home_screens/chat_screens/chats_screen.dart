import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hablar_clone/controllers/chats_controller.dart';
import 'package:hablar_clone/models/chats.dart';
import 'package:hablar_clone/utils/colors.dart' as utils;

class ChatsScreen extends StatelessWidget {
  final ChatsController controller = Get.put(ChatsController());

  ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [utils.purpleLilac, utils.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Chats',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: utils.darkGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Obx(() {
                  if (controller.chats.isEmpty) {
                    return Center(
                      child: Text(
                        'No chats available',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          color: utils.darkGrey,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: controller.chats.length,
                    itemBuilder: (context, index) {
                      final Chat chat = controller.chats[index];

                      return GestureDetector(
                        onTap: () {
                          Get.toNamed('/chat-details', arguments: {
                            'chatId': chat.chatId,
                            'contactName': chat.name
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: utils.lightGrey,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: utils.pinkLilac,
                                child: Text(
                                  chat.name[0],
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.bold,
                                    color: utils.darkGrey,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      chat.name,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: utils.darkGrey,
                                      ),
                                    ),
                                    Text(
                                      chat.lastMessage,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        color: utils.darkGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                chat.time.toDate().toLocal().toString().split(' ')[0],
                                style: TextStyle(color: utils.darkGrey),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
