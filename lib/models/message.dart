import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderId;
  final String text;
  final Timestamp timestamp;
  final String messageType;
  final List<String> deliveredTo;
  final List<String> readBy;
  final String id;

  Message({
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.messageType,
    required this.deliveredTo,
    required this.readBy,
    required this.id,
  });

  Map<String, dynamic> toJson() => {
    'senderId': senderId,
    'text': text,
    'timestamp': timestamp,
    'messageType': messageType,
    'deliveredTo': deliveredTo,
    'readBy': readBy,
  };

  factory Message.fromJson(Map<String, dynamic> json, String docId) {
    return Message(
      senderId: json['senderId'],
      text: json['text'],
      timestamp: json['timestamp'],
      messageType: json['messageType'],
      deliveredTo: List<String>.from(json['deliveredTo'] ?? []),
      readBy: List<String>.from(json['readBy'] ?? []),
      id: docId,
    );
  }
}
