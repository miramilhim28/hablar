
class RecentCalls{
  final String name;
  final String callType;
  final String callTime;
  final bool isMissed;


  const RecentCalls({
    required this.name,
    required this.callType,
    required this.callTime,
    this.isMissed = false,
  });

   Map<String, dynamic> toJson() => {
    'name': name,    
    'callType': callType,
    'callTime': callTime
  };
}