import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:hablar_clone/modules/chat/controllers/chats_controller.dart';
import 'package:hablar_clone/models/chats.dart';
import 'package:hablar_clone/modules/chat/screens/chat_msgs_screen.dart';
import 'package:hablar_clone/utils/colors.dart' as utils;

class ChatsScreen extends StatelessWidget {
  final ChatsController controller = Get.put(ChatsController());

  ChatsScreen({super.key});

  String formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return DateFormat('h:mm a').format(date);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(date);
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  Widget slideLeftBackground() {
    return Container(
      color: Colors.red,
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: 20),
      child: Icon(Icons.delete, color: Colors.white),
    );
  }

  Widget slideRightBackground() {
    return Container(
      color: Colors.grey,
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.only(left: 20),
      child: Icon(Icons.volume_off, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

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

                      if (chat.lastMessage.trim().isEmpty) {
                        return const SizedBox(); // Skip empty chats
                      }

                      final isUnread = !chat.readBy.contains(currentUserId);
                      final receiverId = chat.participants.firstWhere(
                        (id) => id != currentUserId,
                        orElse: () => '',
                      );

                      return StreamBuilder<int>(
                        stream: controller.getUnreadCount(chat.chatId, currentUserId),
                        builder: (context, snapshot) {
                          final unreadCount = snapshot.data ?? 0;

                          return Dismissible(
                            key: Key(chat.chatId),
                            background: slideRightBackground(),
                            secondaryBackground: slideLeftBackground(),
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.startToEnd) {
                                Get.snackbar("Muted", "${chat.name} has been muted");
                                return false;
                              } else if (direction == DismissDirection.endToStart) {
                                await controller.deleteChat(chat.chatId);
                                return true;
                              }
                              return false;
                            },
                            child: GestureDetector(
                              onTap: () {
                                FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(currentUserId)
                                    .collection('unread')
                                    .doc(chat.chatId)
                                    .set({'count': 0});
                                Get.to(
                                  () => ChatMsgsScreen(),
                                  arguments: {
                                    'receiverId': receiverId,
                                    'contactName': chat.name,
                                  },
                                );
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
                                        chat.name.isNotEmpty ? chat.name[0] : '?',
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
                                              fontWeight: isUnread || unreadCount > 0
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: utils.darkGrey,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${chat.lastMessageSenderId == currentUserId ? "You" : chat.name}: ${chat.lastMessage}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 14,
                                              color: utils.darkGrey,
                                              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          formatTimestamp(chat.time),
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 12,
                                            color: utils.darkGrey,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        if (unreadCount > 0)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: utils.darkPurple,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '$unreadCount',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
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
