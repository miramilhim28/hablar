import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:get/get.dart';
import 'package:hablar_clone/controllers/call_signalling_controller.dart';
import 'package:hablar_clone/utils/colors.dart' as utils;
import 'dart:async';

class AudioCallScreen extends StatefulWidget {
  final String callerId;
  final String calleeId;
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
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _initializeAudioCall();
    _listenForCallStatus();
    _startCallTimeout();
  }

  //initialize WebRTC sudio call
  Future<void> _initializeAudioCall() async {
    try {
      await _callController.initializePeerConnection();

      _callController.localStream = await webrtc.navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });

      if (_callController.localStream != null) {
        _callController.localStream!.getTracks().forEach((track) {
          _callController.peerConnection?.addTrack(track, _callController.localStream!);
        });
      }

      //initialize remote renderer
      webrtc.RTCVideoRenderer remoteRenderer = webrtc.RTCVideoRenderer();
      await remoteRenderer.initialize();

      //join the WebRTC room
      await _callController.joinRoom(widget.callId, remoteRenderer);
    } catch (e) {
      print("Error initializing audio call: $e");
    }
  }

  //Listen for call status updates from firestore
  void _listenForCallStatus() {
    FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.callId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        String status = snapshot['callStatus'] ?? 'calling';
        print("CALL STATUS: $status");

        //if answered cancel timeout timer
        if (status == 'answered') {
          _timeoutTimer?.cancel();
          setState(() {
            isCallEnded = false;
          });
        }

        //if ended or missed close call screen
        if ((status == 'ended' || status == 'missed') && !isCallEnded) {
          _endCall();
        }
      }
    });
  }

  //Missed call
  void _startCallTimeout() {
    _timeoutTimer = Timer(const Duration(seconds: 30), () async {
      DocumentSnapshot callSnapshot = await FirebaseFirestore.instance
          .collection('calls')
          .doc(widget.callId)
          .get();

      if (callSnapshot.exists) {
        String status = callSnapshot['callStatus'] ?? 'calling';

        // If still calling after 30 sec, mark as missed
        if (status == 'calling') {
          await FirebaseFirestore.instance.collection('calls').doc(widget.callId).update({
            'callStatus': 'missed',
          });
        }
      }
    });
  }

  //End the call and close the call screen
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
    _timeoutTimer?.cancel();
    _callController.hangUp();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
              // Call Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Mute/Unmute Button
                  IconButton(
                    icon: Icon(
                      isAudioOn ? Icons.mic : Icons.mic_off,
                      color: isAudioOn ? Colors.green : Colors.red,
                      size: 50,
                    ),
                    onPressed: () {
                      setState(() {
                        isAudioOn = !isAudioOn;
                        _callController.localStream?.getAudioTracks().first.enabled = isAudioOn;
                      });
                    },
                  ),
                  const SizedBox(width: 40),

                  // End Call Button
                  IconButton(
                    icon: Icon(
                      Icons.call_end,
                      color: Colors.red,
                      size: 50,
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
