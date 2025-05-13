import 'package:cloud_firestore/cloud_firestore.dart';
import 'contact.dart';
import 'calls.dart';

class User {
  final String name;
  final String email;
  final String bio;
  final String password;
  final String phone;
  final String uid;
  final Map<String, dynamic> werbRtcInfo;
  final List<Contact> contacts;
  final List<Call> calls;
  final List<String> favorites;

  const User({
    required this.name,
    required this.email,
    required this.bio,
    required this.password,
    required this.phone,
    required this.uid,
    required this.werbRtcInfo,
    required this.contacts,
    required this.calls,
    required this.favorites,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'bio': bio,
        'password': password,
        'phone': phone,
        'uid': uid,
        'werbRtcInfo': werbRtcInfo,
        'contacts': contacts.map((contact) => contact.toJson()).toList(),
        'calls': calls.map((call) => call.toJson()).toList(),
        'favorites': favorites,
      };

  static User fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    List<Contact> contactList = [];
    if (snapshot['contacts'] != null && snapshot['contacts'] is List) {
      contactList = (snapshot['contacts'] as List)
          .map((contactData) => Contact.fromJson(contactData))
          .toList();
    }

    List<Call> callList = [];
    if (snapshot['calls'] != null && snapshot['calls'] is List) {
      callList = (snapshot['calls'] as List)
          .map((callData) => Call.fromJson(callData))
          .toList();
    }

    return User(
      name: snapshot['name'] is String ? snapshot['name'] : '',
      email: snapshot['email'] is String ? snapshot['email'] : '',
      bio: snapshot['bio'] is String ? snapshot['bio'] : '',
      password: snapshot['password'] is String ? snapshot['password'] : '',
      phone: snapshot['phone'] is String ? snapshot['phone'] : '',
      uid: snapshot['uid'] is String ? snapshot['uid'] : '',
      werbRtcInfo: snapshot['werbRtcInfo'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(snapshot['werbRtcInfo'])
          : {},
      contacts: contactList,
      calls: callList,
      favorites: snapshot['favorites'] is List
          ? List<String>.from(snapshot['favorites'])
          : [],
    );
  }
}
