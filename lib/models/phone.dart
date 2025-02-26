
class Phone{
  final String phoneId;
  final String phoneNumber;
  final Map<String,dynamic> info;

  const Phone({
    required this.phoneId,
    required this.phoneNumber,
    required this.info,
  });

  Map<String, dynamic> toJson() =>{
    'uid': phoneId,
    'phoneNumber': phoneNumber,
    'info': info,
  };

  }