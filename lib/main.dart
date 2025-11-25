import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:carlet/services/auth_service.dart';
import 'package:carlet/services/messaging_service.dart';
import 'package:carlet/app.dart';
import 'package:carlet/firebase_options.dart';
import 'package:carlet/utils/firebase_emulators.dart';

// Top-level background handler for FCM
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Prevent Google Fonts from trying to access file system in background isolate
  GoogleFonts.config.allowRuntimeFetching = false;

  // Initialize Firebase with error handling for duplicate app
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      // Firebase already initialized, safe to continue
      debugPrint('[Firebase] App already initialized in background handler');
    } else {
      rethrow;
    }
  }

  // If compiled with --dart-define=USE_EMULATORS=true, connect to local emulators
  await connectToFirebaseEmulators();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with error handling for duplicate app
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      // Firebase already initialized, safe to continue
      debugPrint('[Firebase] App already initialized, continuing...');
    } else {
      rethrow;
    }
  }

  // Connect to Firebase Emulators if USE_EMULATORS=true
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
