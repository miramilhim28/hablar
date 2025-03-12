import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hablar_clone/controllers/call_signalling_controller.dart';
import 'package:hablar_clone/screens/home_screens/audio_call_screen.dart';
import 'package:hablar_clone/utils/colors.dart' as utils;

class IncomingCallScreen extends StatelessWidget {
  final String callId;
  final String callerId;
  final String calleeId;
  final String callerName;

  IncomingCallScreen({
    required this.callId,
    required this.callerId,
    required this.calleeId,
    required this.callerName,
  });

  final CallSignallingController controller = Get.find<CallSignallingController>();

  // Accept the incoming call
  Future<void> _acceptCall() async {
    try {
      // Fetch the call details from Firestore
      DocumentSnapshot callSnapshot = await FirebaseFirestore.instance.collection('users').doc(calleeId).get();

      if (!callSnapshot.exists) {
        Get.snackbar("Error", "Call not found or already ended.");
        return;
      }

      Map<String, dynamic>? callData = callSnapshot.data() as Map<String, dynamic>?;

      if (callData == null || !callData.containsKey('werbRtcInfo') || !callData['werbRtcInfo'].containsKey('offerSDP')) {
        Get.snackbar("Error", "Invalid call data.");
        return;
      }

      // Accept the call by passing offer SDP and ICE candidates
      await controller.createAnswer(
        callData['werbRtcInfo']['offerSDP'],
        callData['werbRtcInfo']['iceCandidates'],
      );

      // Navigate to the audio call screen with the retrieved offer
      Get.off(() => AudioCallScreen(
        callerId: callerId,
        calleeId: calleeId,
        offer: callData['werbRtcInfo']['offerSDP'],
      ));
    } catch (e) {
      Get.snackbar("Error", "Failed to accept call: ${e.toString()}");
    }
  }

  // Decline the incoming call
  Future<void> _declineCall() async {
    try {
      controller.endCall();
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
                // Accept Call Button
                IconButton(
                  icon: const Icon(Icons.call, color: Colors.green, size: 50),
                  onPressed: _acceptCall,
                ),
                const SizedBox(width: 50),
                // Decline Call Button
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
