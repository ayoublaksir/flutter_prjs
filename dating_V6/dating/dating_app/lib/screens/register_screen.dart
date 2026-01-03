import 'package:flutter/material.dart';
import 'signup/multi_step_signup_screen.dart';

class RegisterScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Automatically redirect to the new signup screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MultiStepSignupScreen()),
      );
    });

    // Show a loading indicator while redirecting
    return Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
