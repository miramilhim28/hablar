import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hablar_clone/controllers/chats_controller.dart';
import 'package:hablar_clone/models/message.dart';
import 'package:hablar_clone/utils/colors.dart' as utils;

class ChatMsgsScreen extends StatelessWidget {
  final ChatsController controller = Get.put(ChatsController());
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final Map<String, dynamic> chatData = Get.arguments;

  ChatMsgsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String chatId = chatData['chatId'];
    String contactName = chatData['contactName'];
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

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
                contactName[0],
                style: TextStyle(color: utils.darkGrey, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              contactName,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                color: utils.pinkLilac,
              ),
            ),
          ],
        ),
        actions: const [
          Icon(Icons.call, color: utils.pinkLilac),
          SizedBox(width: 16),
          Icon(Icons.videocam, color: utils.pinkLilac),
          SizedBox(width: 16),
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
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  var messages = snapshot.data!;
                  return ListView.builder(
                    controller: scrollController,
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      bool isSentByMe = message.senderId == currentUserId;
                      Color bubbleColor = isSentByMe ? utils.darkPurple : utils.purpleLilac;
                      Color textColor = isSentByMe ? utils.white : utils.darkGrey;

                      return Align(
                        alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          padding: EdgeInsets.all(12),
                          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                          decoration: BoxDecoration(
                            color: bubbleColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            message.text,
                            style: TextStyle(color: textColor),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            _buildMessageInput(chatId, currentUserId),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(String chatId, String currentUserId) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                decoration: InputDecoration(
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
                controller.sendMessage(chatId, currentUserId, messageController.text.trim());
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
    Future.delayed(Duration(milliseconds: 100), () {
      scrollController.animateTo(
        scrollController.position.minScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }
}
