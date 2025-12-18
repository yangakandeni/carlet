import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:carlet/services/auth_service.dart';
import 'package:carlet/services/messaging_service.dart';
import 'package:carlet/app.dart';
import 'package:carlet/env/env.dart';
import 'package:carlet/utils/firebase_emulators.dart';

// Top-level background handler for FCM
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Prevent Google Fonts from trying to access file system in background isolate
  GoogleFonts.config.allowRuntimeFetching = false;

  // Initialize Firebase with error handling for duplicate app
  try {
    await Firebase.initializeApp(
      options: Env.firebaseOptions,
    );
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      // Firebase already initialized, safe to continue
      debugPrint('[Firebase] App already initialized in background handler');
    } else {
      rethrow;
    }
  }

  // Connect to emulators only in dev environment
  await connectToFirebaseEmulators();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Log environment configuration
  Env.logEnvironment();

  // Initialize Firebase with error handling for duplicate app
  try {
    await Firebase.initializeApp(
      options: Env.firebaseOptions,
    );
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      // Firebase already initialized, safe to continue
      debugPrint('[Firebase] App already initialized, continuing...');
    } else {
      rethrow;
    }
  }

  // Initialize Firebase App Check
  // Use debug provider in dev, deviceCheck/appAttest in production
  if (Env.isDev) {
    // Development: use debug provider for testing
    await FirebaseAppCheck.instance.activate(
      appleProvider: AppleProvider.debug,
      androidProvider: AndroidProvider.debug,
    );
    debugPrint('[AppCheck] Firebase App Check activated (DEBUG mode)');
  } else {
    // Production: use platform-specific secure providers
    await FirebaseAppCheck.instance.activate(
      appleProvider: AppleProvider.deviceCheck,
      androidProvider: AndroidProvider.playIntegrity,
    );
    debugPrint('[AppCheck] Firebase App Check activated (PRODUCTION mode)');
  }

  // Connect to Firebase Emulators only in dev environment
  await connectToFirebaseEmulators();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => MessagingService()),
      ],
      child: const CarletApp(),
    ),
  );
}
