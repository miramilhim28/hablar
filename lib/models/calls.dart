class Call {
  final String callId;
  final String calleeId;
  final String callerId;
  final String phoneNumber;
  final String callType;
  final String callStatus;
  final DateTime callTime;
  final String roomId;
  final Map<String, dynamic> werbRtcInfo;

  const Call({
    required this.callId,
    required this.calleeId,
    required this.callerId,
    required this.phoneNumber,
    required this.callType,
    required this.callStatus,
    required this.callTime,
    required this.roomId,
    required this.werbRtcInfo,
  });

  Map<String, dynamic> toJson() => {
        'callId': callId,
        'calleeId': calleeId,
        'callerId': callerId,
        'phoneNumber': phoneNumber,
        'callType': callType,
        'callStatus': callStatus,
        'callTime': callTime.toIso8601String(),
        'roomId': roomId,
        'werbRtcInfo': werbRtcInfo,
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
      roomId: json['roomId'],
      werbRtcInfo: json['werbRtcInfo'],
    );
  }
}
