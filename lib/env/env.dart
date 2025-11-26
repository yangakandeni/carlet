import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'package:carlet/firebase_options.dart' as dev;
import 'package:carlet/firebase_options_prod.dart' as prod;

/// Environment configuration for the app.
///
/// Determines which Firebase project, app identifiers, and backend
/// services to use based on the build flavor (dev or prod).
///
/// Usage:
/// - Dev builds: `flutter run --flavor dev --dart-define=APP_ENV=dev`
/// - Prod builds: `flutter build appbundle --flavor prod --dart-define=APP_ENV=prod`
class Env {
  Env._();

  /// Current environment name (dev or prod)
  static const String _env =
      String.fromEnvironment('APP_ENV', defaultValue: 'dev');

  /// Whether the app is in development environment
  static bool get isDev => _env == 'dev';

  /// Whether the app is in production environment
  static bool get isProd => _env == 'prod';

  /// Whether to use Firebase emulators (only in dev + debug mode)
  static bool get useEmulators {
    const useEmulatorsFlag =
        String.fromEnvironment('USE_EMULATORS', defaultValue: 'false');
    // Only allow emulators in dev environment and debug mode
    return isDev && kDebugMode && useEmulatorsFlag == 'true';
  }

  /// Get the appropriate Firebase options based on environment
  static FirebaseOptions get firebaseOptions {
    if (isProd) {
      return prod.DefaultFirebaseOptions.currentPlatform;
    }
    return dev.DefaultFirebaseOptions.currentPlatform;
  }

  /// Environment name for logging
  static String get name => _env;

  /// App name suffix for development builds
  static String get appNameSuffix => isDev ? ' (Dev)' : '';

  /// Package/Bundle identifier
  static String get packageId {
    if (isProd) {
      return 'com.techolosh.carlet';
    }
    return 'com.techolosh.carletdev';
  }

  /// Log environment information
  static void logEnvironment() {
    debugPrint('[ENV] Environment: $_env');
    debugPrint('[ENV] isDev: $isDev');
    debugPrint('[ENV] isProd: $isProd');
    debugPrint('[ENV] useEmulators: $useEmulators');
    debugPrint('[ENV] packageId: $packageId');
    debugPrint(
        '[ENV] Firebase project: ${isProd ? 'PRODUCTION' : 'DEVELOPMENT'}');
  }
}
