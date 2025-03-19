import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String chatId;
  final String name;
  final String lastMessage;
  final Timestamp time;
  final List<String> participants;

  Chat({
    required this.chatId,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.participants,
  });

  Map<String, dynamic> toJson() => {
        'chatId': chatId,
        'name': name,
        'lastMessage': lastMessage,
        'time': time,
        'participants': participants,
      };

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      chatId: json['chatId'],
      name: json['name'],
      lastMessage: json['lastMessage'],
      time: json['time'],
      participants: List<String>.from(json['participants']),
    );
  }
}
