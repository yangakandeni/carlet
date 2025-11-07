# Security & Secrets Management

This document describes how sensitive information (API keys, credentials, certificates) is managed in this project to prevent accidental leaks in source control or logs.

## Overview

- **API keys and secrets are stored in local files that are excluded from git** via `.gitignore`.
- **Templates are provided** so team members can create their own local config files.
- **Do not commit** `local.properties`, `google-services.json`, or `GoogleService-Info.plist` with real credentials.

---

## Android: Maps API Key

### Setup (one-time per developer)

1. Get your Google Maps API Key from [Google Cloud Console](https://console.cloud.google.com/google/maps-apis/credentials).
2. Open `android/local.properties` (or create it from `android/local.properties.template`).
3. Add your key:
   ```properties
   MAPS_API_KEY=YOUR_ACTUAL_KEY_HERE
   ```
4. The key is injected into `AndroidManifest.xml` at build time via Gradle (see `android/app/build.gradle.kts`).

**Why:**
- `android/local.properties` is already in `.gitignore`, so your key won't be committed.
- The hardcoded key in `AndroidManifest.xml` has been replaced with a placeholder `${MAPS_API_KEY}`.

---

## Android: Firebase `google-services.json`

### Setup (one-time per developer)

1. Download `google-services.json` from your [Firebase Console](https://console.firebase.google.com/) for the Android app.
2. Place it in one of these locations:
   - `android/app/google-services.json` (recommended for most projects)
   - `android/app/src/debug/google-services.json` (debug builds only)
   - `android/app/src/google-services.json` (all build types)

**Why:**
- `google-services.json` contains Firebase project IDs and API keys. It's listed in `.gitignore` under `**/google-services.json`.
- For local development with emulators, the `tools/scripts/run_app.sh` script can create a minimal placeholder if needed.

---

## iOS: Firebase `GoogleService-Info.plist`

### Setup (one-time per developer)

1. Download `GoogleService-Info.plist` from your [Firebase Console](https://console.firebase.google.com/) for the iOS app.
2. Place it in:
   - `ios/Runner/GoogleService-Info.plist`
   - (Optional) `macos/Runner/GoogleService-Info.plist` for macOS builds

**Why:**
- These files contain Firebase configuration including API keys.
- They are excluded from git via `.gitignore` patterns: `**/GoogleService-Info.plist` and explicit entries for `ios/Runner/` and `macos/Runner/`.

---

## CI/CD Setup

For continuous integration and deployment:

- **Do not commit real secrets** to the repository.
- Use your CI platform's secret storage (GitHub Secrets, GitLab CI variables, etc.) and inject keys at build time.
- Example GitHub Actions workflow step to inject `local.properties`:
  ```yaml
  - name: Create local.properties
    run: |
      echo "sdk.dir=$ANDROID_SDK_ROOT" >> android/local.properties
      echo "flutter.sdk=$FLUTTER_ROOT" >> android/local.properties
      echo "MAPS_API_KEY=${{ secrets.MAPS_API_KEY }}" >> android/local.properties
  ```
- For `google-services.json` / `GoogleService-Info.plist`, store base64-encoded versions in CI secrets and decode them before the build:
  ```yaml
  - name: Decode google-services.json
    run: echo "${{ secrets.GOOGLE_SERVICES_JSON_BASE64 }}" | base64 --decode > android/app/google-services.json
  ```

---

## What's in `.gitignore`

The following patterns ensure secrets never reach GitHub:

```gitignore
# Android secrets
android/local.properties
**/google-services.json

# iOS/macOS secrets
**/GoogleService-Info.plist
ios/Runner/GoogleService-Info.plist
macos/Runner/GoogleService-Info.plist
```

---

## Log Safety

- The app uses Firebase Emulators for local development (when `kDebugMode` or `APP_ENV=DEV`). Emulator endpoints are local (localhost/10.0.2.2) and don't require production credentials.
- If you see API keys in logs (e.g., Google Maps SDK logs), ensure:
  - The key is restricted in [Google Cloud Console](https://console.cloud.google.com/apis/credentials) to your app's package name and SHA-1 fingerprint.
  - You're not committing logs or `.log` files to git.

---

## Team Onboarding Checklist

When a new developer joins:

1. Copy `android/local.properties.template` to `android/local.properties` and fill in your `MAPS_API_KEY`.
2. Download and place `google-services.json` for Android and `GoogleService-Info.plist` for iOS from Firebase Console.
3. Run `flutter pub get` and `./tools/scripts/run_app.sh` to verify setup.
4. **Never commit** `local.properties`, `google-services.json`, or `GoogleService-Info.plist`.

---

## Useful Commands

- Start Firebase emulators (for local dev without production keys):
  ```bash
  ./tools/scripts/firebase_emulators.sh start
  ```
- Run the app in DEV mode (uses emulators):
  ```bash
  ./tools/scripts/run_app.sh
  ```
- Check what's ignored by git:
  ```bash
  git status --ignored
  ```

---

## Questions or Issues?

If you accidentally committed a secret:
1. **Immediately revoke/regenerate** the key in Google Cloud Console or Firebase Console.
2. Remove the secret from git history using `git filter-branch`, `BFG Repo-Cleaner`, or similar.
3. Never reuse a leaked key.

For questions on secret management, see the project README or contact the team lead.
