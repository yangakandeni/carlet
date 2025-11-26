# Testing Guide - Dev vs Prod Builds

This guide walks through testing both development and production builds to verify the flavor system works correctly.

## Prerequisites

✅ All Firebase configs in place (dev and prod)
✅ iOS schemes configured (Dev and Prod)
✅ Android flavors configured
✅ Device or simulator available

## Quick Test Commands

### Test Dev Build

```bash
# Using the run script (recommended)
./tools/scripts/run_app.sh --env dev --device <device-id>

# Or directly with Flutter
flutter run --flavor dev --dart-define=APP_ENV=dev -d <device-id>
```

### Test Prod Build

```bash
# Using the run script (recommended)
./tools/scripts/run_app.sh --env prod --device <device-id>

# Or directly with Flutter
flutter run --flavor prod --dart-define=APP_ENV=prod -d <device-id>
```

## Comprehensive Testing Checklist

### Step 1: Test Dev Build

**Run the app:**
```bash
./tools/scripts/run_app.sh --env dev --device 00008110-001601CA0E81801E
```

**Verify in console logs:**
- [ ] `Environment: dev`
- [ ] `Emulators: ENABLED` (if debug mode and emulators running)
- [ ] `Firebase Project: carlet-dev-6be6a`
- [ ] `Package ID: com.techolosh.carletdev`

**Verify on device:**
- [ ] App name shows "Carlet (Dev)"
- [ ] App icon appears (should be the same for now)
- [ ] Can install alongside prod version (different bundle ID)

**Test Firebase connection:**
- [ ] Phone authentication works
- [ ] Can create/read Firestore data
- [ ] Can upload images to Storage
- [ ] Data appears in dev Firebase project

**Test with emulators (if available):**
```bash
# Start emulators first
./tools/scripts/firebase_emulators.sh start

# Run dev build
./tools/scripts/run_app.sh --env dev --device 00008110-001601CA0E81801E
```

- [ ] App connects to local emulators
- [ ] Auth data goes to emulator (not live Firebase)
- [ ] Firestore data visible in emulator UI (http://localhost:4005)

### Step 2: Test Prod Build

**Run the app:**
```bash
./tools/scripts/run_app.sh --env prod --device 00008110-001601CA0E81801E
```

**Verify in console logs:**
- [ ] `Environment: prod`
- [ ] `Emulators: DISABLED (production environment)`
- [ ] `Firebase Project: carlet-68fca`
- [ ] `Package ID: com.techolosh.carlet`

**Verify on device:**
- [ ] App name shows "Carlet" (no suffix)
- [ ] Can install alongside dev version
- [ ] Both apps visible on home screen

**Test Firebase connection:**
- [ ] Phone authentication works
- [ ] Can create/read Firestore data
- [ ] Can upload images to Storage
- [ ] Data appears in **production** Firebase project (carlet-68fca)
- [ ] **NEVER** connects to emulators (even if running)

**Critical security check:**
```bash
# With emulators running and prod build installed
./tools/scripts/firebase_emulators.sh start

# Run prod build
./tools/scripts/run_app.sh --env prod --device 00008110-001601CA0E81801E

# Verify logs show: "Emulators disabled - using PRODUCTION Firebase"
# Verify data does NOT appear in emulator UI
# Verify data DOES appear in production Firebase Console
```

### Step 3: Side-by-Side Testing

**Install both versions:**
```bash
# Install dev
flutter install --flavor dev --dart-define=APP_ENV=dev -d 00008110-001601CA0E81801E

# Install prod
flutter install --flavor prod --dart-define=APP_ENV=prod -d 00008110-001601CA0E81801E
```

**Verify isolation:**
- [ ] Both apps appear on device with different names
- [ ] Dev app uses dev Firebase project
- [ ] Prod app uses prod Firebase project
- [ ] No data mixing between environments
- [ ] User accounts are separate
- [ ] Auth state doesn't affect the other app

### Step 4: Build Release Bundles

**Android App Bundle (for Google Play):**
```bash
# Clean first
flutter clean

# Build prod release
flutter build appbundle --flavor prod --dart-define=APP_ENV=prod

# Verify output
ls -lh build/app/outputs/bundle/prodRelease/app-prod-release.aab

# Check size (should be ~20-40 MB)
```

**iOS Archive (for App Store):**
```bash
# Clean first
flutter clean

# Build prod release
flutter build ios --flavor prod --dart-define=APP_ENV=prod --release

# Open Xcode for archiving
open ios/Runner.xcworkspace

# In Xcode:
# 1. Select "Prod" scheme
# 2. Select "Any iOS Device (arm64)"
# 3. Product → Archive
# 4. Wait for build to complete
# 5. Organizer opens with the archive
```

**Verify bundle identifiers:**
```bash
# Android
unzip -p build/app/outputs/bundle/prodRelease/app-prod-release.aab \
  base/manifest/AndroidManifest.xml | grep -o 'package="[^"]*"'
# Should show: package="com.techolosh.carlet"

# iOS (after building)
/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" \
  build/ios/iphoneos/Runner.app/Info.plist
# Should show: com.techolosh.carlet
```

## Testing Firebase Features

### Authentication

**Dev environment:**
```bash
./tools/scripts/run_app.sh --env dev
```
1. Enter phone number
2. Verify OTP sent to emulator (or real phone if not using emulator)
3. Enter code
4. Verify user appears in Firebase Console → carlet-dev-6be6a → Authentication

**Prod environment:**
```bash
./tools/scripts/run_app.sh --env prod
```
1. Enter phone number (use different number than dev)
2. Receive real SMS with OTP
3. Enter code
4. Verify user appears in Firebase Console → carlet-68fca → Authentication

### Firestore

**Dev:**
- Create a report
- Check Firebase Console → carlet-dev-6be6a → Firestore
- Verify data exists

**Prod:**
- Create a report
- Check Firebase Console → carlet-68fca → Firestore
- Verify data exists separately from dev

### Storage

**Dev:**
- Upload an image
- Check Firebase Console → carlet-dev-6be6a → Storage
- Verify image uploaded

**Prod:**
- Upload an image
- Check Firebase Console → carlet-68fca → Storage
- Verify image uploaded separately from dev

### Push Notifications (if enabled)

**Dev:**
- Ensure FCM token is registered
- Send test notification from Firebase Console → carlet-dev-6be6a → Cloud Messaging
- Verify notification received on dev app

**Prod:**
- Ensure FCM token is registered
- Send test notification from Firebase Console → carlet-68fca → Cloud Messaging
- Verify notification received on prod app

## Performance Testing

### App Size

```bash
# Dev build
flutter build apk --flavor dev --dart-define=APP_ENV=dev --release
ls -lh build/app/outputs/flutter-apk/app-dev-release.apk

# Prod build
flutter build apk --flavor prod --dart-define=APP_ENV=prod --release
ls -lh build/app/outputs/flutter-apk/app-prod-release.apk

# Sizes should be similar (both ~20-30 MB)
```

### Startup Time

- [ ] Dev app starts in < 3 seconds
- [ ] Prod app starts in < 3 seconds
- [ ] No significant performance difference

### Memory Usage

Use Xcode Instruments or Android Studio Profiler:
- [ ] Dev build memory usage acceptable (< 200 MB)
- [ ] Prod build memory usage acceptable (< 200 MB)

## Security Verification

### Emulator Isolation

**Critical test:**
1. Start Firebase emulators: `./tools/scripts/firebase_emulators.sh start`
2. Run prod build: `./tools/scripts/run_app.sh --env prod`
3. Create test data in prod app
4. **Verify**: Data appears in production Firebase Console
5. **Verify**: Data does NOT appear in emulator UI (http://localhost:4005)
6. **Check logs**: Should show "Emulators disabled - using PRODUCTION Firebase"

### API Key Security

- [ ] Firebase API keys are in config files (normal for Firebase)
- [ ] No hardcoded secrets in code
- [ ] ProGuard/R8 enabled for Android release builds
- [ ] Code obfuscation working (check build logs)

### Bundle ID/Package Name

```bash
# Verify dev uses different ID
flutter run --flavor dev --dart-define=APP_ENV=dev
# Check console for: Package ID: com.techolosh.carletdev

# Verify prod uses correct ID
flutter run --flavor prod --dart-define=APP_ENV=prod
# Check console for: Package ID: com.techolosh.carlet
```

## Troubleshooting

### Build Fails

```bash
# Clean everything
flutter clean
cd ios && pod deintegrate && pod install && cd ..
flutter pub get

# Try again
flutter run --flavor dev --dart-define=APP_ENV=dev
```

### Wrong Firebase Project

**Check logs on startup:**
- Should see: `[ENV] Firebase project: DEVELOPMENT` or `[ENV] Firebase project: PRODUCTION`

**Verify in code:**
```dart
// In main.dart, add after Firebase.initializeApp:
debugPrint('Firebase Project: ${Env.firebaseOptions.projectId}');
```

### Emulators Connecting in Prod

**This should be impossible**, but if it happens:
1. Check console logs for `Env.logEnvironment()` output
2. Verify `APP_ENV=prod` is set in command
3. Check `lib/env/env.dart` logic
4. Verify `Env.useEmulators` returns false for prod

### Both Apps Show Same Name

- Check Xcode: Build Settings → APP_DISPLAY_NAME is set per configuration
- Check Android: `android:label="@string/app_name"` in AndroidManifest.xml
- Rebuild and reinstall

## Pre-Submission Checklist

Before submitting to app stores:

### Code Quality
- [ ] `flutter analyze` passes with no errors
- [ ] `flutter test` all tests pass
- [ ] No debug prints in production code
- [ ] Error handling implemented

### Firebase Setup
- [ ] Production Firebase project configured
- [ ] Security rules deployed
- [ ] Authentication methods enabled
- [ ] Indexes created (if needed)

### Build Verification
- [ ] Prod build uses correct Firebase project
- [ ] Prod build never connects to emulators
- [ ] Bundle IDs correct (com.techolosh.carlet)
- [ ] App name is "Carlet" (no suffix)
- [ ] App icon set correctly

### Legal & Privacy
- [ ] Privacy policy accessible
- [ ] Terms of service created
- [ ] App Store/Play Store listings ready
- [ ] Screenshots prepared

### Platform-Specific

**iOS:**
- [ ] Signing certificates configured
- [ ] Provisioning profiles set up
- [ ] TestFlight build uploaded and tested
- [ ] App Store Connect metadata complete

**Android:**
- [ ] Release signing keystore configured
- [ ] ProGuard rules tested
- [ ] Internal testing track tested
- [ ] Play Store listing complete

## Post-Deployment Monitoring

After submitting to stores:

### Firebase Console Monitoring
- Monitor Authentication → Users count
- Monitor Firestore → Usage tab
- Monitor Storage → Usage tab
- Check for errors in Crashlytics (if enabled)

### User Feedback
- Monitor store reviews
- Check support channels
- Track crash reports

### Performance
- Monitor app startup time
- Check memory usage
- Track network errors
- Monitor API response times

---

## Quick Reference

**Dev build:**
```bash
./tools/scripts/run_app.sh --env dev
```

**Prod build:**
```bash
./tools/scripts/run_app.sh --env prod
```

**Verify environment:**
- Check console for `[ENV]` logs
- Check app name on device
- Check Firebase Console for data location

**Emergency:** If prod connects to emulators, immediately:
1. Stop the emulators
2. Check `lib/env/env.dart` for logic errors
3. Rebuild with correct flags
