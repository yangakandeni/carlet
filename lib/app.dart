import 'package:flutter/material.dart';

import 'package:carlet/screens/splash_screen.dart';
import 'package:carlet/screens/auth/login_screen.dart';
// Signup removed; phone-only authentication.
import 'package:carlet/screens/home/home_screen.dart';
import 'package:carlet/screens/report/create_report_screen.dart';
import 'package:carlet/screens/auth/onboarding_screen.dart';

class CarletApp extends StatelessWidget {
  const CarletApp({super.key});

  @override
  Widget build(BuildContext context) {
    final messengerKey = GlobalKey<ScaffoldMessengerState>();
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.indigo);
    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'Carlet',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      scaffoldMessengerKey: messengerKey,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          centerTitle: true,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: darkColorScheme,
        useMaterial3: true,
      ),
      initialRoute: SplashScreen.routeName,
      routes: {
        SplashScreen.routeName: (_) => const SplashScreen(),
        LoginScreen.routeName: (_) => const LoginScreen(),
          OnboardingScreen.routeName: (_) => const OnboardingScreen(),
        HomeScreen.routeName: (_) => const HomeScreen(),
        CreateReportScreen.routeName: (_) => const CreateReportScreen(),
      },
    );
  }
}
