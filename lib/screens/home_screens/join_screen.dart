import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hablar_clone/controllers/call_signalling_controller.dart';
import 'package:hablar_clone/utils/colors.dart' as utils;
import 'package:hablar_clone/screens/home_screens/call_screen.dart';

class JoinScreen extends StatelessWidget {
  final String selfCallerId;
  final CallSignallingController callController = Get.put(
    CallSignallingController(),
  );
  JoinScreen({super.key, required this.selfCallerId});
  final TextEditingController remoteCallerIdController =
      TextEditingController();

  void _joinCall({
    required String callerId,
    required String calleeId,
    dynamic offer,
  }) {
    Get.to(
      () => CallScreen(callerId: callerId, calleeId: calleeId, offer: offer),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [utils.purpleLilac, utils.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: utils.darkGrey),
                      onPressed: () => Get.back(),
                    ),
                    SizedBox(width: 80),
                    Text(
                      'Join a Call',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: utils.darkGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Self Caller ID
                        TextField(
                          controller: TextEditingController(text: selfCallerId),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'Poppins'),
                          decoration: InputDecoration(
                            hintText: "Your Caller ID",
                            hintStyle: TextStyle(fontFamily: 'Poppins'),
                            filled: true,
                            fillColor: utils.lightGrey,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Remote Caller ID
                        TextField(
                          controller: remoteCallerIdController,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'Poppins'),
                          decoration: InputDecoration(
                            hintText: "Enter Remote Caller ID",
                            hintStyle: TextStyle(fontFamily: 'Poppins'),
                            filled: true,
                            fillColor: utils.lightGrey,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: utils.darkPurple,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(200, 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          onPressed: () {
                            _joinCall(
                              callerId: selfCallerId,
                              calleeId: remoteCallerIdController.text,
                            );
                          },
                          child: Text(
                            "Start Call",
                            style: TextStyle(fontSize: 16, fontFamily: 'Poppins'),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Incoming Call Alert
                        Obx(() {
                          if (callController.remoteSDP.value.isNotEmpty) {
                            return Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              color: utils.lightGrey,
                              child: ListTile(
                                title: Text(
                                  "Incoming Call from ${callController.remoteSDP.value}",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: utils.darkGrey,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Reject Call Button
                                    IconButton(
                                      icon: const Icon(
                                        Icons.call_end,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => callController.endCall(),
                                    ),
                                    // Accept Call Button
                                    IconButton(
                                      icon: const Icon(
                                        Icons.call,
                                        color: Colors.green,
                                      ),
                                      onPressed: () {
                                        _joinCall(
                                          callerId: callController.remoteSDP.value,
                                          calleeId: selfCallerId,
                                          offer: callController.remoteSDP.value,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        }),
                      ],
                    ),
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
