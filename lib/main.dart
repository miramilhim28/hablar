import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hablar_clone/modules/call/controllers/call_signalling_controller.dart';
import 'package:hablar_clone/modules/auth/controllers/auth_controller.dart';
import 'package:hablar_clone/modules/home/controllers/home_controller.dart';
import 'package:hablar_clone/modules/home/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  Get.put(AuthController());
  Get.put(HomeController());
  Get.put(CallSignallingController());

  String? userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId != null) {
    Get.find<CallSignallingController>().listenForIncomingCalls(userId);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hablar',
      home: SplashScreen(),
    );
  }
}
