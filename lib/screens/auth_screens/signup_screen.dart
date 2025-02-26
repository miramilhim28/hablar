import 'package:flutter/material.dart';
import 'package:hablar_clone/screens/auth_screens/login_screen.dart';
import 'package:hablar_clone/utils/colors.dart' as utils;
import 'package:hablar_clone/controllers/auth_controller.dart';
import 'package:get/get.dart';

class SignupScreen extends StatelessWidget{
  SignupScreen({super.key});
  final AuthController _signupController = Get.put(AuthController());

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
              utils.white,
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

            //text field input for name:
            SizedBox(
              width: 300,
              height: 50,
              child: TextField(
                controller: _signupController.nameController,
                decoration: InputDecoration(
                  hintText: 'Name',
                  filled: true,
                  fillColor: utils.lightGrey,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(height: 24),

            //text field input for email:
            SizedBox(
              width: 300,
              height: 50,
              child: TextField(
                controller: _signupController.emailController,
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

            //text field for password:
            SizedBox(
              width: 300,
              height: 50,
              child: TextField(
                controller: _signupController.passwordController,
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

            //Signup button
            Obx(() => ElevatedButton(
              onPressed: _signupController.isLoading.value
                    ? null
                    : _signupController.signUpUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: utils.darkPurple,
                foregroundColor: utils.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: 
                const EdgeInsets.all(16),
              ),
              child: _signupController.isLoading.value ? 
              const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: utils.white,
                  strokeWidth: 2,
                ),
              )
              : const Text(
                'Sign Up',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  color: utils.white,
                ),
              ),
            ),),
            const SizedBox(height: 24),

            //login link:
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Already have an account? ',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: utils.darkGrey
                  )
                ),
                GestureDetector(
                  onTap: () => Get.to(LoginScreen()),
                  child: const Text(
                    'Log In',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: utils.darkPurple,
                      fontWeight: FontWeight.bold,
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