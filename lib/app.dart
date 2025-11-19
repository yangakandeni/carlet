import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import 'package:carlet/screens/splash_screen.dart';
import 'package:carlet/screens/auth/login_screen.dart';
// Signup removed; phone-only authentication.
import 'package:carlet/screens/home/home_screen.dart';
import 'package:carlet/screens/report/create_report_screen.dart';
import 'package:carlet/screens/auth/onboarding_screen.dart';
import 'package:carlet/screens/profile/profile_screen.dart';
import 'package:carlet/core/theme/app_theme.dart';

class CarletApp extends StatelessWidget {
  const CarletApp({super.key});

  @override
  Widget build(BuildContext context) {
    final messengerKey = GlobalKey<ScaffoldMessengerState>();

    return ToastificationWrapper(
      child: MaterialApp(
          title: 'Carlet',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.system,
          scaffoldMessengerKey: messengerKey,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          initialRoute: SplashScreen.routeName,
          routes: {
            SplashScreen.routeName: (_) => const SplashScreen(),
            LoginScreen.routeName: (_) => const LoginScreen(),
            OnboardingScreen.routeName: (_) => const OnboardingScreen(),
            HomeScreen.routeName: (_) => const HomeScreen(),
            CreateReportScreen.routeName: (_) => const CreateReportScreen(),
            ProfileScreen.routeName: (_) => const ProfileScreen(),
          }),
    );
  }
}
