# iOS Scheme Setup Guide

This guide explains how to set up Dev and Prod schemes in Xcode for flavor-based builds.

## Overview

The app uses two schemes/configurations:
- **Dev**: Development environment with bundle ID `com.techolosh.carletdev`
- **Prod**: Production environment with bundle ID `com.techolosh.carlet`

## Automated Setup (Recommended)

Run the setup script from the project root:

```bash
cd ios
./setup_ios_schemes.sh
```

This script will:
1. Duplicate the Release configuration to create Dev-Release and Prod-Release
2. Update bundle identifiers for each configuration
3. Add a build phase to copy the correct GoogleService-Info.plist
4. Create schemes for Dev and Prod

## Manual Setup (If Needed)

If the automated script doesn't work, follow these steps in Xcode:

### 1. Open Project in Xcode

```bash
open ios/Runner.xcworkspace
```

### 2. Create Build Configurations

1. Select the **Runner** project in the Project Navigator
2. Select the **Runner** project (not target) under PROJECT
3. Go to the **Info** tab
4. Under **Configurations**, duplicate existing configurations:
   - Duplicate **Debug** → Rename to **Dev-Debug**
   - Duplicate **Release** → Rename to **Dev-Release**
   - Duplicate **Debug** → Rename to **Prod-Debug**  
   - Duplicate **Release** → Rename to **Prod-Release**
   - Duplicate **Profile** → Rename to **Dev-Profile** (optional)
   - Duplicate **Profile** → Rename to **Prod-Profile** (optional)

### 3. Configure Bundle Identifiers

1. Select the **Runner** target (under TARGETS)
2. Go to the **Build Settings** tab
3. Search for "Product Bundle Identifier"
4. Expand **Product Bundle Identifier** and set for each configuration:
   - **Dev-Debug**: `com.techolosh.carletdev`
   - **Dev-Release**: `com.techolosh.carletdev`
   - **Prod-Debug**: `com.techolosh.carlet`
   - **Prod-Release**: `com.techolosh.carlet`

### 4. Add Firebase Config Copy Build Phase

1. Select the **Runner** target
2. Go to **Build Phases** tab
3. Click **+** → **New Run Script Phase**
4. Drag this phase to run **before** "Compile Sources"
5. Rename it to "Copy Firebase Config"
6. Paste this script:

```bash
"${SRCROOT}/Runner/copy-firebase-config.sh"
```

7. Ensure "Run script only when installing" is **unchecked**

### 5. Create Schemes

#### Dev Scheme

1. Go to **Product** → **Scheme** → **Manage Schemes**
2. Click **+** to add a new scheme
3. Name: **Dev**
4. Target: **Runner**
5. Click **OK**
6. Select **Dev** scheme and click **Edit**
7. For each action (Run, Test, Profile, Analyze, Archive):
   - **Build Configuration**: Set to corresponding Dev configuration
   - Run: Dev-Debug
   - Test: Dev-Debug
   - Profile: Dev-Profile (if created)
   - Analyze: Dev-Debug
   - Archive: Dev-Release
8. Check "Shared" checkbox
9. Click **Close**

#### Prod Scheme

1. Repeat steps above but:
   - Name: **Prod**
   - Use Prod configurations (Prod-Debug, Prod-Release, etc.)

### 6. Configure Display Names

1. Select **Runner** target
2. **Build Settings** → Search for "App Display Name"
3. Set for each configuration:
   - **Dev-Debug/Release**: `Carlet (Dev)`
   - **Prod-Debug/Release**: `Carlet`

Or add to Info.plist:

```xml
<key>CFBundleDisplayName</key>
<string>$(APP_DISPLAY_NAME)</string>
```

Then in Build Settings, add User-Defined Setting:
- Name: `APP_DISPLAY_NAME`
- Dev configurations: `Carlet (Dev)`
- Prod configurations: `Carlet`

## Verification

### Check Configurations

```bash
xcodebuild -list -workspace ios/Runner.xcworkspace
```

Should show Dev and Prod schemes.

### Test Build

```bash
# Dev build
flutter build ios --flavor dev --dart-define=APP_ENV=dev

# Prod build  
flutter build ios --flavor prod --dart-define=APP_ENV=prod
```

### Verify Bundle ID

After building, check the built app's bundle ID:

```bash
# Dev
/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" \
  build/ios/iphoneos/Runner.app/Info.plist

# Should output: com.techolosh.carletdev
```

## Firebase Configuration Files

Ensure these files exist with correct content:

- `ios/Runner/Dev/GoogleService-Info.plist` - Development Firebase project
- `ios/Runner/Prod/GoogleService-Info.plist` - Production Firebase project

To generate:

```bash
# Dev (already done)
flutterfire configure --project=carlet-dev-6be6a \
  --out=lib/firebase_options.dart \
  --ios-bundle-id=com.techolosh.carletdev

# Prod (TODO: create carlet project first)
flutterfire configure --project=carlet \
  --out=lib/firebase_options_prod.dart \
  --ios-bundle-id=com.techolosh.carlet
```

Then copy the generated `ios/Runner/GoogleService-Info.plist` to the appropriate directory.

## Troubleshooting

### "GoogleService-Info.plist not found"

- Ensure files exist in `ios/Runner/Dev/` and `ios/Runner/Prod/`
- Check that copy script has execute permissions: `chmod +x ios/Runner/copy-firebase-config.sh`
- Verify build phase runs before Compile Sources

### Wrong Bundle ID in Build

- Clean build folder: **Product** → **Clean Build Folder** (Cmd+Shift+K)
- Check Product Bundle Identifier in Build Settings for the configuration
- Ensure you're building with the correct scheme

### Scheme Not Found

- Ensure schemes are marked as "Shared" in Manage Schemes
- Check `ios/Runner.xcodeproj/xcshareddata/xcschemes/` directory

### GoogleService-Info.plist Issues

- Verify the plist files are valid XML
- Check that PROJECT_ID, BUNDLE_ID, etc. match your Firebase project
- Ensure you've added the iOS app in Firebase Console with matching bundle ID

## Next Steps

After setup:

1. Test both Dev and Prod builds on simulator and device
2. Verify correct Firebase project connection
3. Test push notifications for both environments
4. Submit Prod build to TestFlight/App Store

## References

- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)
- [Xcode Build Configurations](https://developer.apple.com/documentation/xcode/build-configurations)
- [Firebase iOS Setup](https://firebase.google.com/docs/ios/setup)
