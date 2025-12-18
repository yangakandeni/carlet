# Firebase App Check Setup Guide

## Overview
Firebase App Check is now enabled to fix the iOS phone authentication issue. It protects your Firebase resources by verifying requests come from your legitimate app.

## The Problem (Fixed)
The error you were experiencing:
```
Swift runtime failure: Unexpectedly found nil while implicitly unwrapping an Optional value
at PhoneAuthProvider.verifyPhoneNumber
```

This occurred because Firebase Phone Authentication on iOS requires App Check to be configured in production builds.

## Solution Implemented

### 1. Added firebase_app_check Package
Added to `pubspec.yaml`:
```yaml
firebase_app_check: ^0.4.1+2
```

### 2. Initialized App Check in main.dart
- **Development (--env dev)**: Uses debug provider for easy testing
- **Production (--env prod)**: Uses DeviceCheck provider for iOS security

### 3. Configure Firebase Console (REQUIRED)

You need to register your app in the Firebase Console:

#### For iOS (Production):
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your **PRODUCTION** project
3. Go to **Build** → **App Check**
4. Click **Apps** tab
5. Find your iOS app and click **Register**
6. Select **DeviceCheck** as the provider
7. Save the configuration

#### For iOS (Debug/Development):
1. Run the app in debug mode once
2. Check the console logs for the debug token:
   ```
   [AppCheck] Debug token: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
   ```
3. In Firebase Console → App Check → Apps → iOS app
4. Click **Manage debug tokens**
5. Add the token from your logs
6. This allows testing on simulators and development builds

#### For Android (When ready):
1. In Firebase Console → App Check
2. Select your Android app
3. Choose **Play Integrity** for production
4. Or use **Debug** provider for development (similar to iOS debug flow)

## Testing the Fix

### Development Environment (with emulators):
```bash
./tools/scripts/run_app.sh --env dev --device YOUR_DEVICE_ID
```
- Uses debug provider
- No Firebase Console setup needed initially
- Debug token may need to be registered if verification fails

### Production Environment (your current issue):
```bash
./tools/scripts/run_app.sh --env prod --device 00008110-001601CA0E81801E
```
- Uses DeviceCheck provider
- **Requires Firebase Console setup** (step 3 above)
- Phone authentication will work after setup

## Important Notes

1. **DeviceCheck vs App Attest**:
   - DeviceCheck: Works on iOS 11+
   - App Attest: More secure, requires iOS 14+
   - We're using DeviceCheck for broader compatibility

2. **Debug Tokens**:
   - Debug tokens are temporary and for development only
   - Each device/simulator may need its own debug token
   - Production builds don't use debug tokens

3. **Play Integrity (Android)**:
   - Only needed when you start testing on Android
   - Requires app to be uploaded to Play Console (internal testing track works)

## Verification

After setup, you should see in logs:
```
[AppCheck] Firebase App Check activated (PRODUCTION mode)
[AUTH] Starting phone verification for: +27...
[AUTH] Code sent, verificationId: ...
```

No more Swift runtime errors! 🎉

## Troubleshooting

### Issue: Still getting nil pointer error
**Solution**: Make sure you've registered your iOS app in Firebase Console → App Check → DeviceCheck

### Issue: "App Check token is invalid"
**Solution**: 
- For debug builds: Register the debug token shown in console logs
- For production: Verify DeviceCheck is properly configured

### Issue: Works on simulator but not device
**Solution**: Physical devices and simulators may need separate debug tokens registered in development

## References
- [Firebase App Check Documentation](https://firebase.google.com/docs/app-check)
- [iOS DeviceCheck Setup](https://firebase.google.com/docs/app-check/ios/devicecheck-provider)
- [Android Play Integrity](https://firebase.google.com/docs/app-check/android/play-integrity-provider)
