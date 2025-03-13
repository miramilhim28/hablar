import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:get/get.dart';
import 'package:hablar_clone/controllers/call_signalling_controller.dart';
import 'package:hablar_clone/utils/colors.dart' as utils;

class AudioCallScreen extends StatefulWidget {
  final String callerId, calleeId;
  final String callId;
  final dynamic offer;

  const AudioCallScreen({
    super.key,
    required this.callId,
    required this.callerId,
    required this.calleeId,
    this.offer,
  });

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  final CallSignallingController _callController = Get.put(CallSignallingController());
  bool isAudioOn = true;
  bool isCallEnded = false;
  bool isAnswered = false;
  int callDurationInSeconds = 0;
  String calleeName = "Unknown";

  @override
  void initState() {
    super.initState();
    _initializeAudioCall();
    _fetchCalleeName();
    _listenForCallStatus();
  }

  /// **Initialize Audio Call (WebRTC & Media)**
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

    // ✅ Ensure `offer` exists before using it
    if (widget.offer != null && widget.callId.isNotEmpty) {
      await _callController.joinRoom(widget.callId, webrtc.RTCVideoRenderer());
    }
  } catch (e) {
    print("Error initializing audio call: $e");
  }
}

  /// **Fetch Callee Name from Firestore**
  Future<void> _fetchCalleeName() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.calleeId)
          .get();

      if (snapshot.exists && snapshot.data() != null) {
        setState(() {
          calleeName = snapshot['name'] ?? 'Unknown';
        });
      }
    } catch (e) {
      print('Error fetching callee name: $e');
    }
  }

  /// **Listen for Call Status Updates from Firestore**
  void _listenForCallStatus() {
    FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.callId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        String status = snapshot['callStatus'] ?? 'calling';
        print("CALL STATUS: $status");

        if (status == 'answered' && !isAnswered) {
          setState(() {
            isAnswered = true;
          });
          print("Call was answered! Timer should start now.");
          _startCallTimer();
        }

        if (status == 'ended' && !isCallEnded) {
          _endCall();
        }
      }
    });
  }

  /// **Start Call Timer when Answered**
  void _startCallTimer() {
    if (!isCallEnded) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && !isCallEnded) {
          setState(() {
            callDurationInSeconds += 1;
          });
          _startCallTimer();
        }
      });
    }
  }

  /// **End Call**
  Future<void> _endCall() async {
    if (!isCallEnded) {
      setState(() {
        isCallEnded = true;
      });

      await _callController.hangUp();
      Get.back();
    }
  }

  @override
  void dispose() {
    _callController.localStream?.dispose();
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
              // Profile Picture & Caller Info
              CircleAvatar(
                radius: 70,
                backgroundColor: utils.white,
                child: Icon(
                  Icons.person,
                  size: 80,
                  color: utils.darkPurple,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                calleeName,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: utils.white,
                ),
              ),
              const SizedBox(height: 10),

              Text(
                isAnswered ? "In Call" : "Calling...",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  color: utils.darkPurple,
                ),
              ),
              const SizedBox(height: 30),

              if (isAnswered)
                Text(
                  "${(callDurationInSeconds ~/ 60).toString().padLeft(2, '0')}:" +
                  "${(callDurationInSeconds % 60).toString().padLeft(2, '0')}",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: utils.darkGrey,
                  ),
                ),
              const SizedBox(height: 40),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Mute/Unmute Button
                  IconButton(
                    icon: Icon(
                      isAudioOn ? Icons.mic : Icons.mic_off,
                      color: isAudioOn ? Colors.green : Colors.red,
                      size: 40,
                    ),
                    onPressed: () {
                      setState(() {
                        isAudioOn = !isAudioOn;
                        _callController.localStream?.getAudioTracks().first.enabled =
                            isAudioOn;
                      });
                    },
                  ),
                  const SizedBox(width: 40),

                  // End Call Button
                  IconButton(
                    icon: Icon(
                      Icons.call_end,
                      color: Colors.red,
                      size: 40,
                    ),
                    onPressed: _endCall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
