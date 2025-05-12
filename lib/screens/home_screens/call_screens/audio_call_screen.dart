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
  final CallSignallingController _callController = Get.find();
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

  Future<void> _initializeAudioCall() async {
    try {
      await _callController.openUserMedia(video: false);
      _callController.localStream?.getAudioTracks().forEach((track) {
        track.enabled = true;
        print("🎙 Local Audio Enabled: \${track.label}");
      });

      await _callController.joinRoom(widget.callId, webrtc.RTCVideoRenderer());
    } catch (e) {
      print("❌ Error initializing audio call: \$e");
    }
  }

  void _listenForCallStatus() {
    FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.callId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;

      String status = snapshot['callStatus'] ?? 'calling';
      print("CALL STATUS: \$status");

      if (status == 'answered') {
        _timeoutTimer?.cancel();
        setState(() {
          isCallEnded = false;
          isAudioOn = true;
        });

        _callController.localStream?.getAudioTracks().forEach((track) {
          track.enabled = true;
          print("🎙 Local Audio Re-enabled: \${track.id}");
        });

        _callController.remoteStream.value?.getAudioTracks().forEach((track) {
          track.enabled = true;
          print("🔊 Remote Audio Track: ID=\${track.id}, ENABLED=\${track.enabled}, MUTED=\${track.muted}");
        });
      }

      if ((status == 'ended' || status == 'missed') && !isCallEnded) {
        _endCall();
      }
    });
  }

  void _startCallTimeout() {
    _timeoutTimer = Timer(const Duration(seconds: 15), () async {
      DocumentSnapshot callSnapshot = await FirebaseFirestore.instance
          .collection('calls')
          .doc(widget.callId)
          .get();

      if (callSnapshot.exists && (callSnapshot['callStatus'] ?? 'calling') == 'calling') {
        await FirebaseFirestore.instance
            .collection('calls')
            .doc(widget.callId)
            .update({'callStatus': 'missed'});
      }
    });
  }

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
    _callController.localStream?.dispose();
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      isAudioOn ? Icons.mic : Icons.mic_off,
                      color: isAudioOn ? Colors.green : Colors.red,
                      size: 50,
                    ),
                    onPressed: () {
                      setState(() => isAudioOn = !isAudioOn);
                      _callController.localStream?.getAudioTracks().forEach(
                        (track) => track.enabled = isAudioOn,
                      );
                    },
                  ),
                  const SizedBox(width: 40),
                  IconButton(
                    icon: const Icon(Icons.call_end, color: Colors.red, size: 50),
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