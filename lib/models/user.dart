import 'package:cloud_firestore/cloud_firestore.dart';
import 'contact.dart';
import 'calls.dart';

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
  final List<String> calls;
  final List<String> favorites;
  final String? roomId;

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
    required this.calls,
    required this.favorites,
    this.roomId,
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
    'calls': calls,
    'favorites': favorites,
    'roomId': roomId,
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
      calls: List<String>.from(snapshot['calls']),
      favorites: List<String>.from(snapshot['favorites']),
      roomId: snapshot['roomId'],
    );
  }
}


