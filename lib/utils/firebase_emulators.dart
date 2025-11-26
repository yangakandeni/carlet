import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import 'package:carlet/env/env.dart';

// Emulator connection is now controlled by Env.useEmulators
// which checks:
// - APP_ENV=dev (required)
// - kDebugMode=true (required)
// - USE_EMULATORS=true (optional explicit flag)
//
// This ensures production builds never connect to emulators.

String _defaultHost() {
  // On Android emulators, the host machine is 10.0.2.2
  if (Platform.isAndroid) return '10.0.2.2';
  // iOS simulator/macOS/web can use localhost
  // Physical iOS devices need the Mac's IP address (set via EMULATOR_HOST)
  return 'localhost';
}

bool _isPhysicalIOSDevice() {
  // Physical iOS devices can't connect to localhost emulators
  // They need the Mac's IP address set via --dart-define EMULATOR_HOST=<ip>
  return Platform.isIOS &&
      !Platform.environment.containsKey('SIMULATOR_DEVICE_NAME');
}

String get emulatorHost {
  const envHost = String.fromEnvironment('EMULATOR_HOST', defaultValue: '');
  return envHost.isNotEmpty ? envHost : _defaultHost();
}

bool _connected = false;

Future<void> connectToFirebaseEmulators() async {
  if (_connected || !Env.useEmulators) {
    if (!Env.useEmulators) {
      debugPrint(
          '[EMULATOR] Emulators disabled - using ${Env.isProd ? 'PRODUCTION' : 'DEVELOPMENT'} Firebase');
    }
    return;
  }

  // Physical iOS devices can't connect to localhost emulators
  // Skip emulator connection and use live Firebase instead
  if (_isPhysicalIOSDevice()) {
    const emulatorHost =
        String.fromEnvironment('EMULATOR_HOST', defaultValue: '');
    if (emulatorHost.isEmpty) {
      debugPrint(
          '[EMULATOR] Skipping emulators on physical iOS device (use live dev Firebase)');
      debugPrint(
          '[EMULATOR] To use emulators, set --dart-define EMULATOR_HOST=<your-mac-ip>');
      return;
    }
  }

  final host = emulatorHost;

  debugPrint('[EMULATOR] Connecting to Firebase Emulators at $host...');

  // Auth Emulator (port 9098 per firebase.json)
  await FirebaseAuth.instance.useAuthEmulator(host, 9098);
  debugPrint('[EMULATOR] ✓ Auth Emulator connected at $host:9098');

  // Firestore Emulator (port 8085 per firebase.json)
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8085);
  // Recommended settings for emulator/dev
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
    sslEnabled: false,
  );
  debugPrint('[EMULATOR] ✓ Firestore Emulator connected at $host:8085');

  // Storage Emulator (port 9198 per firebase.json)
  await FirebaseStorage.instance.useStorageEmulator(host, 9198);
  debugPrint('[EMULATOR] ✓ Storage Emulator connected at $host:9198');

  // Note: Cloud Functions emulator is optional and not required here since
  // this app doesn't call functions from the client. If needed, add
  // cloud_functions to pubspec and configure useFunctionsEmulator(host, 5001).

  _connected = true;
  debugPrint('[EMULATOR] All emulators connected successfully!');
}
