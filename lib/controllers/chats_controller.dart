import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hablar_clone/models/chats.dart';
import 'package:hablar_clone/models/message.dart';

class ChatsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  RxSet<String> unreadChatIds = <String>{}.obs;
  var chats = <Chat>[].obs;
  var selectedIndex = 3;

  @override
  void onInit() {
    super.onInit();
    fetchChats();
    initFCM();
  }

  // ✅ Firebase Cloud Messaging initialization
  void initFCM() async {
    await _firebaseMessaging.requestPermission();

    String? token = await _firebaseMessaging.getToken();
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (token != null && userId.isNotEmpty) {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
      });
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        Get.snackbar(
          message.notification!.title ?? 'New message',
          message.notification!.body ?? '',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
      }
    });
  }

  // ✅ Fetch chats and show the latest message
  void fetchChats() {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('time', descending: true)
        .snapshots()
        .listen((snapshot) async {
          List<Chat> validChats = [];

          for (var doc in snapshot.docs) {
            final chatData = doc.data();
            final chatId = doc.id;

            try {
              final participants = List<String>.from(
                chatData['participants'] ?? [],
              );
              final readBy = List<String>.from(chatData['readBy'] ?? []);
              final timestamp = chatData['time'] ?? Timestamp.now();

              final lastMessage = chatData['lastMessage'] ?? '';
              final lastMessageSenderId = chatData['lastMessageSenderId'] ?? '';

              if (lastMessage.trim().isEmpty) continue;

              final otherUserId = participants.firstWhere(
                (id) => id != currentUserId,
                orElse: () => '',
              );

              String userName = 'Unknown';
              if (otherUserId.isNotEmpty) {
                final userDoc =
                    await _firestore.collection('users').doc(otherUserId).get();
                userName = userDoc.data()?['name'] ?? 'Unknown';
              }

              final chat = Chat(
                chatId: chatId,
                name: userName,
                lastMessage: lastMessage,
                lastMessageSenderId: lastMessageSenderId,
                time: timestamp,
                participants: participants,
                readBy: readBy,
              );

              validChats.add(chat);
            } catch (e) {
              print("⚠️ Error loading chat $chatId: $e");
            }
          }

          chats.assignAll(validChats);
        });
  }

  // ✅ Get message stream
  Stream<List<Message>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Message.fromJson(doc.data(), doc.id))
                  .toList(),
        );
  }

  // ✅ Send new message
  Future<void> sendMessage(
    String senderId,
    String receiverId,
    String receiverName,
    String text,
  ) async {
    final List<String> ids = [senderId, receiverId]..sort();
    final String chatId = ids.join('_');
    final chatRef = _firestore.collection('chats').doc(chatId);
    final chatSnapshot = await chatRef.get();

    // Create chat if it doesn't exist yet
    if (!chatSnapshot.exists) {
      final newChat = Chat(
        chatId: chatId,
        name: receiverName,
        lastMessage: text,
        time: Timestamp.now(),
        participants: [senderId, receiverId],
        lastMessageSenderId: senderId,
        readBy: [senderId],
      );
      await chatRef.set(newChat.toJson());
    }

    final messageData = {
      'senderId': senderId,
      'text': text,
      'timestamp': Timestamp.now(),
      'messageType': 'text',
      'deliveredTo': [],
      'readBy': [senderId],
    };

    await chatRef.collection('messages').add(messageData);

    // Update chat summary info
    await chatRef.update({
      'lastMessage': text,
      'lastMessageSenderId': senderId,
      'time': Timestamp.now(),
      'readBy': [senderId],
    });

    // Increment unread count for receiver
    final unreadRef = _firestore
        .collection('users')
        .doc(receiverId)
        .collection('unread')
        .doc(chatId);

    await unreadRef.set({
      'count': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  Stream<int> getUnreadCount(String chatId, String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('unread')
        .doc(chatId)
        .snapshots()
        .map((snap) => snap.data()?['count'] ?? 0);
  }

  Future<void> deleteChat(String chatId) async {
    await _firestore.collection('chats').doc(chatId).delete();
  }

  void updateSelectedIndex(int index) {
    selectedIndex = index;
  }
}
