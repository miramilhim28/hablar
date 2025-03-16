import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:get/get.dart';
import 'package:hablar_clone/controllers/call_signalling_controller.dart';
import 'package:hablar_clone/utils/colors.dart' as utils;

class AudioCallScreen extends StatefulWidget {
  final String callerId, calleeId;
  final String callId;

  const AudioCallScreen({
    super.key,
    required this.callId,
    required this.callerId,
    required this.calleeId,
  });

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  final CallSignallingController _callController = Get.put(CallSignallingController());
  bool isAudioOn = true;
  bool isCallEnded = false;

  @override
  void initState() {
    super.initState();
    _initializeAudioCall();
    String? userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId != null) {
    CallSignallingController callController = Get.put(CallSignallingController());
    callController.listenForIncomingCalls();
  }
  }

  Future<void> _initializeAudioCall() async {
    try {
      await _callController.initializePeerConnection();
      _callController.localStream =
          await webrtc.navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});

      if (_callController.localStream != null) {
        _callController.localStream!.getTracks().forEach((track) {
          _callController.peerConnection?.addTrack(track, _callController.localStream!);
        });
      }

      await _callController.joinRoom(widget.callId);
    } catch (e) {
      print("Error initializing audio call: $e");
    }
  }

  @override
  void dispose() {
    _callController.hangUp();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [utils.purpleLilac, utils.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "In Call...",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: utils.white,
                ),
              ),
              const SizedBox(height: 40),
              IconButton(
                icon: Icon(
                  Icons.call_end,
                  color: Colors.red,
                  size: 50,
                ),
                onPressed: () async {
                  await _callController.hangUp();
                  Get.back();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
