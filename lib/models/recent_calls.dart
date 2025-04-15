import 'package:cloud_firestore/cloud_firestore.dart';
class RecentCalls {
  String name;
  final String callType;
  final DateTime callTime;
  final bool isMissed;
  final String callerId;
  final String calleeId;

  RecentCalls({
    required this.name,
    required this.callType,
    required this.callTime,
    required this.callerId,
    required this.calleeId,
    this.isMissed = false,
  });

  Map<String, dynamic> toJson() => {
  'name': name,
  'callType': callType,
  'timestamp': Timestamp.fromDate(callTime), 
  'callerId': callerId,
  'calleeId': calleeId,
};

}
