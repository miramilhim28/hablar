import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:hablar_clone/modules/call/controllers/call_signalling_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hablar_clone/utils/colors.dart' as utils;
import 'dart:async';

class VideoCallScreen extends StatefulWidget {
  final String callerId;
  final String calleeId;
  final String callId;
  final dynamic offer;
  final String callType;

  const VideoCallScreen({
    super.key,
    required this.callId,
    required this.callerId,
    required this.calleeId,
    this.offer,
    required this.callType,
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
  StreamSubscription? _remoteStreamSubscription;

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

    // If we're the callee, we need to join the room
    if (_callController.roomId != widget.callId) {
      print("🔄 Joining room: ${widget.callId}");
      await _callController.joinRoom(widget.callId, _remoteRenderer);
    }

    // Set up local stream if it doesn't exist
    _callController.localStream ??= await webrtc.navigator.mediaDevices
        .getUserMedia({
          'audio': true,
          'video':
              widget.callType == "video"
                  ? {
                    'facingMode': 'user',
                    'width': {'ideal': 1280},
                    'height': {'ideal': 720},
                  }
                  : false,
        });

    // Set local renderer
    setState(() {
      _localRenderer.srcObject = _callController.localStream;
    });

    // Listen for remote stream changes
    _remoteStreamSubscription = _callController.remoteStream.listen((stream) {
      if (stream != null && mounted) {
        setState(() {
          _remoteRenderer.srcObject = stream;
          print("🖥 Remote renderer updated with new stream");

          // Force enable all tracks on the remote stream
          stream.getTracks().forEach((track) {
            track.enabled = true;
            print("✅ Force enabled remote track: ${track.kind}");
          });
        });
      }
    });
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

          // Set remote renderer again when answered
          if (status == 'answered' &&
              _callController.remoteStream.value != null) {
            setState(() {
              _remoteRenderer.srcObject = _callController.remoteStream.value;
              print("📱 Remote renderer set after answer");

              // Force enable all tracks on the remote stream
              _callController.remoteStream.value!.getTracks().forEach((track) {
                track.enabled = true;
                print("✅ Remote track enabled after answer: ${track.kind}");
              });
            });
          }

          if (status == 'declined' || status == 'ended' || status == 'missed') {
            print('Call was declined or ended. Closing the caller screen.');
            if (mounted) {
              Get.back(); 
            }
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
    // Only start timeout if we're the caller
    if (_callController.isInitiator) {
      _timeoutTimer = Timer(const Duration(seconds: 30), () async {
        DocumentSnapshot snapshot =
            await FirebaseFirestore.instance
                .collection('calls')
                .doc(widget.callId)
                .get();

        if (snapshot.exists &&
            (snapshot['callStatus'] ?? 'calling') == 'calling') {
          await FirebaseFirestore.instance
              .collection('calls')
              .doc(widget.callId)
              .update({'callStatus': 'missed'});
        }
      });
    }
  }

  Future<void> _endCall() async {
    if (!isCallEnded) {
      setState(() => isCallEnded = true);
      await _callController.hangUp();
      Get.back();
    }
  }

  void _toggleAudio() {
    setState(() => isAudioOn = !isAudioOn);
    _callController.localStream?.getAudioTracks().forEach(
      (track) => track.enabled = isAudioOn,
    );
  }

  void _toggleVideo() {
    setState(() => isVideoOn = !isVideoOn);
    _callController.localStream?.getVideoTracks().forEach(
      (track) => track.enabled = isVideoOn,
    );
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _remoteStreamSubscription?.cancel();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
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
                    // Remote video (full screen)
                    Obx(
                      () => Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Colors.black,
                        child:
                            _callController.remoteStream.value != null
                                ? RTCVideoView(
                                  _remoteRenderer,
                                  mirror: false,
                                  objectFit:
                                      RTCVideoViewObjectFit
                                          .RTCVideoViewObjectFitCover,
                                )
                                : const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                      ),
                    ),

                    // Local video (small overlay)
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
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: RTCVideoView(
                            _localRenderer,
                            mirror: true,
                            objectFit:
                                RTCVideoViewObjectFit
                                    .RTCVideoViewObjectFitCover,
                          ),
                        ),
                      ),
                    ),

                    // Call status
                    Positioned(
                      top: 40,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isAnswered
                              ? "In Call (${_formatDuration(callDurationInSeconds)})"
                              : "Calling...",
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            color: Colors.white,
                          ),
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
                        size: 30,
                      ),
                      onPressed: _toggleAudio,
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.call_end,
                          color: Colors.white,
                          size: 30,
                        ),
                        onPressed: _endCall,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isVideoOn ? Icons.videocam : Icons.videocam_off,
                        color: isVideoOn ? Colors.green : Colors.red,
                        size: 30,
                      ),
                      onPressed: _toggleVideo,
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
