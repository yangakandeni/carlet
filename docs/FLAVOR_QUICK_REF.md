# Flavor System - Quick Reference

## Run Commands

```bash
# Development (default) - Auto-connects to emulators
./tools/scripts/run_app.sh

# Development on specific device
./tools/scripts/run_app.sh --device ios
./tools/scripts/run_app.sh --device android

# Production - Never uses emulators
./tools/scripts/run_app.sh --env prod

# Production release mode
./tools/scripts/run_app.sh --env prod --release
```

## Build Commands

### Android App Bundle (for Google Play)

```bash
# Development
flutter build appbundle --flavor dev --dart-define=APP_ENV=dev

# Production
flutter build appbundle --flavor prod --dart-define=APP_ENV=prod
```

Output: `build/app/outputs/bundle/{flavor}Release/app-{flavor}-release.aab`

### iOS Archive (for App Store)

```bash
# Development
flutter build ios --flavor dev --dart-define=APP_ENV=dev

# Production
flutter build ios --flavor prod --dart-define=APP_ENV=prod
```

Then in Xcode: Product → Archive → Distribute

## Firebase Emulators

```bash
# Start emulators (background)
./tools/scripts/firebase_emulators.sh start

# Check status
./tools/scripts/firebase_emulators.sh status

# View logs
./tools/scripts/firebase_emulators.sh logs

# Stop emulators
./tools/scripts/firebase_emulators.sh stop
```

UI available at: http://localhost:4005

## Environment Detection in Code

```dart
import 'package:carlet/env/env.dart';

// Check environment
if (Env.isDev) {
  // Development-only code
}

if (Env.isProd) {
  // Production-only code
}

// Check if emulators should be used
if (Env.useEmulators) {
  // This is ONLY true in dev + debug mode
}

// Get current Firebase config
FirebaseOptions options = Env.firebaseOptions;

// Log environment info
Env.logEnvironment();
```

## Package IDs

| Environment | Android Package | iOS Bundle ID |
|-------------|----------------|---------------|
| Dev | com.techolosh.carletdev | com.techolosh.carletdev |
| Prod | com.techolosh.carlet | com.techolosh.carlet |

## App Names

- Dev: "Carlet (Dev)" (shown in app drawer/home screen)
- Prod: "Carlet"

## Firebase Projects

- Dev: carlet-dev-6be6a
- Prod: carlet (to be created)

## Security Rules

### Emulator Connections

- **Dev + Debug Mode**: ✅ Auto-connects to emulators
- **Dev + Release Mode**: ❌ No emulators
- **Prod (any mode)**: ❌ No emulators (EVER)

This is enforced by `Env.useEmulators` which requires BOTH conditions:
1. `APP_ENV=dev`
2. `kDebugMode=true`

### Production Safety

The production build:
- Uses separate Firebase project
- Different package/bundle ID
- Can NEVER connect to emulators (code prevents it)
- Different app name to avoid confusion

## Testing Checklist

### Before Each Dev Build

```bash
# Start emulators if not running
./tools/scripts/firebase_emulators.sh start

# Run dev build
./tools/scripts/run_app.sh --device ios
```

### Before Production Deployment

```bash
# Run all tests
flutter test

# Check for issues
flutter analyze

# Build production locally and test
flutter build ios --flavor prod --dart-define=APP_ENV=prod
# Or
flutter build appbundle --flavor prod --dart-define=APP_ENV=prod

# Verify environment in logs
# Should see: "Environment: prod" and "Emulators: DISABLED"
```

## Troubleshooting

### "No matching client found"
- Check that `google-services.json` is in correct flavor directory
- Android dev: `android/app/src/dev/google-services.json`
- Android prod: `android/app/src/prod/google-services.json`

### Emulators not connecting in dev
- Verify emulators are running: `./tools/scripts/firebase_emulators.sh status`
- Check you're using dev build: `./tools/scripts/run_app.sh --env dev`
- Look for `Env.logEnvironment()` output in console

### Wrong Firebase project
- Check dart-defines match flavor: `--flavor dev --dart-define=APP_ENV=dev`
- Verify `APP_ENV` value in logs

### iOS build can't find GoogleService-Info.plist
- Verify `copy-firebase-config.sh` is added as build phase in Xcode
- Check it runs BEFORE "Copy Bundle Resources" phase
- Verify files exist in `ios/Runner/Dev/` and `ios/Runner/Prod/`

## Documentation

- Complete guide: `docs/FLAVOR_SYSTEM.md`
- Next steps: `docs/FLAVOR_NEXT_STEPS.md`
- iOS setup: `docs/IOS_SCHEME_SETUP.md`
- Deployment checklist: `docs/DEPLOYMENT_CHECKLIST.md`
