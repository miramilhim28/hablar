import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hablar_clone/models/user.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sanitize the user ID to ensure it does not contain invalid characters
  String sanitizeUserId(String userId) {
    // Ensure the userId doesn't contain slashes or invalid characters
    if (userId.contains('/')) {
      throw Exception('User ID cannot contain slashes');
    }
    return userId;
  }

  // Get user document reference (with sanitized userId)
  DocumentReference<Map<String, dynamic>> getUserRef(String userId) {
    String sanitizedUserId = sanitizeUserId(userId); 
    return _firestore.collection('users').doc(sanitizedUserId);
  }

  // Update WebRTC info
  Future<void> updateWebRTCInfo(String userId, Map<String, dynamic> data) async {
    try {
      await getUserRef(userId).update({
        'werbRtcInfo': data,
      });
    } catch (e) {
      print("Error updating WebRTC info: $e");
      rethrow;
    }
  }

  // Listen for WebRTC updates
  Stream<DocumentSnapshot<Map<String, dynamic>>> listenToWebRTCChanges(String userId) {
    return getUserRef(userId).snapshots();
  }

  // Clear WebRTC info
  Future<void> clearWebRTCInfo(String userId) async {
    try {
      await getUserRef(userId).update({
        'werbRtcInfo': FieldValue.delete(),
      });
    } catch (e) {
      print("Error clearing WebRTC info: $e");
      rethrow;
    }
  }

  // Store WebRTC offer
  Future<void> storeOffer(String remoteUserId, RTCSessionDescription offer, String callerId) async {
    try {
      DocumentReference userRef = getUserRef(remoteUserId);

      await userRef.update({
        'werbRtcInfo': {
          'offerSDP': offer.sdp,
          'callerId': callerId,
          'status': 'initiated',
          'iceCandidates': [],
        },
      });
    } catch (e) {
      print("Error storing WebRTC offer: $e");
      rethrow;
    }
  }

  // Store WebRTC answer
  Future<void> storeAnswer(String remoteUserId, RTCSessionDescription answer) async {
    try {
      DocumentReference userRef = getUserRef(remoteUserId);

      await userRef.update({
        'werbRtcInfo': {
          'answerSDP': answer.sdp,
          'status': 'answered',
        },
      });
    } catch (e) {
      print("Error storing WebRTC answer: $e");
      rethrow;
    }
  }

  // Store ICE candidates
  Future<void> storeIceCandidates(String remoteUserId, List<RTCIceCandidate> candidates) async {
    try {
      DocumentReference userRef = getUserRef(remoteUserId);

      for (RTCIceCandidate candidate in candidates) {
        await userRef.update({
          'werbRtcInfo': {
            'iceCandidates': FieldValue.arrayUnion([{
              'candidate': candidate.candidate,
              'sdpMid': candidate.sdpMid,
              'sdpMLineIndex': candidate.sdpMLineIndex,
            }]),
          },
        });
      }
    } catch (e) {
      print("Error storing ICE candidates: $e");
      rethrow;
    }
  }

  // Fetch a User from Firestore by uid
  Future<User> getUserById(String userId) async {
    try {
      DocumentSnapshot snapshot = await getUserRef(userId).get();
      if (!snapshot.exists) {
        throw Exception("User not found");
      }
      return User.fromSnap(snapshot); 
    } catch (e) {
      print("Error fetching user: $e");
      rethrow;
    }
  }

  // Update user details 
  Future<void> updateUserDetails(String userId, User user) async {
    try {
      await getUserRef(userId).update(user.toJson());
    } catch (e) {
      print("Error updating user details: $e");
      rethrow;
    }
  }

  // Store User
  Future<void> storeUser(User user) async {
    try {
      DocumentReference userRef = getUserRef(user.uid);
      await userRef.set(user.toJson());
    } catch (e) {
      print("Error storing user: $e");
      rethrow;
    }
  }
}
