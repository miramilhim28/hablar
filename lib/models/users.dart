import 'package:flutter/material.dart';
import 'package:hablar/models/calls.dart';

class User{
  final String name;
  final String phoneNumber;
  final String photoUrl;
  final String bio;
  final String uid;
  final List<String> contacts;
  final List<String> history;
  final List<String> favorites;

  const User({
    required this.name,
    required this.phoneNumber,
    required this.photoUrl,
    required this.bio,
    required this.uid,
    required this.contacts,
    required this.history,
    required this.favorites,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'phoneNumber': phoneNumber,
    'photoUrl': photoUrl,
    'bio': bio,
    'uid': uid,
    'contacts': contacts,
    'history': history,
    'favorites': favorites,
  };

}