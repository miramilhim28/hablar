class Contact {
  final id;
  final String name;
  final String phone;

  const Contact({required this.id, required this.name, required this.phone});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'phone': phone};

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'],
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}
