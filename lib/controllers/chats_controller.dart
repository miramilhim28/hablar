import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:hablar_clone/models/chats.dart';
import 'package:hablar_clone/models/message.dart';

class ChatsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  var chats = <Chat>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchChats();
  }

  void fetchChats() {
  String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  _firestore
      .collection('chats')
      .where('participants', arrayContains: currentUserId)
      .snapshots()
      .listen((snapshot) {
    chats.assignAll(snapshot.docs
        .map((doc) => Chat.fromJson(doc.data() as Map<String, dynamic>))
        .toList());
  });
}

  Stream<List<Message>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Message.fromJson(doc.data() as Map<String, dynamic>)).toList());
  }

  Future<void> sendMessage(String chatId, String senderId, String text) async {
    await _firestore.collection('chats').doc(chatId).collection('messages').add({
      'senderId': senderId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'messageType': 'text',
    });

    // Update last message in chat
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'time': FieldValue.serverTimestamp(),
    });
  }
}
