import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String chatId;
  final String name;
  final String lastMessage;
  final Timestamp time;
  final List<String> participants;
  final String lastMessageSenderId;
  final List<String> readBy;

  Chat({
    required this.chatId,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.participants,
    required this.lastMessageSenderId,
    required this.readBy,
  });

  Map<String, dynamic> toJson() => {
        'chatId': chatId,
        'name': name,
        'lastMessage': lastMessage,
        'time': time,
        'participants': participants,
        'lastMessageSenderId': lastMessageSenderId,
        'readBy': readBy,
      };

  factory Chat.fromJson(Map<String, dynamic> json) {
    try {
      return Chat(
        chatId: json['chatId'] ?? '',
        name: json['name'] ?? '',
        lastMessage: json['lastMessage'] ?? '',
        time: json['time'] ?? Timestamp.now(),
        participants: List<String>.from(json['participants'] ?? []),
        lastMessageSenderId: json['lastMessageSenderId'] ?? '',
        readBy: List<String>.from(json['readBy'] ?? []), 
      );
    } catch (e) {
      print("⚠️ Error parsing chat JSON: $e");
      return Chat(
        chatId: '',
        name: '',
        lastMessage: '',
        time: Timestamp.now(),
        participants: [],
        lastMessageSenderId: '',
        readBy: [],
      );
    }
  }
}


