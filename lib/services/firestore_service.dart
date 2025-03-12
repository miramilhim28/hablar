import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user document reference
  DocumentReference<Map<String, dynamic>> getUserRef(String userId) {
    return _firestore.collection('users').doc(userId);
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

  // Clear WebRTC info (End Call)
  Future<void> clearWebRTCInfo(String userId) async {
    try {
      await getUserRef(userId).update({
        'werbRtcInfo': FieldValue.delete(),  // Deletes 'werbRtcInfo' field from Firestore
      });
    } catch (e) {
      print("Error clearing WebRTC info: $e");
      rethrow;
    }
  }

  // Store WebRTC offer (create room)
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

  // Clear the room data when the call ends
  Future<void> clearRoomData(String roomId) async {
    try {
      DocumentReference roomRef = _firestore.collection('rooms').doc(roomId);
      
      // Clear ICE candidates and offer/answer
      await roomRef.update({
        'werbRtcInfo': FieldValue.delete(),
      });

      // Optionally delete the room if needed
      await roomRef.delete();
    } catch (e) {
      print("Error clearing room data: $e");
      rethrow;
    }
  }
}
