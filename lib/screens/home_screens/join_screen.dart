import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hablar_clone/controllers/call_signalling_controller.dart';
import 'package:hablar_clone/utils/colors.dart' as utils;
import 'package:hablar_clone/screens/home_screens/audio_call_screen.dart';
import 'package:hablar_clone/screens/home_screens/video_call_screen.dart';

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
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _startCall();
  }

  Future<void> _startCall() async {
  setState(() {
    isLoading = true;
  });

  try {
    String roomId = await callController.createRoom();
    print("Room Created: $roomId");

    await Future.delayed(Duration(seconds: 1));

    RTCSessionDescription? offerSDP = await callController.peerConnection?.getLocalDescription();

    if (offerSDP == null) {
      throw Exception("Local SDP offer is null.");
    }

    await FirebaseFirestore.instance.collection('calls').doc(roomId).set({
      'callId': roomId,
      'callerId': widget.callerId,
      'calleeId': widget.calleeId,
      'callType': widget.callType,
      'callStatus': 'calling',
      'offer': {'sdp': offerSDP.sdp, 'type': offerSDP.type},
      'timestamp': FieldValue.serverTimestamp(),
    });

    _listenForAnswer(roomId);
  } catch (e) {
    Get.snackbar("Error", "Failed to start call: $e");
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}



  void _listenForAnswer(String roomId) {
    FirebaseFirestore.instance.collection('rooms').doc(roomId).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        var roomData = snapshot.data() as Map<String, dynamic>;

        if (roomData.containsKey('answer')) {
          print("Call Answered! Navigating...");

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
