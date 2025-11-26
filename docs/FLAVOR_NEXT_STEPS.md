# Flavor System - Next Steps

## ✅ Completed Tasks

The flavor system implementation is **90% complete**. All code changes are done:

1. ✅ Created `lib/env/env.dart` - Central environment configuration
2. ✅ Set up Android flavors in `build.gradle.kts` (dev/prod)
3. ✅ Created iOS configuration structure (build script, directories)
4. ✅ Updated `main.dart` to use Env switcher
5. ✅ Secured emulator connections (dev-only via `Env.useEmulators`)
6. ✅ Updated `run_app.sh` script for flavor support
7. ✅ Created comprehensive documentation (`FLAVOR_SYSTEM.md`, `IOS_SCHEME_SETUP.md`)

## 🔧 Required Manual Steps (Before Production Deployment)

### 1. Configure iOS Schemes in Xcode

**Status:** ⏳ **Manual setup required** (cannot be automated)

**Instructions:** Follow `docs/IOS_SCHEME_SETUP.md`

**What to do:**
1. Open Xcode: `open ios/Runner.xcworkspace`
2. Create build configurations (Dev/Prod)
3. Set bundle identifiers per configuration
4. Add the `copy-firebase-config.sh` build phase
5. Create Dev and Prod schemes

**Time estimate:** 15-20 minutes (one-time setup)

**Can skip for now if:** You're only testing on Android or using command-line builds

### 2. Create Production Firebase Project

**Status:** ⏳ **User action required**

**What to do:**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Name it `carlet` (or your preferred production project name)
4. Add iOS app:
   - Bundle ID: `com.techolosh.carlet`
   - Download `GoogleService-Info.plist`
5. Add Android app:
   - Package name: `com.techolosh.carlet`
   - Download `google-services.json`
6. Enable required services:
   - Authentication → Phone
   - Firestore Database
   - Storage
   - Cloud Messaging (if using push notifications)

**Time estimate:** 10 minutes

**Note:** Keep dev and prod projects completely separate - never share data between them

### 3. Generate Real Production Firebase Configs

**Status:** ⏳ **User action required** (depends on step 2)

**Command to run:**
```bash
flutterfire configure \
  --project=carlet \
  --out=lib/firebase_options_prod.dart \
  --ios-bundle-id=com.techolosh.carlet \
  --android-package-name=com.techolosh.carlet
```

**What this does:**
- Replaces the placeholder `lib/firebase_options_prod.dart` with real credentials
- Ensures all platforms are configured correctly

**Then manually copy:**
- Android: `google-services.json` → `android/app/src/prod/google-services.json`
- iOS: `GoogleService-Info.plist` → `ios/Runner/Prod/GoogleService-Info.plist`

**Time estimate:** 5 minutes

### 4. Deploy Production Firestore & Storage Rules

**Status:** ⏳ **User action required** (after prod project exists)

**Commands to run:**
```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules --project carlet

# Deploy Storage rules  
firebase deploy --only storage --project carlet
```

**Files to deploy:**
- `firestore.rules` (already configured)
- `storage.rules` (already configured with 10MB limit, image-only)

**Time estimate:** 2 minutes

## 🚀 Testing the Flavor System

### Test Dev Flavor (Can do now)

```bash
# Run dev flavor with emulators
./tools/scripts/firebase_emulators.sh start
./tools/scripts/run_app.sh --env dev --device ios

# Verify in logs:
# ✅ Environment: dev
# ✅ Emulators: ENABLED
# ✅ Firebase Project: carlet-dev-6be6a
```

### Test Prod Flavor (After completing manual steps)

```bash
# Run prod flavor (NO emulators)
./tools/scripts/run_app.sh --env prod --device ios

# Verify in logs:
# ✅ Environment: prod
# ✅ Emulators: DISABLED
# ✅ Firebase Project: carlet
# ✅ Package ID: com.techolosh.carlet (not carletdev)
```

## 📦 Building Release Bundles

### Android App Bundle (Google Play)

```bash
# Production release
flutter build appbundle --flavor prod --dart-define=APP_ENV=prod

# Output: build/app/outputs/bundle/prodRelease/app-prod-release.aab
```

### iOS Archive (App Store)

```bash
# Production release
flutter build ios --flavor prod --dart-define=APP_ENV=prod

# Then in Xcode:
# 1. Select "Runner (Prod)" scheme
# 2. Product → Archive
# 3. Distribute to App Store Connect
```

## 📋 Pre-Deployment Checklist

Before submitting to app stores:

- [ ] iOS schemes configured in Xcode (step 1)
- [ ] Production Firebase project created (step 2)
- [ ] Real production configs generated (step 3)
- [ ] Production Firebase rules deployed (step 4)
- [ ] Test production build locally
- [ ] Verify no emulator connections in prod
- [ ] Check app name shows "Carlet" (not "Carlet (Dev)")
- [ ] Privacy policy accessible
- [ ] Terms of service created
- [ ] App signing configured (iOS: certificates, Android: keystore)
- [ ] Store listing assets ready (screenshots, description, etc.)

## 🎯 Development Workflow Going Forward

### Daily Development

```bash
# Just use the dev flavor (default)
./tools/scripts/run_app.sh

# Or specify device
./tools/scripts/run_app.sh --device ios
```

### Testing Production Build Locally

```bash
# Run prod flavor without deploying
./tools/scripts/run_app.sh --env prod --device ios --release
```

### Before Each Release

1. Test both dev and prod builds
2. Run all tests: `flutter test`
3. Check for lint issues: `flutter analyze`
4. Build production bundles
5. Test the production bundle on real devices

## 🆘 Need Help?

- **Flavor system guide:** `docs/FLAVOR_SYSTEM.md`
- **iOS setup guide:** `docs/IOS_SCHEME_SETUP.md`
- **Deployment checklist:** `docs/DEPLOYMENT_CHECKLIST.md`
- **Flutter docs:** https://docs.flutter.dev/deployment

## 🔮 Optional Future Enhancements

- [ ] Add staging environment (3-flavor system: dev/staging/prod)
- [ ] Environment-specific API endpoints
- [ ] CI/CD pipeline (GitHub Actions, Codemagic, etc.)
- [ ] Automated E2E tests per flavor
- [ ] Feature flags per environment

---

**Status Summary:**
- ✅ Code implementation: 100% complete
- ✅ Scripts & automation: 100% complete
- ⏳ Manual iOS setup: 0% (15 min required)
- ⏳ Production Firebase: 0% (20 min required)

**Can deploy to stores:** After completing the 4 manual steps above (est. 45 minutes total)
