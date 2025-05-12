import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:hablar_clone/controllers/call_signalling_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hablar_clone/utils/colors.dart' as utils;
import 'dart:async';

class VideoCallScreen extends StatefulWidget {
  final String callerId;
  final String calleeId;
  final String callId;
  final dynamic offer;

  const VideoCallScreen({
    super.key,
    required this.callId,
    required this.callerId,
    required this.calleeId,
    this.offer,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final CallSignallingController _callController = Get.find();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool isAudioOn = true;
  bool isVideoOn = true;
  bool isCallEnded = false;
  bool isAnswered = false;
  int callDurationInSeconds = 0;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _initializeVideoCall();
    _listenForCallStatus();
    _startCallTimeout();
  }

  Future<void> _initializeVideoCall() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    await _callController.joinRoom(widget.callId, _remoteRenderer);

    _callController.localStream = await webrtc.navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {
        'facingMode': 'user',
        'width': {'ideal': 1280},
        'height': {'ideal': 720},
      },
    });

    _localRenderer.srcObject = _callController.localStream;
  }

  void _listenForCallStatus() {
    FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.callId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;

      String status = snapshot['callStatus'] ?? 'calling';

      if (status == 'answered' && !isAnswered) {
        _timeoutTimer?.cancel();
        setState(() => isAnswered = true);
        _startCallTimer();
      }

      if (_callController.remoteStream.value != null) {
        _remoteRenderer.srcObject = null;
        _remoteRenderer.srcObject = _callController.remoteStream.value;

        _callController.remoteStream.value?.getTracks().forEach((track) {
          track.enabled = true;
        });

        _callController.remoteStream.value?.getAudioTracks().forEach((track) {
          track.enabled = true;
          print("🔊 Remote Audio Track: ID=${track.id}, ENABLED=${track.enabled}, MUTED=${track.muted}");
        });

        _callController.remoteStream.value?.getVideoTracks().forEach((track) {
          track.enabled = true;
          print("🎥 Remote Video Track: ID=${track.id}, ENABLED=${track.enabled}");
        });
      }

      if ((status == 'ended' || status == 'missed') && !isCallEnded) {
        _endCall();
      }
    });
  }

  void _startCallTimer() {
    if (!isCallEnded) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && !isCallEnded) {
          setState(() => callDurationInSeconds++);
          _startCallTimer();
        }
      });
    }
  }

  void _startCallTimeout() {
    _timeoutTimer = Timer(const Duration(seconds: 15), () async {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('calls')
          .doc(widget.callId)
          .get();

      if (snapshot.exists && (snapshot['callStatus'] ?? 'calling') == 'calling') {
        await FirebaseFirestore.instance
            .collection('calls')
            .doc(widget.callId)
            .update({'callStatus': 'missed'});
      }
    });
  }

  Future<void> _endCall() async {
    if (!isCallEnded) {
      setState(() => isCallEnded = true);
      await _callController.hangUp();
      Get.back();
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
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
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.black,
                      child: RTCVideoView(
                        _remoteRenderer,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
                    ),
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Container(
                        width: 120,
                        height: 160,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: RTCVideoView(
                          _localRenderer,
                          mirror: true,
                          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 40,
                      child: Text(
                        isAnswered ? "In Call" : "Calling...",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          color: utils.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                color: Colors.black,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                        isAudioOn ? Icons.mic : Icons.mic_off,
                        color: isAudioOn ? Colors.green : Colors.red,
                        size: 40,
                      ),
                      onPressed: () {
                        setState(() => isAudioOn = !isAudioOn);
                        _callController.localStream?.getAudioTracks().forEach(
                          (track) => track.enabled = isAudioOn,
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        isVideoOn ? Icons.videocam : Icons.videocam_off,
                        color: isVideoOn ? Colors.green : Colors.red,
                        size: 40,
                      ),
                      onPressed: () {
                        setState(() => isVideoOn = !isVideoOn);
                        _callController.localStream?.getVideoTracks().forEach(
                          (track) => track.enabled = isVideoOn,
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.call_end, color: Colors.red, size: 40),
                      onPressed: _endCall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
