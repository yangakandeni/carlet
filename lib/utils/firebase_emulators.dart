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
  if (_connected || !kUseEmulators) return;
  final host = emulatorHost;

  // Auth Emulator (port 9098 per firebase.json)
  await FirebaseAuth.instance.useAuthEmulator(host, 9098);

  // Firestore Emulator (port 8085 per firebase.json)
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8085);
  // Recommended settings for emulator/dev
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
    sslEnabled: false,
  );

  // Storage Emulator (port 9198 per firebase.json)
  await FirebaseStorage.instance.useStorageEmulator(host, 9198);

  // Note: Cloud Functions emulator is optional and not required here since
  // this app doesn't call functions from the client. If needed, add
  // cloud_functions to pubspec and configure useFunctionsEmulator(host, 5001).

  _connected = true;
}
