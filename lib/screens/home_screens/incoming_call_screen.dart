import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hablar_clone/controllers/call_signalling_controller.dart';
import 'package:hablar_clone/screens/home_screens/audio_call_screen.dart';
import 'package:hablar_clone/screens/home_screens/video_call_screen.dart';
import 'package:hablar_clone/utils/colors.dart' as utils;

class IncomingCallScreen extends StatelessWidget {
  final String callId;
  final String callerId;
  final String calleeId;
  final String callerName;
  final String callType;

  IncomingCallScreen({
    required this.callId,
    required this.callerId,
    required this.calleeId,
    required this.callerName,
    required this.callType,
  });

  final CallSignallingController controller = Get.find<CallSignallingController>();

  //Accept the Incoming Call
  Future<void> _acceptCall() async {
    try {
      //Fetch the Room associated with this Call
      DocumentSnapshot roomSnapshot = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(callId)
          .get();

      if (!roomSnapshot.exists) {
        Get.snackbar("Error", "Call room not found or already ended.");
        return;
      }

      var roomData = roomSnapshot.data() as Map<String, dynamic>?;

      if (roomData == null || !roomData.containsKey('werbRtcInfo')) {
        Get.snackbar("Error", "Invalid room data.");
        return;
      }

      //Join the WebRTC session (Handles SDP Answer)
      await controller.joinRoom(callId, RTCVideoRenderer());

      // ✅ Update Firestore to mark call as `answered`
      await FirebaseFirestore.instance.collection('rooms').doc(callId).update({
        'werbRtcInfo.callStatus': 'answered',
      });

      //Navigate to the correct call screen based on `callType`
      if (callType == "video") {
        Get.off(() => VideoCallScreen(
              callerId: callerId,
              calleeId: calleeId,
              callId: callId,
            ));
      } else {
        Get.off(() => AudioCallScreen(
              callerId: callerId,
              calleeId: calleeId,
              callId: callId,
            ));
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to accept call: ${e.toString()}");
    }
  }

  //Decline the Incoming Call
  Future<void> _declineCall() async {
    try {
      //Update Firestore to mark the call as `declined`
      await FirebaseFirestore.instance.collection('rooms').doc(callId).update({
        'werbRtcInfo.callStatus': 'declined',
      });

      //End WebRTC session and close screen
      controller.hangUp();
      Get.back();
    } catch (e) {
      Get.snackbar("Error", "Failed to decline call: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: utils.darkPurple,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Incoming Call from",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              callerName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 100),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //Accept Call Button
                IconButton(
                  icon: const Icon(Icons.call, color: Colors.green, size: 50),
                  onPressed: _acceptCall,
                ),
                const SizedBox(width: 50),
                //Decline Call Button
                IconButton(
                  icon: const Icon(Icons.call_end, color: Colors.red, size: 50),
                  onPressed: _declineCall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
