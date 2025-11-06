import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

// Compile-time flags:
// - USE_EMULATORS=true to enable emulator connections
// - EMULATOR_HOST=<host> to override default host (localhost/10.0.2.2)
const bool kUseEmulators =
    bool.fromEnvironment('USE_EMULATORS', defaultValue: false);
const String kEmulatorHostEnv =
    String.fromEnvironment('EMULATOR_HOST', defaultValue: '');

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
  print('[EMULATOR] USE_EMULATORS=$kUseEmulators, HOST=$emulatorHost');

  if (_connected || !kUseEmulators) {
    if (!kUseEmulators) {
      print('[EMULATOR] Emulators disabled - using production Firebase');
    }
    return;
  }
  final host = emulatorHost;

  print('[EMULATOR] Connecting to Firebase Emulators at $host...');

  // Auth Emulator (port 9098 per firebase.json)
  await FirebaseAuth.instance.useAuthEmulator(host, 9098);
  print('[EMULATOR] ✓ Auth Emulator connected at $host:9098');

  // Firestore Emulator (port 8085 per firebase.json)
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8085);
  // Recommended settings for emulator/dev
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
    sslEnabled: false,
  );
  print('[EMULATOR] ✓ Firestore Emulator connected at $host:8085');

  // Storage Emulator (port 9198 per firebase.json)
  await FirebaseStorage.instance.useStorageEmulator(host, 9198);
  print('[EMULATOR] ✓ Storage Emulator connected at $host:9198');

  // Note: Cloud Functions emulator is optional and not required here since
  // this app doesn't call functions from the client. If needed, add
  // cloud_functions to pubspec and configure useFunctionsEmulator(host, 5001).

  _connected = true;
  print('[EMULATOR] All emulators connected successfully!');
}
