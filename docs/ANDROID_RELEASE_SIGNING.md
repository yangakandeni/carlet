# Android Release Signing Configuration

This guide walks you through setting up release signing for your Android app before submitting to the Google Play Store.

## ⚠️ IMPORTANT: Current Status

**Your app currently uses DEBUG signing for release builds** (line 50 in `android/app/build.gradle.kts`):
```kotlin
signingConfig = signingConfigs.getByName("debug")  // ⚠️ Must change for production
```

This MUST be changed before submitting to Google Play Store.

---

## Step 1: Create a Release Keystore

### Generate the Keystore

Run this command from your project root:

```bash
keytool -genkey -v -keystore ~/carlet-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias carlet-release
```

**You will be prompted for:**
- Keystore password (remember this!)
- Key password (can be same as keystore password)
- Your name, organization, etc. (this info goes into the certificate)

**CRITICAL:**
- Store the password securely (use a password manager)
- Back up the `.jks` file to a secure location (you can NEVER recover it if lost)
- If you lose this keystore, you cannot update your app on Play Store - you'll need a new app listing

### Recommended Storage

```bash
# Move keystore to a secure location
mv ~/carlet-release-key.jks ~/.android/keystores/carlet-release-key.jks

# Set proper permissions
chmod 600 ~/.android/keystores/carlet-release-key.jks
```

---

## Step 2: Configure Signing in Gradle

### Create `key.properties` File

Create `android/key.properties` (this file is gitignored):

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=carlet-release
storeFile=/Users/YOUR_USERNAME/.android/keystores/carlet-release-key.jks
```

**Security Note:** This file contains sensitive information and is already in `.gitignore`. NEVER commit it to git.

### Update `android/app/build.gradle.kts`

Add this code **before the `android {` block**:

```kotlin
// Load signing configuration from key.properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```

Then **inside the `android {` block**, add the signing configuration:

```kotlin
android {
    // ... existing config ...

    signingConfigs {
        create("release") {
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")  // ✅ Use release signing
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

---

## Step 3: Create ProGuard Rules

Create `android/app/proguard-rules.pro`:

```proguard
# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep model classes (adjust to your package)
-keep class com.techolosh.carletdev.** { *; }
```

---

## Step 4: Test the Release Build

### Build the App Bundle

```bash
flutter build appbundle --release
```

**Output location:** `build/app/outputs/bundle/release/app-release.aab`

### Verify Signing

```bash
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab
```

You should see:
```
jar verified.
```

And your certificate details (NOT "Android Debug").

### Check the Bundle

```bash
# Install bundletool
# For modern macOS:
brew install bundletool

# For older macOS (13 or earlier):
mkdir -p ~/bin
curl -L -o ~/bin/bundletool.jar https://github.com/google/bundletool/releases/download/1.17.2/bundletool-all-1.17.2.jar
# Add alias to ~/.zshrc: alias bundletool="java -jar ~/bin/bundletool.jar"

# Extract and inspect
bundletool build-apks --bundle=build/app/outputs/bundle/release/app-release.aab \
  --output=/tmp/carlet.apks \
  --mode=universal

# Install on connected device (requires device/emulator running)
# Option 1: Using bundletool (if ANDROID_HOME is set)
bundletool install-apks --apks=/tmp/carlet.apks

# Option 2: Extract and install manually
unzip -p /tmp/carlet.apks universal.apk > /tmp/carlet-universal.apk
adb install /tmp/carlet-universal.apk

# Option 3: Use Flutter (easiest)
flutter install --release
```

---

## Step 5: Pre-Flight Checklist

Before uploading to Google Play Console:

- [ ] Keystore is backed up securely
- [ ] Passwords are stored in password manager
- [ ] `key.properties` is NOT committed to git
- [ ] Release build completes without errors
- [ ] App installs and runs on physical device
- [ ] Version number is updated in `pubspec.yaml`
- [ ] App bundle size is reasonable (<150MB)
- [ ] Firebase Storage rules are secured (no wide-open access)
- [ ] Network security config is removed/conditional for release
- [ ] Google Maps API key is not in public repo
- [ ] All tests pass

---

## Step 6: Upload to Play Console

### First Time Setup

1. Go to [Google Play Console](https://play.google.com/console/)
2. Create a new app
3. Fill in store listing details
4. Upload your App Bundle to Internal Testing track first
5. Complete all required forms (privacy policy, content rating, etc.)

### Subsequent Releases

1. Increment version in `pubspec.yaml`: `version: 1.0.1+2`
2. Build: `flutter build appbundle --release`
3. Upload to appropriate track (Internal Testing → Closed Testing → Open Testing → Production)

---

## Troubleshooting

### "Could not find signing config"

Make sure `key.properties` exists and paths are absolute.

### "Wrong password"

Double-check passwords in `key.properties`. They must match what you used when creating the keystore.

### "Resource shrinking failed"

Add ProGuard rules for any libraries causing issues.

### App crashes in release but not debug

Check ProGuard rules - you may be stripping necessary code. Use `--no-shrink` temporarily to test.

---

## Team Setup

For team members to build releases:

1. **DO NOT** share the actual keystore file via git
2. **DO** share it securely (1Password, encrypted drive, etc.)
3. Each developer creates their own `android/key.properties` with the correct path
4. CI/CD should use environment variables or secret management

### CI/CD Example (GitHub Actions)

```yaml
- name: Decode keystore
  run: echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 --decode > android/app/release-key.jks

- name: Create key.properties
  run: |
    echo "storePassword=${{ secrets.KEYSTORE_PASSWORD }}" > android/key.properties
    echo "keyPassword=${{ secrets.KEY_PASSWORD }}" >> android/key.properties
    echo "keyAlias=carlet-release" >> android/key.properties
    echo "storeFile=../app/release-key.jks" >> android/key.properties
```

---

## Additional Resources

- [Official Flutter Android Deployment Guide](https://docs.flutter.dev/deployment/android)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)
- [Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756)

---

## Notes

- Google Play now uses **Play App Signing** by default - they hold the final signing key
- Your upload key (created here) is used to upload bundles
- Google re-signs with their key before distribution
- This is more secure and allows key recovery if needed
