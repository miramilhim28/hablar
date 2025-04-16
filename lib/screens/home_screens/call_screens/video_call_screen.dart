import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:get/get.dart';
import 'package:hablar_clone/controllers/call_signalling_controller.dart';
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
  final CallSignallingController _callController = Get.put(CallSignallingController());
  webrtc.RTCVideoRenderer _localRenderer = webrtc.RTCVideoRenderer();
  webrtc.RTCVideoRenderer _remoteRenderer = webrtc.RTCVideoRenderer();
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

  //Initialize WebRTC video call
  void _initializeVideoCall() async {
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

    print("🎥 Local video tracks:");
    _callController.localStream?.getVideoTracks().forEach((track) {
      print("Track ID: \${track.id}, Enabled: \${track.enabled}");
    });
  }

  //Listen for call Status Changes in firestore
  void _listenForCallStatus() {
    FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.callId)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            String status = snapshot['callStatus'] ?? 'calling';
            print("CALL STATUS: \$status");

            if (status == 'answered' && !isAnswered) {
              _timeoutTimer?.cancel();
              setState(() {
                isAnswered = true;
              });
              print("Call was answered! Starting timer...");
              _startCallTimer();
            }

            if (_callController.remoteStream.value != null) {
              if (_callController.remoteStream.value != null) {
              print("🔊 Ensuring Remote Audio is Active...");
              _callController.remoteStream.value?.getAudioTracks().forEach((track) {
                track.enabled = true;
              });

              // ✅ Assign remote stream to the renderer if not already assigned
              
              // 🐛 DEBUG: Print all remote tracks
              _callController.remoteStream.value?.getTracks().forEach((track) {
                print("📺 Remote track: kind=${track.kind}, enabled=${track.enabled}");
              });

              _callController.remoteStream.value?.getVideoTracks().forEach((track) {
                print("🎥 Remote video track: ${track.id}, enabled: ${track.enabled}");
                track.enabled = true; // Force-enable
              });

              if (_remoteRenderer.srcObject == null) {
                _remoteRenderer.srcObject = _callController.remoteStream.value;
                print("🎥 Remote stream assigned to renderer.");
              }
            }
              _callController.remoteStream.value?.getAudioTracks().forEach((track) {
                track.enabled = true;
              });
            }

            if ((status == 'ended' || status == 'missed') && !isCallEnded) {
              _endCall();
            }
          }
        });
  }

  //automatically End Call If No Answer After 15 Seconds
  void _startCallTimeout() {
    _timeoutTimer = Timer(const Duration(seconds: 15), () async {
      DocumentSnapshot callSnapshot = await FirebaseFirestore.instance
          .collection('calls')
          .doc(widget.callId)
          .get();

      if (callSnapshot.exists) {
        String status = callSnapshot['callStatus'] ?? 'calling';

        if (status == 'calling') {
          await FirebaseFirestore.instance
              .collection('calls')
              .doc(widget.callId)
              .update({'callStatus': 'missed'});
        }
      }
    });
  }

  //end call and close the call screen
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
                    // Remote Video (Big)
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.black,
                      child: webrtc.RTCVideoView(
                        _remoteRenderer,
                        objectFit: webrtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
                    ),

                    // Local Video (Small)
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
                        child: webrtc.RTCVideoView(
                          _localRenderer,
                          mirror: true,
                          objectFit: webrtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        ),
                      ),
                    ),

                    // Call Status
                    Positioned(
                      top: 40,
                      child: Column(
                        children: [
                          Text(
                            isAnswered ? "In Call" : "Calling...",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              color: utils.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Call Controls
              Container(
                padding: EdgeInsets.symmetric(vertical: 20),
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
                        setState(() {
                          isAudioOn = !isAudioOn;
                          _callController.localStream?.getAudioTracks().first.enabled = isAudioOn;
                        });
                      },
                    ),

                    IconButton(
                      icon: Icon(
                        isVideoOn ? Icons.videocam : Icons.videocam_off,
                        color: isVideoOn ? Colors.green : Colors.red,
                        size: 40,
                      ),
                      onPressed: () {
                        setState(() {
                          isVideoOn = !isVideoOn;
                          _callController.localStream?.getVideoTracks().first.enabled = isVideoOn;
                        });
                      },
                    ),

                    IconButton(
                      icon: Icon(Icons.call_end, color: Colors.red, size: 40),
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