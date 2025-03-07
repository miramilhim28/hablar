class Contact {
  final id;
  final String name;
  final String phone;
  final String email;

  const Contact({required this.id, required this.name, required this.phone, required this.email});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'phone': phone, email: 'email'};

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
    );
  }
}
