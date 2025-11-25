# 🚀 Carlet Deployment Checklist

**Last Updated:** November 24, 2025  
**App Version:** 1.0.0+1  
**Status:** Ready for deployment preparation

---

## 📋 Overview

This checklist ensures your app is ready for submission to Apple App Store and Google Play Store. Work through each section systematically.

---

## ✅ COMPLETED (Automated Fixes Applied)

### Code Quality & Security
- [x] iOS permission descriptions added (`NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`)
- [x] iOS bundle identifier corrected (`com.techolosh.carletdev`)
- [x] Firebase Storage rules secured (authentication required, file size limits, image validation)
- [x] App version updated to 1.0.0+1
- [x] Android app label capitalized to "Carlet"
- [x] Network security config documented with warnings
- [x] All unit tests passing (53/53)

---

## 🔴 CRITICAL - Must Complete Before Submission

### iOS App Store

#### 1. Apple Developer Account Setup
- [ ] Active Apple Developer Program membership ($99/year)
- [ ] App ID created in Apple Developer Portal
  - Bundle ID: `com.techolosh.carletdev`
  - Capabilities: Push Notifications, Background Modes
- [ ] Provisioning profiles created (Development & Distribution)

#### 2. Xcode Signing Configuration
- [ ] Open `ios/Runner.xcworkspace` in Xcode
- [ ] Select your Development Team in Signing & Capabilities
- [ ] Update `DEVELOPMENT_TEAM` in `project.pbxproj` if needed
- [ ] Verify signing for all configurations (Debug, Release, Profile)
- [ ] Test archive build: Product → Archive

#### 3. API Key Security
- [ ] **CRITICAL:** Rotate Google Maps API key exposed in `ios/Runner/Info.plist`
  - Current key: `AIzaSyA9gO0qGZdMVZcTxFB3hKbcWSo8QGy0WJE` (EXPOSED IN REPO)
  - Create new key with iOS app restrictions
  - Update `Info.plist` with new key
  - Delete old key from Google Cloud Console
- [ ] Remove hardcoded Firebase keys from public repo history

#### 4. App Store Connect Setup
- [ ] App created in App Store Connect
- [ ] App Store listing completed:
  - Name: "Carlet - Car Alerts" (or similar)
  - Subtitle: 48 characters max
  - Description: Up to 4000 characters
  - Keywords: 100 characters max
  - Support URL
  - Marketing URL (optional)
- [ ] Screenshots prepared (6.5", 5.5" iPhone sizes required)
- [ ] App icon 1024x1024 uploaded
- [ ] Privacy policy URL provided
- [ ] Age rating completed (likely 4+)
- [ ] Contact information provided

### Android Play Store

#### 1. Google Play Console Account
- [ ] Active Google Play Developer account ($25 one-time fee)
- [ ] App created in Play Console
- [ ] Package name: `com.techolosh.carletdev`

#### 2. Release Signing **CRITICAL**
- [ ] Follow `docs/ANDROID_RELEASE_SIGNING.md` guide
- [ ] Create release keystore (`.jks` file)
- [ ] Backup keystore securely (1Password, encrypted drive)
- [ ] Store passwords in password manager
- [ ] Create `android/key.properties` (gitignored)
- [ ] Update `android/app/build.gradle.kts`:
  - Remove debug signing from release build
  - Add release signing configuration
  - Enable ProGuard/R8 obfuscation
- [ ] Create `android/app/proguard-rules.pro`
- [ ] Test release build: `flutter build appbundle --release`
- [ ] Verify signing: `jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab`

#### 3. Play Console Setup
- [ ] Store listing completed:
  - App name: "Carlet"
  - Short description: 80 characters max
  - Full description: Up to 4000 characters
  - Icon: 512x512 PNG
  - Feature graphic: 1024x500 JPG/PNG
  - Phone screenshots: 2-8 required
  - 7" tablet screenshots: Optional but recommended
- [ ] Privacy policy URL provided
- [ ] Content rating questionnaire completed
- [ ] Target audience selected
- [ ] App category: Navigation or Auto & Vehicles

---

## ⚠️ HIGH PRIORITY - Complete Before Launch

### Firebase & Backend

#### 1. Production Environment
- [ ] Create separate Firebase project for production
  - Project ID: `carlet-prod-xxxxx` (not `carlet-dev-6be6a`)
  - Separate iOS app: `com.techolosh.carlet` (remove "dev")
  - Separate Android app: `com.techolosh.carlet`
- [ ] Run `flutterfire configure` for production project
- [ ] Update bundle IDs to production (`com.techolosh.carlet`)
- [ ] Enable Firebase services:
  - Authentication (Phone Auth with proper SMS quotas)
  - Cloud Firestore
  - Cloud Storage
  - Cloud Messaging (FCM)
- [ ] Deploy Firebase Security Rules:
  ```bash
  firebase deploy --only firestore:rules,storage:rules
  ```
- [ ] Set up Firebase Auth SMS quotas for production scale
- [ ] Configure APNs for iOS push notifications
- [ ] Configure FCM for Android push notifications

#### 2. Cloud Functions (if using)
- [ ] Deploy functions: `cd firebase/functions && npm run deploy`
- [ ] Set up production environment variables
- [ ] Configure function scaling limits
- [ ] Set up error monitoring (Firebase Crashlytics or Sentry)

#### 3. API Keys & Secrets
- [ ] Google Maps API keys with production quotas
  - Separate keys for iOS and Android with app restrictions
  - Enable billing on Google Cloud project
  - Set usage quotas and alerts
- [ ] Firebase API keys properly configured
- [ ] No hardcoded secrets in codebase

### Legal & Compliance

#### 1. Privacy Policy **REQUIRED**
- [ ] Create comprehensive privacy policy covering:
  - What data is collected (phone number, location, photos, license plates)
  - How data is used
  - Data retention policy
  - User rights (access, deletion, modification)
  - Third-party services (Firebase, Google Maps)
  - Contact information
- [ ] Host privacy policy (GitHub Pages, your website, etc.)
- [ ] Add privacy policy link to:
  - App Store Connect
  - Google Play Console
  - App's Profile screen
  - iOS Info.plist: `NSPrivacyPolicyURL` (optional)

#### 2. Terms of Service
- [ ] Create Terms of Service covering:
  - Acceptable use policy
  - Prohibited content
  - User responsibilities
  - Liability limitations
  - Dispute resolution
- [ ] Host Terms of Service
- [ ] Link from Profile screen

#### 3. GDPR & Data Protection (if targeting EU)
- [ ] Data export functionality
- [ ] Account deletion functionality
- [ ] Cookie consent (if using web analytics)
- [ ] Data processing agreements with third parties

### App Content & Features

#### 1. Remove Development Features
- [ ] Remove or make conditional:
  - Firebase emulator connections
  - Network security cleartext config
  - Debug print statements
  - Development-only features
- [ ] Update `network_security_config.xml`:
  - Move to `android/app/src/debug/res/xml/` (debug only)
  - Or remove entirely for production

#### 2. Testing
- [ ] Comprehensive testing on real devices:
  - [ ] iOS 13, 14, 15, 16, 17 (if supporting older versions)
  - [ ] iPhone SE, iPhone 14, iPhone 15 Pro Max
  - [ ] Multiple Android devices (Samsung, Pixel, OnePlus)
  - [ ] Android 10, 11, 12, 13, 14
  - [ ] Tablet testing (iPad, Android tablet)
- [ ] Test critical flows:
  - [ ] Phone auth and OTP verification
  - [ ] Onboarding with vehicle registration
  - [ ] Create report with photo and license plate
  - [ ] Self-report prevention
  - [ ] View and comment on reports
  - [ ] Mark report as resolved
  - [ ] Push notifications
  - [ ] Profile management
  - [ ] Sign out and re-authentication
- [ ] Test edge cases:
  - [ ] Poor network conditions
  - [ ] No internet connection
  - [ ] Location permission denied
  - [ ] Camera permission denied
  - [ ] Photo library permission denied
  - [ ] Large image uploads
  - [ ] Invalid license plates
  - [ ] Concurrent updates

#### 3. Performance
- [ ] App bundle size < 150MB
- [ ] Cold start time < 3 seconds
- [ ] Smooth scrolling (60fps)
- [ ] Memory usage reasonable
- [ ] Battery usage acceptable
- [ ] No memory leaks
- [ ] Image optimization and caching

---

## 🔵 RECOMMENDED - Improve Quality

### Monitoring & Analytics

- [ ] Set up crash reporting:
  - Firebase Crashlytics
  - Or Sentry
- [ ] Set up analytics:
  - Firebase Analytics
  - Google Analytics
- [ ] Set up performance monitoring:
  - Firebase Performance Monitoring
- [ ] Error tracking and logging strategy

### Beta Testing

- [ ] TestFlight (iOS):
  - [ ] Internal testing with team
  - [ ] External testing with beta users (up to 10,000)
  - [ ] Collect feedback and iterate
- [ ] Google Play Internal Testing:
  - [ ] Internal testing track
  - [ ] Closed testing track
  - [ ] Open testing track (optional)

### App Store Optimization (ASO)

- [ ] App name optimization (searchability vs branding)
- [ ] Keyword research and optimization (iOS keywords field)
- [ ] Compelling app description with features and benefits
- [ ] Localization for target markets (if applicable)
- [ ] App preview videos (recommended)
- [ ] Compelling screenshots with captions
- [ ] Regular updates and version notes

### Code Quality

- [ ] Run static analysis: `flutter analyze`
- [ ] Check for outdated dependencies: `flutter pub outdated`
- [ ] Update dependencies to latest stable versions
- [ ] Code review by another developer
- [ ] Accessibility audit (screen readers, color contrast)
- [ ] Internationalization setup (if planning multilingual)

---

## 📱 Final Build & Submission

### iOS

#### Build
```bash
# Clean
flutter clean
flutter pub get

# Build iOS
flutter build ios --release

# Or build with Xcode
open ios/Runner.xcworkspace
# Product → Archive → Distribute App → App Store Connect
```

#### Submit
1. Upload via Xcode Organizer or Transporter
2. Wait for processing (15-60 minutes)
3. Complete App Store Connect compliance questions
4. Submit for review
5. Review typically takes 24-48 hours
6. Monitor status in App Store Connect

### Android

#### Build
```bash
# Clean
flutter clean
flutter pub get

# Build App Bundle
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

#### Submit
1. Upload AAB to Play Console
2. Fill in "What's new" release notes
3. Choose release track (Internal → Closed → Open → Production)
4. Complete review (usually within 24-48 hours)
5. Roll out to percentage or full release

---

## 📞 Post-Launch

### Monitoring
- [ ] Monitor crash reports daily for first week
- [ ] Watch user reviews and ratings
- [ ] Track key metrics (DAU, retention, engagement)
- [ ] Monitor Firebase usage and costs
- [ ] Set up alerts for API quota limits

### User Support
- [ ] Respond to user reviews (App Store, Play Store)
- [ ] Set up support email/contact form
- [ ] Create FAQ or help center
- [ ] Plan for feature requests and bug reports

### Updates
- [ ] Plan regular update cycle (bug fixes, features)
- [ ] Monitor OS beta releases for compatibility
- [ ] Keep dependencies updated (security patches)
- [ ] Prepare for major OS releases (iOS 18, Android 15)

---

## 🔗 Resources

### Documentation
- [Flutter Deployment Guide](https://docs.flutter.dev/deployment)
- [iOS App Distribution](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases)
- [Android App Publishing](https://developer.android.com/studio/publish)
- [Firebase Documentation](https://firebase.google.com/docs)

### Project Docs
- `docs/ANDROID_RELEASE_SIGNING.md` - Android signing setup
- `docs/SECURITY.md` - Secrets management
- `README.md` - Project overview and setup

### External Tools
- [App Store Connect](https://appstoreconnect.apple.com/)
- [Google Play Console](https://play.google.com/console/)
- [Firebase Console](https://console.firebase.google.com/)
- [Google Cloud Console](https://console.cloud.google.com/)

---

## 🎉 Launch Checklist Summary

**Before iOS Submission:**
- ✅ All critical iOS items completed above
- ✅ Tested on real iOS devices
- ✅ Privacy policy live and linked
- ✅ Release build archived successfully
- ✅ Screenshots and metadata ready

**Before Android Submission:**
- ✅ Release signing configured and tested
- ✅ All critical Android items completed above
- ✅ Tested on real Android devices
- ✅ Privacy policy live and linked
- ✅ App bundle built and verified

**Both Platforms:**
- ✅ Production Firebase project set up
- ✅ All API keys secured and production-ready
- ✅ All tests passing
- ✅ Legal documents in place
- ✅ Monitoring and analytics configured
- ✅ Team prepared for post-launch support

---

**Good luck with your launch! 🚀**
