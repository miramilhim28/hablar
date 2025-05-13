import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:hablar_clone/modules/chat/controllers/chats_controller.dart';
import 'package:hablar_clone/models/message.dart';
import 'package:hablar_clone/modules/call/screens/join_screen.dart';
import 'package:hablar_clone/utils/colors.dart' as utils;

class ChatMsgsScreen extends StatelessWidget {
  final ChatsController controller = Get.put(ChatsController());
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final Map<String, dynamic> chatData = Get.arguments;

  ChatMsgsScreen({super.key});

  String formatTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
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

  @override
  Widget build(BuildContext context) {
    final String receiverId = chatData['receiverId'];
    final String receiverName = chatData['contactName'];
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    final List<String> ids = [currentUserId, receiverId]..sort();
    final String chatId = ids.join('_');
    _clearUnreadCount(chatId, currentUserId);


    return Scaffold(
      appBar: AppBar(
        backgroundColor: utils.darkGrey,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: utils.pinkLilac),
          onPressed: () => Get.back(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: utils.pinkLilac,
              child: Text(
                receiverName[0],
                style: TextStyle(
                  color: utils.darkGrey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              receiverName,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                color: utils.pinkLilac,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: utils.pinkLilac),
            onPressed: () {
              Get.to(() => JoinScreen(
                    callerId: currentUserId,
                    calleeId: receiverId,
                    callType: "audio",
                    isVideo: false, 
                  ));
            },
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.videocam, color: utils.pinkLilac),
            onPressed: () {
              Get.to(() => JoinScreen(
                    callerId: currentUserId,
                    calleeId: receiverId,
                    callType: "video",
                  ));
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [utils.purpleLilac, utils.white],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Message>>(
                stream: controller.getMessages(chatId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text("📭 No messages yet"));
                  }

                  final messages = snapshot.data!;

                  _markDeliveredAndRead(chatId, messages, currentUserId);

                  return ListView.builder(
                    controller: scrollController,
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isSentByMe = message.senderId == currentUserId;

                      String tick = "";
                      if (isSentByMe) {
                        if (message.readBy.contains(receiverId)) {
                          tick = "✔️✔️";
                        } else {
                          tick = "✔️";
                        }
                      }

                      final bubbleColor =
                          isSentByMe ? utils.darkPurple : utils.purpleLilac;
                      final textColor =
                          isSentByMe ? utils.white : utils.darkGrey;

                      return Align(
                        alignment: isSentByMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 12),
                          decoration: BoxDecoration(
                            color: bubbleColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: isSentByMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      message.text,
                                      style: TextStyle(color: textColor),
                                    ),
                                  ),
                                  if (isSentByMe) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      tick,
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatTime(message.timestamp),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: textColor.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            _buildMessageInput(chatId, currentUserId, receiverId, receiverName),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(
    String chatId,
    String senderId,
    String receiverId,
    String receiverName,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: utils.darkGrey,
      child: Row(
        children: [
          const Icon(Icons.keyboard_alt_outlined, color: Colors.blueGrey),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: utils.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Type a message',
                  hintStyle: TextStyle(color: Colors.blueGrey),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.send, color: utils.pinkLilac),
            onPressed: () {
              if (messageController.text.trim().isNotEmpty) {
                controller.sendMessage(
                  senderId,
                  receiverId,
                  receiverName,
                  messageController.text.trim(),
                );
                messageController.clear();
                _scrollToBottom();
              }
            },
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      scrollController.animateTo(
        scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }
  void _clearUnreadCount(String chatId, String userId) async {
  final unreadRef = FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('unread')
      .doc(chatId);

  await unreadRef.set({'count': 0});
}


  void _markDeliveredAndRead(
      String chatId, List<Message> messages, String currentUserId) async {
    final batch = FirebaseFirestore.instance.batch();
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

    for (final msg in messages) {
      final msgRef = chatRef.collection('messages').doc(msg.id);

      if (!msg.deliveredTo.contains(currentUserId)) {
        batch.update(msgRef, {
          'deliveredTo': FieldValue.arrayUnion([currentUserId]),
        });
      }

      if (!msg.readBy.contains(currentUserId)) {
        batch.update(msgRef, {
          'readBy': FieldValue.arrayUnion([currentUserId]),
        });
      }
    }

    await batch.commit();
  }
}
