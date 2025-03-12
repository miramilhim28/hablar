class Contact {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String bio;
  bool isFavorite;

  Contact({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.bio,
    this.isFavorite = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'email': email,
    'bio': bio,
    'isFavorite': isFavorite,
  };

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      bio: json['bio'] ?? '',
      isFavorite: json['isFavorite'] ?? false,
    );
  }
}
