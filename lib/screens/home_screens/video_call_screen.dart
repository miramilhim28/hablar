import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:get/get.dart';
import 'package:hablar_clone/controllers/call_signalling_controller.dart';
import 'package:hablar_clone/utils/colors.dart' as utils;

class VideoCallScreen extends StatefulWidget {
  final String callerId, calleeId;
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
  String calleeName = "Unknown";

  @override
  void initState() {
    super.initState();
    _initializeVideoCall();
    _fetchCalleeName();
    _listenForCallStatus();
  }

  Future<void> _initializeVideoCall() async {
    try {
      await _localRenderer.initialize();
      await _remoteRenderer.initialize();

      await _callController.initializePeerConnection();
      _callController.localStream =
          await webrtc.navigator.mediaDevices.getUserMedia({'audio': true, 'video': true});
      _localRenderer.srcObject = _callController.localStream;

      if (_callController.localStream != null) {
        _callController.localStream!.getTracks().forEach((track) {
          _callController.peerConnection?.addTrack(track, _callController.localStream!);
        });
      }

      if (widget.offer != null && widget.callId.isNotEmpty) {
        await _callController.joinRoom(widget.callId, _remoteRenderer); 
      }

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

  //Listen for Call Status Updates from Firestore
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

  //Start Call Timer when Answered
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

  //End Call
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

                    // Callee Name & Call Status
                    Positioned(
                      top: 40,
                      child: Column(
                        children: [
                          Text(
                            calleeName,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: utils.white,
                            ),
                          ),
                          const SizedBox(height: 5),
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
                    if (isAnswered)
                      Positioned(
                        top: 80,
                        child: Text(
                          "${(callDurationInSeconds ~/ 60).toString().padLeft(2, '0')}:" +
                          "${(callDurationInSeconds % 60).toString().padLeft(2, '0')}",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: utils.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Call Controls
              Container(
                padding: EdgeInsets.symmetric(vertical: 20),
                color: Colors.black.withOpacity(0.2),
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
