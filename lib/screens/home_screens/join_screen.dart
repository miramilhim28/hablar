import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hablar_clone/controllers/call_signalling_controller.dart';
import 'package:hablar_clone/utils/colors.dart' as utils;
import 'package:hablar_clone/screens/home_screens/audio_call_screen.dart';
import 'package:hablar_clone/screens/home_screens/video_call_screen.dart';
import 'package:hablar_clone/services/firestore_service.dart';

class JoinScreen extends StatefulWidget {
  final String callerId;
  final String calleeId;
  final String callType;

  JoinScreen({
    super.key,
    required this.callerId,
    required this.calleeId,
    required this.callType,
  });

  @override
  _JoinScreenState createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final CallSignallingController callController = Get.put(CallSignallingController());
  final FirestoreService _firestoreService = FirestoreService();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _startCall(); // Auto-start call when screen opens
  }

  /// **Start a Call (Caller)**
  Future<void> _startCall() async {
  setState(() {
    isLoading = true;
  });

  try {
    // ✅ Create WebRTC Room and Offer
    String roomId = await callController.createRoom(RTCVideoRenderer());
    print("📞 Room Created: $roomId");

    // ✅ Wait for Local SDP Offer to be Set
    await Future.delayed(Duration(seconds: 1));  // Ensure SDP is set properly

    RTCSessionDescription? offerSDP = await callController.peerConnection?.getLocalDescription();

    if (offerSDP == null) {
      throw Exception("Local SDP offer is null.");
    }

    // ✅ Store Call Data in Firestore
    await _firestoreService.storeOffer(
      widget.calleeId,
      offerSDP,  // Store the actual offer retrieved
      widget.callerId,
    );

    // ✅ Listen for Answer from Callee
    _listenForAnswer(roomId);
  } catch (e) {
    Get.snackbar("Error", "Failed to start call: $e");
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}


  /// **Listen for SDP Answer**
  void _listenForAnswer(String roomId) {
    FirebaseFirestore.instance.collection('rooms').doc(roomId).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        var roomData = snapshot.data() as Map<String, dynamic>;

        if (roomData.containsKey('answer')) {
          print("✅ Call Answered! Navigating...");

          // Navigate to correct call screen
          if (widget.callType == "video") {
            Get.off(() => VideoCallScreen(
                  callerId: widget.callerId,
                  calleeId: widget.calleeId,
                  callId: roomId,
                ));
          } else {
            Get.off(() => AudioCallScreen(
                  callerId: widget.callerId,
                  calleeId: widget.calleeId,
                  callId: roomId,
                ));
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [utils.purpleLilac, utils.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: isLoading
                ? CircularProgressIndicator(color: utils.darkPurple)
                : Text(
                    "Waiting for Answer...",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: utils.darkGrey,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
