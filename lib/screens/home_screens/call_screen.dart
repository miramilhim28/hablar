import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:hablar_clone/controllers/call_signalling_controller.dart';

class CallScreen extends StatelessWidget {
  final String callerId, calleeId;
  final dynamic offer;
  final CallSignallingController callController = Get.put(
    CallSignallingController(),
  );

  CallScreen({
    super.key,
    this.offer,
    required this.callerId,
    required this.calleeId,
  });

  @override
  Widget build(BuildContext context) {
    // Initialize WebRTC when the screen is built
    if (offer != null) {
      callController.createAnswer(offer['sdpOffer'], offer['iceCandidates']);
    } else {
      callController.createOffer();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(centerTitle: true, title: const Text("P2P Call App")),
      body: SafeArea(
        child: Obx(() {
          if (!callController.isCallActive.value) {
            return Center(
              child: Text(
                'Waiting for the call to be accepted...',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    RTCVideoView(
                      RTCVideoRenderer(),
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                    Positioned(
                      right: 20,
                      bottom: 20,
                      child: SizedBox(
                        height: 150,
                        width: 120,
                        child: RTCVideoView(
                          RTCVideoRenderer(),
                          mirror: true, // Mirror local video
                          objectFit:
                              RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.call_end),
                      iconSize: 30,
                      onPressed: callController.endCall,
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
