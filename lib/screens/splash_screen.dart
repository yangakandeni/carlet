import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:carlet/services/auth_service.dart';
import 'package:carlet/services/messaging_service.dart';
import 'package:carlet/screens/auth/login_screen.dart';
import 'package:carlet/screens/home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  static const routeName = '/';
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthService>();
      if (!mounted) return;
      if (auth.currentUser != null) {
        final user = auth.currentUser!;
        final userId = user.id;
        // Best-effort update (no await to avoid blocking navigation)
        context.read<MessagingService>().ensurePermissionAndToken(userId);
        if (user.onboardingComplete == true) {
          Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
        } else {
          Navigator.of(context).pushReplacementNamed('/onboarding');
        }
      } else {
        Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FlutterLogo(size: 96),
            SizedBox(height: 16),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
