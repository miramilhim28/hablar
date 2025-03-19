import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderId;
  final String text;
  final Timestamp timestamp;
  final String messageType; // text/ image/ audio

  Message({
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.messageType,
  });

  Map<String, dynamic> toJson() => {
        'senderId': senderId,
        'text': text,
        'timestamp': timestamp,
        'messageType': messageType,
      };

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      senderId: json['senderId'],
      text: json['text'],
      timestamp: json['timestamp'],
      messageType: json['messageType'],
    );
  }
}
