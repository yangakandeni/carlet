# Flavor System Guide

This document describes the complete dev/prod flavor setup for the Carlet app.

## Overview

The app uses Flutter flavors to maintain separate development and production environments with:
- Different Firebase projects (dev vs prod)
- Different app bundle identifiers
- Different app names
- Automatic emulator connections in dev only
- Strict environment separation

## Quick Start

### Running the App

```bash
# Development (default)
./tools/scripts/run_app.sh

# Development on specific device
./tools/scripts/run_app.sh --device ios

# Production
./tools/scripts/run_app.sh --env prod

# Production release build
./tools/scripts/run_app.sh --env prod --release
```

The script automatically sets the correct flavor and dart-defines based on the environment.

### Building Release Bundles

**Android:**
```bash
# Development
flutter build appbundle --flavor dev --dart-define=APP_ENV=dev

# Production
flutter build appbundle --flavor prod --dart-define=APP_ENV=prod
```

**iOS:**
```bash
# Development
flutter build ios --flavor dev --dart-define=APP_ENV=dev

# Production  
flutter build ios --flavor prod --dart-define=APP_ENV=prod
```

## Architecture

### Environment Configuration (`lib/env/env.dart`)

Central class that manages environment-specific settings:

```dart
class Env {
  static bool get isDev => const String.fromEnvironment('APP_ENV') == 'dev';
  static bool get isProd => const String.fromEnvironment('APP_ENV') == 'prod';
  static bool get useEmulators => isDev && kDebugMode;
  static FirebaseOptions get firebaseOptions => isDev 
    ? DefaultFirebaseOptions.currentPlatform 
    : ProdFirebaseOptions.currentPlatform;
}
```

Key features:
- `isDev`/`isProd`: Detects current environment from dart-defines
- `useEmulators`: Only true in dev mode + debug builds
- `firebaseOptions`: Returns correct Firebase config for environment
- `logEnvironment()`: Debug logging helper

### Android Configuration

**Flavors defined in `android/app/build.gradle.kts`:**

```kotlin
flavorDimensions += "environment"
productFlavors {
    create("dev") {
        dimension = "environment"
        applicationId = "com.techolosh.carletdev"
        resValue("string", "app_name", "Carlet (Dev)")
    }
    create("prod") {
        dimension = "environment"
        applicationId = "com.techolosh.carlet"
        resValue("string", "app_name", "Carlet")
    }
}
```

**Firebase configs:**
- Dev: `android/app/src/dev/google-services.json`
- Prod: `android/app/src/prod/google-services.json`

### iOS Configuration

**Schemes:**
- `Runner (Dev)` - Development environment
- `Runner (Prod)` - Production environment

**Build Configurations:**
- Dev: Debug-Dev, Profile-Dev, Release-Dev
- Prod: Debug-Prod, Profile-Prod, Release-Prod

**Firebase configs:**
- Dev: `ios/Runner/Dev/GoogleService-Info.plist`
- Prod: `ios/Runner/Prod/GoogleService-Info.plist`

**Build Phase Script (`ios/Runner/copy-firebase-config.sh`):**
Automatically copies the correct GoogleService-Info.plist based on the active configuration.

**Bundle Identifiers:**
- Dev: `com.techolosh.carletdev`
- Prod: `com.techolosh.carlet`

## Environment Properties

| Property | Dev | Prod |
|----------|-----|------|
| Firebase Project | carlet-dev-6be6a | carlet (TBD) |
| Android Package | com.techolosh.carletdev | com.techolosh.carlet |
| iOS Bundle ID | com.techolosh.carletdev | com.techolosh.carlet |
| App Name | Carlet (Dev) | Carlet |
| Emulators | Auto-connect in debug | Never |
| Firebase Config | firebase_options.dart | firebase_options_prod.dart |

## Setup Instructions

### 1. iOS Scheme Configuration (One-Time Setup)

Follow the detailed guide in `docs/IOS_SCHEME_SETUP.md` to:
1. Create build configurations (Dev/Prod)
2. Set bundle identifiers per configuration
3. Add the copy-firebase-config.sh build phase
4. Create Dev and Prod schemes

This is a **manual** step that must be done in Xcode.

### 2. Production Firebase Project (Required for Prod Deployment)

1. Create a new Firebase project called `carlet`
2. Add iOS app with bundle ID: `com.techolosh.carlet`
3. Add Android app with package: `com.techolosh.carlet`
4. Download the config files

### 3. Generate Production Firebase Options

Run the flutterfire CLI to generate the production Dart config:

```bash
flutterfire configure \
  --project=carlet \
  --out=lib/firebase_options_prod.dart \
  --ios-bundle-id=com.techolosh.carlet \
  --android-package-name=com.techolosh.carlet
```

This will replace the placeholder in `lib/firebase_options_prod.dart` with real credentials.

### 4. Update Firebase Config Files

**Android:**
Copy the downloaded `google-services.json` from Firebase Console to:
```
android/app/src/prod/google-services.json
```

**iOS:**
Copy the downloaded `GoogleService-Info.plist` from Firebase Console to:
```
ios/Runner/Prod/GoogleService-Info.plist
```

## Verification

### Check Current Environment

The app logs environment info at startup:
```
🚀 Environment: dev
📱 Package ID: com.techolosh.carletdev
🔌 Emulators: ENABLED (dev + debug mode)
🔥 Firebase Project: carlet-dev-6be6a
```

### Verify Flavor Configuration

**Android:**
```bash
cd android
./gradlew app:dependencies --configuration devDebugRuntimeClasspath | grep google-services
./gradlew app:dependencies --configuration prodReleaseRuntimeClasspath | grep google-services
```

**iOS:**
Build in Xcode and check the build log for:
```
✅ Copied GoogleService-Info.plist from Dev configuration
```

### Test Emulator Connections

Dev build should connect to emulators automatically:
```
firebase emulators:start
./tools/scripts/run_app.sh --env dev
```

Prod build should NEVER connect to emulators even if they're running:
```
./tools/scripts/run_app.sh --env prod
# Check logs - should see "Emulators: DISABLED (production environment)"
```

## Troubleshooting

### Android: "No matching client found for package name"

The `google-services.json` doesn't match the applicationId. Check:
1. Is the file in the correct flavor directory? (`src/dev/` vs `src/prod/`)
2. Does the package_name in the JSON match the applicationId in build.gradle?
3. Did you download the config from the correct Firebase project?

### iOS: "FirebaseApp.configure() failed"

The GoogleService-Info.plist wasn't copied correctly. Check:
1. Is `copy-firebase-config.sh` added as a build phase?
2. Is it running BEFORE "Copy Bundle Resources"?
3. Do the plist files exist in `Runner/Dev/` and `Runner/Prod/`?
4. Check build logs for the script output

### Emulators connecting in production

This should be IMPOSSIBLE with the current setup. If it happens:
1. Check that `APP_ENV=prod` is set in dart-defines
2. Verify `Env.useEmulators` returns false
3. Check Firebase console to see if prod data is actually being written

### Wrong Firebase project being used

Check dart-defines:
```bash
flutter run --flavor dev --dart-define=APP_ENV=dev
```

The `APP_ENV` dart-define MUST match the flavor name.

## Best Practices

1. **Always use the run script** for development: `./tools/scripts/run_app.sh`
2. **Never hardcode environment values** - always use `Env.isDev`, `Env.isProd`, etc.
3. **Test production builds locally** before submitting to stores
4. **Keep emulator connections dev-only** - production should never touch emulators
5. **Use separate Firebase projects** - never mix dev and prod data
6. **Version control** - commit all flavor config files (except sensitive keys in Firebase configs)

## Future Enhancements

Potential improvements:
- [ ] Add staging environment (3-flavor system)
- [ ] Environment-specific API endpoints
- [ ] Feature flags per environment
- [ ] Automated E2E tests per flavor
- [ ] CI/CD pipeline with flavor-based deployments
