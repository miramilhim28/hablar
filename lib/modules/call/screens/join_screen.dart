import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hablar_clone/modules/call/controllers/call_signalling_controller.dart';
import 'package:hablar_clone/utils/colors.dart' as utils;
import 'package:hablar_clone/modules/call/screens/video_call_screen.dart';

class JoinScreen extends StatefulWidget {
  final String callerId;
  final String calleeId;
  final String callType;
  final bool isVideo;

  const JoinScreen({
    super.key,
    required this.callerId,
    required this.calleeId,
    required this.callType,
    this.isVideo = true,
  });

  @override
  _JoinScreenState createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final CallSignallingController callController = Get.put(
    CallSignallingController(),
  );
  bool isLoading = false;
  String? roomId; 

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
      roomId = await callController.createRoom(video: widget.isVideo);
      print("✅ Room Created: $roomId");

      await Future.delayed(const Duration(seconds: 1));

      RTCSessionDescription? offerSDP =
          await callController.peerConnection?.getLocalDescription();

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

      FirebaseFirestore.instance
          .collection('users')
          .doc(widget.calleeId)
          .update({
            'incomingCall': {
              'callId': roomId,
              'callerId': widget.callerId,
              'callType': widget.callType,
            },
          });

      _listenForAnswer(roomId!);
      _listenForCallStatus(roomId!); 
    } catch (e) {
      Get.snackbar("Error", "Failed to start call: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _listenForAnswer(String roomId) {
    FirebaseFirestore.instance
        .collection('calls')
        .doc(roomId)
        .snapshots()
        .listen(
          (snapshot) async {
            if (snapshot.exists) {
              var roomData = snapshot.data() as Map<String, dynamic>;

              if (roomData.containsKey('answer')) {
                print("✅ Call Answered! Setting Remote SDP...");

                RTCSessionDescription answerSDP = RTCSessionDescription(
                  roomData['answer']['sdp'],
                  roomData['answer']['type'],
                );

                if (callController.peerConnection!.signalingState ==
                    RTCSignalingState.RTCSignalingStateStable) {
                  print(
                    "⚠️ PeerConnection is already in stable state. Skipping setRemoteDescription.",
                  );
                  return;
                }

                await callController.peerConnection?.setRemoteDescription(
                  answerSDP,
                );

                print("✅ Remote SDP Set Successfully!");

                Get.off(
                  () => VideoCallScreen(
                    callerId: widget.callerId,
                    calleeId: widget.calleeId,
                    callId: roomId,
                    callType: widget.callType,
                  ),
                );
              }
            }
          },
          onError: (error) {
            print("❌ Error listening for answer: $error");
          },
        );
  }

  void _listenForCallStatus(String roomId) {
    FirebaseFirestore.instance
        .collection('calls')
        .doc(roomId)
        .snapshots()
        .listen(
      (snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data();
          final status = data?['callStatus'];

          if (status == 'declined' || status == 'missed' || status == 'ended') {
            print("📞 Call was $status. Closing JoinScreen...");
            if (mounted) {
              Get.back();
            }
          }
        }
      },
      onError: (error) {
        print("❌ Error listening for call status: $error");
      },
    );
  }

  Future<void> _cancelCall() async {
    try {
      if (roomId != null) {
        await FirebaseFirestore.instance.collection('calls').doc(roomId).update(
          {'callStatus': 'missed'},
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.calleeId)
            .update({'incomingCall': FieldValue.delete()});
      }
    } catch (e) {
      print("❌ Error cancelling call: $e");
    } finally {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: utils.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [utils.purpleLilac, utils.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Waiting for Answer...",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: utils.darkGrey,
                ),
              ),
              const SizedBox(height: 250),
              ElevatedButton.icon(
                onPressed: _cancelCall,
                icon: const Icon(Icons.call_end, color: Colors.white),
                label: const Text("Cancel Call"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
