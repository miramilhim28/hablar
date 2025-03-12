import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hablar_clone/controllers/call_signalling_controller.dart';
import 'package:hablar_clone/utils/colors.dart' as utils;
import 'package:hablar_clone/screens/home_screens/audio_call_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JoinScreen extends StatefulWidget {
  final String callerId;
  final String calleeId;

  JoinScreen({super.key, required this.callerId, required this.calleeId});

  @override
  _JoinScreenState createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final CallSignallingController callController = Get.put(
    CallSignallingController(),
  );
  final TextEditingController callerIdController = TextEditingController();
  final TextEditingController calleeIdController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    callerIdController.text = widget.callerId;
    calleeIdController.text = widget.calleeId;
  }

  void _joinCall({
    required String callerId,
    required String calleeId,
    dynamic offer,
  }) {
    Get.to(
      () =>
          AudioCallScreen(callerId: callerId, calleeId: calleeId, offer: offer),
    );
  }

  Future<void> _startCall() async {
    String callerId = callerIdController.text.trim();
    String calleeId = calleeIdController.text.trim();

    if (callerId.isEmpty || calleeId.isEmpty) {
      Get.snackbar("Error", "Please enter both Caller ID and Callee ID.");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      var offer = await callController.createOffer(
        myUserId: callerId,
        remoteUserId: calleeId,
      );
      _joinCall(callerId: callerId, calleeId: calleeId, offer: offer);
    } catch (e) {
      Get.snackbar("Error", "Failed to create offer: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    callerIdController.dispose();
    calleeIdController.dispose();
    super.dispose();
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
                        TextField(
                          controller: callerIdController,
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
                        TextField(
                          controller: calleeIdController,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'Poppins'),
                          decoration: InputDecoration(
                            hintText: "Enter the Callee ID",
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
                          onPressed: isLoading ? null : _startCall,
                          child:
                              isLoading
                                  ? CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : Text(
                                    "Start Call",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                        ),
                        const SizedBox(height: 20),
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
