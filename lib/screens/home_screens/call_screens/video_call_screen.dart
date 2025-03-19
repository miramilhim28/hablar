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
  Future<void> _initializeVideoCall() async {
    try {
      await _localRenderer.initialize();
      await _remoteRenderer.initialize();

      //get user media with video
      _callController.localStream =
          await webrtc.navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {
          'facingMode': 'user', // Front camera
          'width': {'ideal': 1280},
          'height': {'ideal': 720}
        }
      });

      //Attach local stream to UI
      _localRenderer.srcObject = _callController.localStream;

      if (_callController.localStream != null) {
        _callController.localStream!.getTracks().forEach((track) {
          _callController.peerConnection?.addTrack(track, _callController.localStream!);
        });
      }

      if (widget.offer != null && widget.callId.isNotEmpty) {
        await _callController.joinRoom(widget.callId, _remoteRenderer);
      }

      //Listen for remote stream
      _callController.remoteStream.listen((stream) {
        if (stream != null) {
          setState(() {
            _remoteRenderer.srcObject = stream;
          });
        }
      });

    } catch (e) {
      print("Error initializing video call: $e");
    }
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
        print("CALL STATUS: $status");

        if (status == 'answered' && !isAnswered) {
          _timeoutTimer?.cancel();
          setState(() {
            isAnswered = true;
          });
          print("Call was answered! Starting timer...");
          _startCallTimer();
        }

        if ((status == 'ended' || status == 'missed') && !isCallEnded) {
          _endCall();
        }
      }
    });
  }

  //automatically End Call If No Answer After 30 Seconds
  void _startCallTimeout() {
    _timeoutTimer = Timer(const Duration(seconds: 30), () async {
      DocumentSnapshot callSnapshot = await FirebaseFirestore.instance
          .collection('calls')
          .doc(widget.callId)
          .get();

      if (callSnapshot.exists) {
        String status = callSnapshot['callStatus'] ?? 'calling';

        //If still calling after 30 sec, mark as missed
        if (status == 'calling') {
          await FirebaseFirestore.instance.collection('calls').doc(widget.callId).update({
            'callStatus': 'missed',
          });
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
                      child: webrtc.RTCVideoView(_remoteRenderer),
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
                    // Mute Audio
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

                    // Toggle Video
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

                    // End Call
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
