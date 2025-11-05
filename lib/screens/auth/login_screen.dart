import 'package:flutter/material.dart';
import 'package:carlet/screens/auth/phone_verification_screen.dart';

class LoginScreen extends StatelessWidget {
  static const routeName = '/login';
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) => const PhoneVerificationScreen();
}
