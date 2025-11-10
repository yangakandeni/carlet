# Onboarding Flow Fix: Returning Users

## Problem
When users signed out and signed back in, they were incorrectly being redirected to the onboarding screen even though they had already completed onboarding.

## Root Cause
The `_ensureUserDoc` method in `AuthService` was **always** setting `onboardingComplete: false` when a user signed in, even for returning users who had already completed onboarding.

### Original Code (Buggy)
```dart
Future<AppUser> _ensureUserDoc(fb.User user) async {
  final ref = _db.collection('users').doc(user.uid);
  await ref.set({
    'name': user.displayName,
    'email': user.email,
    'phoneNumber': user.phoneNumber,
    'photoUrl': user.photoURL,
    'onboardingComplete': false,  // ❌ Always set to false!
  }, SetOptions(merge: true));
  // ...
}
```

Despite using `SetOptions(merge: true)`, explicitly setting `onboardingComplete: false` would overwrite any existing `true` value.

## Solution
Modified `_ensureUserDoc` to:
1. Check if the user document already exists
2. Only set `onboardingComplete: false` if the field doesn't exist
3. Preserve the existing value for returning users

### Fixed Code
```dart
Future<AppUser> _ensureUserDoc(fb.User user) async {
  final ref = _db.collection('users').doc(user.uid);
  
  // Check if user document already exists
  final existingDoc = await ref.get();
  final data = <String, dynamic>{
    'name': user.displayName,
    'email': user.email,
    'phoneNumber': user.phoneNumber,
    'photoUrl': user.photoURL,
  };
  
  // Only set onboardingComplete to false if it doesn't exist
  if (!existingDoc.exists || existingDoc.data()?['onboardingComplete'] == null) {
    data['onboardingComplete'] = false;
  }
  
  await ref.set(data, SetOptions(merge: true));
  // ...
}
```

## Expected Behavior

### New Users (First Sign-In)
1. User completes phone verification
2. User document created with `onboardingComplete: false`
3. User redirected to `OnboardingScreen`
4. After completing onboarding: `onboardingComplete: true`
5. User redirected to `HomeScreen`

### Returning Users (Sign Out → Sign Back In)
1. User signs out
2. User signs back in with phone verification
3. `_ensureUserDoc` checks existing document
4. Sees `onboardingComplete: true` already exists
5. **Does NOT overwrite it**
6. User goes directly to `HomeScreen` ✅

## Testing
- Created `test/auth_service_returning_user_test.dart` with documentation tests
- Verify manually:
  1. Complete onboarding as a new user
  2. Sign out
  3. Sign back in
  4. Should go directly to HomeScreen (not OnboardingScreen)

## Files Modified
- `lib/services/auth_service.dart` - Fixed `_ensureUserDoc` method
- `test/auth_service_returning_user_test.dart` - Added documentation tests

## Related Code
The sign-in flow in `PhoneVerificationScreen._verifyCode` correctly checks:
```dart
if (appUser == null || appUser.onboardingComplete != true) {
  Navigator.pushReplacementNamed(context, OnboardingScreen.routeName);
} else {
  Navigator.pushReplacementNamed(context, HomeScreen.routeName);
}
```

This logic is correct - the bug was in `_ensureUserDoc` overwriting the flag.
