import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user document reference
  DocumentReference<Map<String, dynamic>> getUserRef(String userId) {
    return _firestore.collection('users').doc(userId);
  }

  // Update WebRTC info
  Future<void> updateWebRTCInfo(String userId, Map<String, dynamic> data) async {
    await getUserRef(userId).update({'werbRtcInfo': data});
  }

  // Listen for WebRTC updates
  Stream<DocumentSnapshot<Map<String, dynamic>>> listenToWebRTCChanges(String userId) {
    return getUserRef(userId).snapshots();
  }

  // Clear WebRTC info (End Call)
  Future<void> clearWebRTCInfo(String userId) async {
    await getUserRef(userId).update({'werbRtcInfo': {}});
  }
}
