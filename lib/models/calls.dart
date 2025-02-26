
class Call{
  final String callId;
  final String recId;
  final String callerId;
  final String phoneNumber;
  final String callType;
  final List<String> callStatus;
  final DateTime callTime;


  const Call({
    required this.callId,
    required this.recId,
    required this.callerId,
    required this.phoneNumber,
    required this.callType,
    required this.callStatus,
    required this.callTime,
  });

   Map<String, dynamic> toJson() => {
    'name': callId,
    'recId': recId,
    'callerId': callerId,
    'phoneNumber': phoneNumber,
    'callType': callType,
    'callStatus': callStatus,
    'callTime': callTime
  };
}