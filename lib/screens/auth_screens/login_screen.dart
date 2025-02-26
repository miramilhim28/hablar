import 'package:flutter/material.dart';
import 'package:hablar_clone/screens/auth_screens/signup_screen.dart';
import 'package:hablar_clone/utils/colors.dart' as utils;
import 'package:hablar_clone/controllers/auth_controller.dart';
import 'package:get/get.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});
  final AuthController _loginController = Get.put(AuthController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              utils.purpleLilac,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 8),

            //logo image
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Image.asset(
                'assets/hablar_logo.png',
                width: 270,
                height: 50,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 50),

            //text field input for email:
            SizedBox(
              width: 300,
              height: 50,
              child: TextField(
                controller: _loginController.emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Email',
                  filled: true,
                  fillColor: utils.lightGrey,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            //text field input for Password:
            SizedBox(
              width: 300,
              height: 50,
              child: TextField(
                controller: _loginController.passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Password',
                  filled: true,
                  fillColor: utils.lightGrey,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            //LogIn Button:
            Obx(() => ElevatedButton(
                onPressed: _loginController.isLoading.value
                    ? null
                    : _loginController.loginUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: utils.darkPurple,
                  foregroundColor: utils.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding:
                      const EdgeInsets.all(14),
                ),
                child: _loginController.isLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: utils.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Sign In',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          color: utils.white,
                        ),
                      ))),
            const SizedBox(height: 24),

            //Sign Up Link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Don't have an account? ",
                  style:
                      TextStyle(color: utils.darkGrey, fontFamily: 'Poppins'),
                ),
                GestureDetector(
                  onTap: () =>
                      Get.to(() => SignupScreen()),
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      color: utils.darkPurple,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
