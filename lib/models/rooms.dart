import 'package:cloud_firestore/cloud_firestore.dart';

class Room {
  final String roomId;
  final String callerId;
  final List<String> participants;
  final Map<String, dynamic> werbRtcInfo;

  const Room({
    required this.roomId,
    required this.callerId,
    required this.participants,
    required this.werbRtcInfo,
  });

  Map<String, dynamic> toJson() => {
    'roomId': roomId,
    'callerId': callerId,
    'participants': participants,
    'werbRtcInfo': werbRtcInfo,
  };

  static Room fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    return Room(
      roomId: snapshot['roomId'],
      callerId: snapshot['callerId'],
      participants: List<String>.from(snapshot['participants']),
      werbRtcInfo: snapshot['werbRtcInfo'] ?? {},
    );
  }
}
