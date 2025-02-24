import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hablar/controllers/otp_controller.dart';
import 'package:hablar/utils/colors.dart' as utils;

class OtpScreen extends StatelessWidget{
  final OtpController _otpController = Get.put(OtpController());

  OtpScreen({super.key, required String verificationId}){
    _otpController.setVerificationId(Get.arguments['verificationId']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              utils.purpleLilac,
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Enter OTP',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              //otp input field:
              SizedBox(
                width: 250,
                child: TextField(
                  controller: _otpController.otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    hintText: '6-digit Code',
                    counterText: '',
                    filled: true,
                    fillColor: utils.lightGrey,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              //verify button:
              Obx(() => ElevatedButton(
              onPressed: (){},
              style: ElevatedButton.styleFrom(
                backgroundColor: utils.darkPurple,
                foregroundColor: utils.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: 
                const EdgeInsets.all(16),
              ),
              child: _otpController.isLoading.value ? 
              const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: utils.white,
                  strokeWidth: 2,
                ),
              )
              : const Text(
                'Verify',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  color: utils.white,
                ),
              ),
            ),),
            ],
          ),
        ),
      ),
    );
  }
}