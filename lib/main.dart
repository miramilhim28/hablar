import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hablar_clone/controllers/call_signalling_controller.dart';
import 'package:hablar_clone/screens/home_screens/settings_screen.dart';
import 'package:hablar_clone/screens/landing_screen.dart';
import 'screens/auth_screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final CallSignallingController callController = Get.put(CallSignallingController());
  String? userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId != null) {
    callController.listenForIncomingCalls(userId, calleeId: '');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      home: LoginScreen(),
    );
  }
}
