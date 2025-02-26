
class Chat{
  final String name;
  final String time;

  const Chat({
    required this.name,
    required this.time,
  });

  Map<String, dynamic> toJson() =>{
    'name': name,
    'time': time,
  };

  }