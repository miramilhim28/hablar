import 'package:hablar_clone/models/rooms.dart';
class Call {
  final String callId;
  final String calleeId;
  final String callerId;
  final String phoneNumber;
  final String callType;
  final String callStatus;
  final DateTime callTime;
  final Room room;

  const Call({
    required this.callId,
    required this.calleeId,
    required this.callerId,
    required this.phoneNumber,
    required this.callType,
    required this.callStatus,
    required this.callTime,
    required this.room, 
  });

  Map<String, dynamic> toJson() => {
        'callId': callId,
        'calleeId': calleeId,
        'callerId': callerId,
        'phoneNumber': phoneNumber,
        'callType': callType,
        'callStatus': callStatus,
        'callTime': callTime.toIso8601String(),
        'room': room.toJson(),
      };

  factory Call.fromJson(Map<String, dynamic> json) {
    return Call(
      callId: json['callId'],
      calleeId: json['calleeId'],
      callerId: json['callerId'],
      phoneNumber: json['phoneNumber'],
      callType: json['callType'],
      callStatus: json['callStatus'],
      callTime: DateTime.parse(json['callTime']),
      room: Room.fromJson(json['room']),
    );
  }
}
