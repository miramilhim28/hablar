import 'package:cloud_firestore/cloud_firestore.dart';
import 'contact.dart';

class User {
  final String name;
  final String email;
  final String photoUrl;
  final String bio;
  final String password;
  final String phone;
  final String uid;
  final Map<String, dynamic> werbRtcInfo;
  final List<Contact> contacts;
  final List<String> history;
  final List<String> favorites;

  const User({
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.bio,
    required this.password,
    required this.phone,
    required this.uid,
    required this.werbRtcInfo,
    required this.contacts,
    required this.history,
    required this.favorites,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'photoUrl': photoUrl,
    'bio': bio,
    'password': password,
    'phone': phone,
    'uid': uid,
    'werbRtcInfo': werbRtcInfo,
    'contacts': contacts.map((contact) => contact.toJson()).toList(),
    'history': history,
    'favorites': favorites,
  };

  static User fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    List<Contact> contactList =
        (snapshot['contacts'] as List)
            .map((contactData) => Contact.fromJson(contactData))
            .toList();

    return User(
      name: snapshot['name'],
      email: snapshot['email'],
      photoUrl: snapshot['photoUrl'],
      bio: snapshot['bio'],
      password: snapshot['password'],
      phone: snapshot['phone'],
      uid: snapshot['uid'],
      werbRtcInfo: snapshot['werbRtcInfo'] ?? {},
      contacts: contactList,
      history: List<String>.from(snapshot['history']),
      favorites: List<String>.from(snapshot['favorites']),
    );
  }
}
