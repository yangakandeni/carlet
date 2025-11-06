# Carlet (Flutter + Firebase)

A cross-platform Flutter app to notify car owners when their headlights are left on or if there is an urgent issue with their parked car.

## Features

- **Phone-only authentication** with OTP verification (no email or Google sign-in)
  - International phone number input with country picker (via `intl_phone_field`)
  - Beautiful 6-digit OTP verification UI with animations (via `pinput`)
  - SMS autofill support on iOS and Android
  - 60-second resend countdown timer
- Post alerts with photo, GPS location, license plate, and message
- Real-time feed and map of nearby alerts
- Push notifications to nearby users and direct priority alerts to the car owner
- Owners can mark reports as resolved
- Light/Dark Material 3 UI

## Prerequisites

- Flutter SDK 3.22+ with Dart 3.3+
- Xcode (for iOS), Android Studio/SDK (for Android)
- Firebase project (Auth, Firestore, Storage, Cloud Messaging enabled)
- Firebase CLI and FlutterFire CLI
- Google Maps API key (Android/iOS)

## 1) Clone and bootstrap platforms

Run in your terminal:

```bash
cd /Users/yanga/Documents/dev/projects/carlet
flutter create .
flutter pub get
```

## 2) Configure Firebase

Use FlutterFire to add iOS and Android configs (GoogleService-Info.plist / google-services.json):

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=<your-firebase-project-id> --ios-bundle-id=com.techolosh.carletdev --android-package-name=com.techolosh.carletdev
flutter pub get
```

Ensure Firebase products are enabled: **Phone Authentication** (with reCAPTCHA for web/test mode for emulators), Firestore, Storage, and Cloud Messaging.

> **Note on authentication:** This app uses **phone number authentication only** with OTP verification. Email/password and Google sign-in have been removed for simplicity.
>
> The phone auth UI includes:
>
> - International phone input with country picker and auto-formatting
> - Beautiful 6-digit PIN entry with animations and error states
> - SMS autofill support (iOS/Android automatically fill OTP when received)
> - 60-second countdown timer before allowing code resend
>
> Ensure Firebase Phone Auth is enabled in your Firebase console with proper platform configuration (APNs for iOS, SafetyNet/Play Integrity for Android).

## 3) Google Maps API keys

- Android: add your key to android/app/src/main/AndroidManifest.xml as a `<meta-data>` entry for `com.google.android.geo.API_KEY`.
- iOS: call `GMSServices.provideAPIKey("YOUR_IOS_MAPS_API_KEY")` in AppDelegate.

## 4) Run the app

### Start Firebase Emulators (for development)

```bash
# Start all emulators (Auth, Firestore, Storage)
./tools/scripts/firebase_emulators.sh start

# Check status
./tools/scripts/firebase_emulators.sh status

# View logs
./tools/scripts/firebase_emulators.sh logs

# Stop emulators
./tools/scripts/firebase_emulators.sh stop
```

The emulators are configured to bind to `0.0.0.0` so they're accessible from:
- **Local browser**: http://127.0.0.1:4005
- **Android emulator**: http://10.0.2.2:4005
- **iOS simulator**: http://127.0.0.1:4005

### Run the Flutter app

```bash
# With Firebase Emulators (recommended for development)
flutter run --dart-define=USE_EMULATORS=true --dart-define=EMULATOR_HOST=10.0.2.2

# Production Firebase (requires real phone number & SMS)
flutter run
```

### Testing Phone Authentication with Emulators

When using Firebase Auth Emulator, you can test without real SMS:
1. Enter any phone number in the app (e.g., +1 555 555 5555)
2. The emulator will show the OTP code in the logs or UI
3. Enter the code to sign in

No real SMS is sent when using emulators!

## 5) Cloud Functions (push notifications)

This repo includes a minimal Cloud Functions setup in `firebase/functions` to send:

- Direct priority alerts to the car owner (matching license plate)
- Nearby alerts to users within a small radius (based on last known location)
- Thank-you notifications when an owner resolves a report

Deploy after logging in to Firebase and initializing functions:

```bash
cd firebase/functions
npm i
npm run deploy
```

Note: For scale, consider geo-indexing (e.g., geohashes) instead of naive radius filters.

## Security Rules (example outline)

- users: users can read/write their own profile; read other users only necessary fields
- reports: anyone can create; only the plate owner can mark resolved; everyone can read

Implement strong validation in Firestore rules before going to production.

## What’s included

- `lib/` Flutter app code (screens, services, models)
- `firebase/functions` sample Cloud Functions for FCM triggers

## Troubleshooting

- **Phone authentication**: Ensure proper APNs (iOS) and SafetyNet/Play Integrity (Android) setup. For testing with emulators, enable "test phone numbers" in Firebase console or use real phone numbers with OTP delivery.
- If maps show a gray grid, verify API keys and that Maps SDK is enabled.
- If emulators are enabled and the app cannot connect on Android:
  - Ensure you're using an Android emulator (not a physical device), or set `EMULATOR_HOST` to your Mac's LAN IP.
  - Verify that the Firebase Emulators are running on the host machine.

### Start Firebase Emulators (optional)

```zsh
# Install Firebase CLI if needed
npm i -g firebase-tools

# From your Firebase project directory containing firebase.json (add one if missing)
firebase emulators:start --only auth,firestore,storage
```

- If `flutterfire configure` throws `cannot load such file -- xcodeproj (LoadError)` on macOS:
  - Ensure CocoaPods is installed: `brew install cocoapods`
  - Install the gem for your user: `gem install xcodeproj --user-install`
  - Re-run the command with gem env vars so Ruby can find the gem:

    ```zsh
    GEM_HOME="$HOME/.gem/ruby/3.4.0" GEM_PATH="$HOME/.gem/ruby/3.4.0" \
      flutterfire configure --project=<project> --platforms=android,ios
    ```

  - Optionally add the exports to your `~/.zshrc` for persistence:

    ```zsh
    echo 'export GEM_HOME="$HOME/.gem/ruby/3.4.0"' >> ~/.zshrc
    echo 'export GEM_PATH="$HOME/.gem/ruby/3.4.0"' >> ~/.zshrc
    ```
