import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hablar_clone/controllers/call_signalling_controller.dart';
import 'package:hablar_clone/screens/home_screens/call_screens/audio_call_screen.dart';
import 'package:hablar_clone/screens/home_screens/call_screens/video_call_screen.dart';
import 'package:hablar_clone/utils/colors.dart' as utils;
import 'package:audioplayers/audioplayers.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callId;
  final String callerId;
  final String calleeId;
  final String callType;

  IncomingCallScreen({
    required this.callId,
    required this.callerId,
    required this.calleeId,
    required this.callType, required String callerName,
  });

  @override
  _IncomingCallScreenState createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  final CallSignallingController controller = Get.find<CallSignallingController>();
  String callerName = "Fetching...";
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _fetchCallerName(); 
    _playRingtone();
  }

   Future<void> _playRingtone() async {
    try {
      await _audioPlayer.play(AssetSource('audio/ringtone.mp3.m4a'), volume: 1.0);
      _audioPlayer.setReleaseMode(ReleaseMode.loop); // loop the ringtone
      await _audioPlayer.resume(); 
      print("🔔 Ringtone playing...");
    } catch (e) {
      print("❌ Error playing ringtone: $e");
    }
  }

  Future<void> _stopRingtone() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      print("❌ Error stopping ringtone: $e");
    }
  }

  Future<void> _fetchCallerName() async {
    try {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.callerId)
          .get();

      if (userSnapshot.exists) {
        setState(() {
          callerName = userSnapshot['name'] ?? "Unknown Caller"; 
        });
      } else {
        setState(() {
          callerName = "Unknown Caller";
        });
      }
    } catch (e) {
      print("Error fetching caller name: $e");
      setState(() {
        callerName = "Unknown Caller";
      });
    }
  }

  Future<void> _acceptCall() async {
    try {
      DocumentSnapshot callSnapshot = await FirebaseFirestore.instance
          .collection('calls')
          .doc(widget.callId)
          .get();

      if (!callSnapshot.exists) {
        Get.snackbar("Error", "Call not found or already ended.");
        return;
      }

      RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
      await remoteRenderer.initialize();
      await controller.joinRoom(widget.callId, remoteRenderer);

      //SDP Answer
      RTCSessionDescription? answerSDP = await controller.peerConnection?.getLocalDescription();
      if (answerSDP == null) {
        throw Exception("Local SDP answer is null.");
      }

      //Save the answer SDP in firestore
      await FirebaseFirestore.instance.collection('calls').doc(widget.callId).update({
        'answer': {'sdp': answerSDP.sdp, 'type': answerSDP.type},
        'callStatus': 'answered',
      });

      //Navigate to call screen
      if (widget.callType == "video") {
        Get.off(() => VideoCallScreen(
              callerId: widget.callerId,
              calleeId: widget.calleeId,
              callId: widget.callId,
            ));
      } else {
        Get.off(() => AudioCallScreen(
              callerId: widget.callerId,
              calleeId: widget.calleeId,
              callId: widget.callId,
            ));
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to accept call: ${e.toString()}");
    }
  }

  Future<void> _declineCall() async {
    try {
      await FirebaseFirestore.instance.collection('calls').doc(widget.callId).update({
        'callStatus': 'declined',
      });

      controller.hangUp();
      Get.back();
    } catch (e) {
      Get.snackbar("Error", "Failed to decline call: ${e.toString()}");
    }
  }

  @override
  void dispose() {
    _stopRingtone(); 
    _audioPlayer.dispose();
    super.dispose();
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
