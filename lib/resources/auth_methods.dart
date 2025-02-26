import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:hablar_clone/models/users.dart' as model;

class AuthMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future <model.User> getUserDetails() async{
    User currentUser = _auth.currentUser!;

    DocumentSnapshot snap =
        await _firestore.collection('users').doc(currentUser.uid).get();
        
        return model.User.fromSnap(snap);
  }

  //signup user:
  Future <String> signUpUser({
    required String name,
    required String email,
    required String password,
  }) async{
    String res = "Some error occured";
    try {
      if(name.isNotEmpty || email.isNotEmpty || password.isNotEmpty){
        //register user:
        UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
  
        //add user to the database:
        model.User user = model.User(
          name: name,
          email: email,
          photoUrl: '',
          password: password,
          phone: '',
          uid: '',
          bio: '',
          history: [],
          favorites: [],
          contacts: [],
        );

          await _firestore.collection('users').doc(cred.user!.uid).set(user.toJson(),);
          
          res = "success";
        res = "Success";
      }
    }
    catch (err){
      res = err.toString();
    }

    return res;
  }


  //Login User
  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    String res = "Some error occured";

    try {
      if (email.isNotEmpty || password.isNotEmpty) {
        await _auth.signInWithEmailAndPassword(
            email: email, password: password);
        res = 'success';
      } else {
        res = "Please enter both email and password";
      }
    } catch (err) {
      res = err.toString();
    }
    return res;
  }
}