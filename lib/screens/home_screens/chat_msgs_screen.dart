import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hablar_clone/models/chats.dart';
import 'package:hablar_clone/utils/colors.dart' as utils;

class ChatMsgsScreen extends StatelessWidget {
  final Chat chat = Get.arguments as Chat;

   ChatMsgsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              child: Text(chat.name[0]),
            ),
            const SizedBox(width: 10),
            Text(
              chat.name,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                color: utils.pinkLilac,
              ),
            ),
          ],
        ),
        actions: const [
            Icon(Icons.call, color: utils.pinkLilac,),
            SizedBox(width: 16),
            Icon(Icons.videocam, color: utils.pinkLilac,),
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
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildMessageBubble(isSentByMe: false, color: utils.purpleLilac),
                  _buildMessageBubble(isSentByMe: true, color: utils.darkPurple),
                  _buildMessageBubble(isSentByMe: false, color: utils.purpleLilac),
                  _buildMessageBubble(isSentByMe: true, color: utils.darkPurple),
                ],
              ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }
}

Widget _buildMessageBubble({required bool isSentByMe, required Color color}){
  return Align(
    alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      width: 200,
      child: const Text(
        'Message',
        style: TextStyle(
          color: utils.white
        ),
      ),
    ),
  );
}

Widget _buildMessageInput(){
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
            child: const TextField(
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Type a message',
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Icon(Icons.image, color: Colors.blueGrey),
      ],
    ),
  );
}