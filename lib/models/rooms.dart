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

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      roomId: json['roomId'],
      callerId: json['callerId'],
      participants: List<String>.from(json['participants']),
      werbRtcInfo: json['werbRtcInfo'] ?? {},
    );
  }
}
