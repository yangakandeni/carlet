import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

// Compile-time flags:
// - USE_EMULATORS=true to explicitly enable emulator connections
// - EMULATOR_HOST=<host> to override default host (localhost/10.0.2.2)
// - APP_ENV=<ENV> can be used to select environment (DEV/STAGING/PROD)
const bool kUseEmulators =
  bool.fromEnvironment('USE_EMULATORS', defaultValue: false);
const String kEmulatorHostEnv =
  String.fromEnvironment('EMULATOR_HOST', defaultValue: '');
const String kAppEnv = String.fromEnvironment('APP_ENV', defaultValue: '');

// Decide whether to use emulators:
// - If USE_EMULATORS was compiled-in true, honor that.
// - If APP_ENV is set to DEV (via --dart-define APP_ENV=DEV) use emulators.
// - If the app is running in debug mode (kDebugMode), use emulators.
// This makes local development (debug runs or `APP_ENV=DEV`) automatically
// connect to emulators while allowing explicit overrides via USE_EMULATORS.
final bool kShouldUseEmulators = kUseEmulators ||
  kAppEnv.toUpperCase() == 'DEV' ||
  kDebugMode;

String _defaultHost() {
  // On Android emulators, the host machine is 10.0.2.2
  if (Platform.isAndroid) return '10.0.2.2';
  // iOS simulator/macOS/web can use localhost
  return 'localhost';
}

String get emulatorHost =>
    (kEmulatorHostEnv.isNotEmpty) ? kEmulatorHostEnv : _defaultHost();

bool _connected = false;

Future<void> connectToFirebaseEmulators() async {
  debugPrint('[EMULATOR] USE_EMULATORS=$kUseEmulators, APP_ENV=$kAppEnv, kDebugMode=$kDebugMode, HOST=$emulatorHost');

  if (_connected || !kShouldUseEmulators) {
    if (!kShouldUseEmulators) {
      debugPrint('[EMULATOR] Emulators disabled - using production Firebase');
    }
    return;
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
