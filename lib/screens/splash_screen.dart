import 'package:flutter/material.dart';
import 'package:hablar/utils/colors.dart';
import 'package:hablar/utils/colors.dart' as utils;

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,

              colors: [
                utils.purpleLilac,
                Colors.white,
              ],
            )
          ),
          child: Center(
            child: Image.asset('assets/hablar_logo.png',
            width: 271,
            height: 48,
            ),
          ),
        ),
      ),
    );
  }
}