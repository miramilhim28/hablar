import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:get/get.dart';
import 'package:hablar_clone/controllers/call_signalling_controller.dart';
import 'package:hablar_clone/utils/colors.dart' as utils;

class AudioCallScreen extends StatefulWidget {
  final String callerId, calleeId;
  final dynamic offer;

  const AudioCallScreen({
    super.key,
    this.offer,
    required this.callerId,
    required this.calleeId,
  });

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  final CallSignallingController _callController = Get.put(CallSignallingController());
  webrtc.MediaStream? _localStream;
  bool isAudioOn = true;
  String callDuration = "00:00";
  bool isCallEnded = false;

  @override
  void initState() {
    super.initState();
    _initializeAudioCall();
    _startCallTimer();
  }

  Future<void> _initializeAudioCall() async {
    try {
      _localStream = await webrtc.navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
      if (widget.offer != null) {
        await _callController.answerCall(widget.offer["offerSDP"]);
      }
    } catch (e) {
      print("Error initializing audio call: $e");
    }
  }

  void _startCallTimer() {
    Duration duration = Duration();
    if (!isCallEnded) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && !isCallEnded) {
          setState(() {
            duration = Duration(seconds: duration.inSeconds + 1);
            callDuration = "${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
          });
          _startCallTimer();
        }
      });
    }
  }

  // Fetch callee's name from contacts array
  Future<String> getCalleeName(String calleeId) async {
  try {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.callerId)  
        .get();

    if (snapshot.exists && snapshot.data() != null) {
      List<dynamic> contacts = snapshot['contacts'];

      for (var contact in contacts) {
        if (contact['id'] == calleeId) {
          return contact['name'] ?? 'Unknown'; 
        }
      }
    }
    return 'Unknown'; 
  } catch (e) {
    print('Error fetching callee name: $e');
    return 'Unknown'; 
  }
}


  @override
  void dispose() {
    _localStream?.dispose();
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
              // Profile Picture & Caller/Callee Info
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

              // Fetching Callee Name
              FutureBuilder<String>(
                future: getCalleeName(widget.calleeId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError || !snapshot.hasData) {
                    return Text(
                      'Unknown',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: utils.white,
                      ),
                    );
                  } else {
                    return Text(
                      snapshot.data!,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: utils.white,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 10),
              Text(
                "In Call",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  color: utils.darkPurple,
                ),
              ),
              const SizedBox(height: 30),

              // Call Timer
              Text(
                callDuration,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: utils.darkGrey,
                ),
              ),
              const SizedBox(height: 40),

              // Audio Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
                      });
                    },
                  ),
                  const SizedBox(width: 40),
                  IconButton(
                    icon: Icon(
                      Icons.call_end,
                      color: Colors.red,
                      size: 40,
                    ),
                    onPressed: () async {
                      Get.back();
                    },
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
