import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hablar_clone/modules/auth/screens/login_screen.dart';
import 'package:hablar_clone/modules/home/screens/landing_screen.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 3)); // Splash delay

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      Get.offAll(() => const LandingScreen());
    } else {
      Get.offAll(() => LoginScreen());
    }
  }
}
