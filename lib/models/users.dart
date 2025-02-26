import 'package:cloud_firestore/cloud_firestore.dart';

class User{
  final String name;
  final String email;
  final String photoUrl;
  final String bio;
  final String uid;
  final List<String> contacts;
  final List<String> history;
  final List<String> favorites;

  const User({
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.bio,
    required this.uid,
    required this.contacts,
    required this.history,
    required this.favorites,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'photoUrl': photoUrl,
    'bio': bio,
    'uid': uid,
    'contacts': contacts,
    'history': history,
    'favorites': favorites,
  };

  static User fromSnap(DocumentSnapshot snap){
    var snapshot = snap.data() as Map<String, dynamic>;

    return User(
      name: snapshot['name'],
      email: snapshot['email'],
      photoUrl: snapshot['photoUrl'],
      bio: snapshot['bio'],
      uid: snapshot['uid'],
      contacts: snapshot['contacts'],
      history: snapshot['history'],
      favorites: snapshot['favorites'],
    );
  }

}