# Returning User Data Preservation Fix

## Overview
This document describes the fix for a critical bug where returning users' name and email fields were being set to null after signing in, completed on December 21, 2024.

## Problem Description

### Issue
When a returning user (who had successfully completed onboarding with their name and optionally their email) signed out and then signed back in via phone OTP:
1. The onboarding screen was correctly skipped (as expected)
2. However, their profile showed empty name and email fields
3. This also occurred after updating name/email on the profile screen, signing out, and signing back in

### Root Cause
The bug was in the `AuthService._ensureUserDoc()` method:

```dart
// BUGGY CODE
final data = <String, dynamic>{
  'name': user.displayName,      // ❌ null for phone auth
  'email': user.email,           // ❌ null for phone auth
  'phoneNumber': user.phoneNumber,
  'photoUrl': user.photoURL,     // ❌ null for phone auth
};
await ref.set(data, SetOptions(merge: true));
```

**Why this was problematic:**
1. **Phone Authentication Limitation**: Firebase Auth's phone authentication does not store `displayName`, `email`, or `photoURL` - these properties are `null` for phone auth users
2. **Overwriting Existing Data**: Even with `SetOptions(merge: true)`, explicitly setting a field to `null` overwrites the existing value in Firestore
3. **Data Loss**: Every time a returning user signed in, their carefully entered name and email were overwritten with `null`

### Impact
- **User Experience**: Returning users saw blank profile information
- **Data Integrity**: User data was being lost on each sign-in
- **Trust**: Users might think the app lost their data or had synchronization issues

## Solution

### Fix Strategy
The fix implements a two-path approach in `_ensureUserDoc()`:

#### Path 1: Returning Users with Completed Onboarding
```dart
// For returning users, don't overwrite existing data
if (existingDoc.exists && existingDoc.data()?['onboardingComplete'] == true) {
  // Only update phone number if it changed
  if (user.phoneNumber != null) {
    await ref.set({
      'phoneNumber': user.phoneNumber,
    }, SetOptions(merge: true));
  }
  // Return existing user data without modification
  return appUser;
}
```

**Benefits:**
- ✅ Preserves name, email, and all other existing user data
- ✅ Still updates phone number if it changed (important for security)
- ✅ No data loss for returning users

#### Path 2: New Users or Incomplete Onboarding
```dart
// For new users, initialize document with available data
final data = <String, dynamic>{};

// Only set fields if they have values (not null)
if (user.displayName != null) data['name'] = user.displayName;
if (user.email != null) data['email'] = user.email;
if (user.phoneNumber != null) data['phoneNumber'] = user.phoneNumber;
if (user.photoURL != null) data['photoUrl'] = user.photoURL;

// Set onboardingComplete to false for new users
if (!existingDoc.exists || existingDoc.data()?['onboardingComplete'] == null) {
  data['onboardingComplete'] = false;
}

await ref.set(data, SetOptions(merge: true));
```

**Benefits:**
- ✅ Doesn't write null values unnecessarily
- ✅ Properly initializes new user documents
- ✅ Handles edge cases where Firebase Auth might have some data

### Key Improvements

1. **Early Return for Returning Users**
   - Detects completed onboarding status
   - Skips data overwriting entirely
   - Only updates what needs updating (phone number)

2. **Conditional Field Setting**
   - Only includes fields in the update map if they're not null
   - Prevents accidental null overwrites
   - More defensive programming

3. **Clear Logic Separation**
   - Returning users: preserve data
   - New users: initialize properly
   - No confusion between the two scenarios

## Testing

### Test Coverage
Created `test/returning_user_data_preservation_test.dart` with documentation test.

### Manual Testing Scenarios

#### Scenario 1: Returning User After Sign Out
1. **Setup**: User completes onboarding with name "John Doe" and email "john@example.com"
2. **Action**: User signs out, then signs back in with phone OTP
3. **Expected Result**: Profile shows "John Doe" and "john@example.com" ✅
4. **Previous Bug**: Profile showed empty name and email ❌

#### Scenario 2: Profile Update Then Sign Out/In
1. **Setup**: User updates name to "Jane Smith" and email to "jane@example.com"
2. **Action**: User saves changes, signs out, signs back in
3. **Expected Result**: Profile shows "Jane Smith" and "jane@example.com" ✅
4. **Previous Bug**: Profile showed empty name and email ❌

#### Scenario 3: New User First Sign In
1. **Setup**: New user signs in for the first time via phone
2. **Action**: Complete phone verification
3. **Expected Result**: 
   - Onboarding screen shows ✅
   - User can enter name, email, and vehicle info ✅
   - Fields are empty (no pre-filled data) ✅

#### Scenario 4: Phone Number Change
1. **Setup**: Returning user with existing profile data
2. **Action**: Updates phone number via profile settings
3. **Expected Result**:
   - Phone number updated ✅
   - Name and email preserved ✅
   - All other data preserved ✅

### Test Results
All 24 tests passing ✅

## Edge Cases Handled

### 1. User Without Name/Email (Valid State)
**Scenario**: Some users might not have entered email (optional field)

**Handling**: 
- Null values are valid for optional fields
- The fix doesn't force these to have values
- Only preserves what exists

### 2. First-Time Sign In
**Scenario**: Brand new user, no existing Firestore document

**Handling**:
- Creates document with `onboardingComplete: false`
- Only writes non-null Firebase Auth data
- User proceeds to onboarding flow

### 3. Partial Onboarding
**Scenario**: User started onboarding but didn't complete it

**Handling**:
- Document exists but `onboardingComplete != true`
- Treated as new user
- Can update with any available Firebase Auth data
- Still directed to complete onboarding

### 4. Phone Number Update Mid-Session
**Scenario**: User updates phone number while signed in

**Handling**:
- Handled separately by `confirmPhoneUpdate()` method
- Uses explicit merge to update only phone number
- Not affected by this fix

## Data Flow

### Before Fix (Buggy)
```
1. User signs in via phone → Firebase Auth User created
2. Firebase Auth User properties:
   - uid: "abc123"
   - phoneNumber: "+1234567890"
   - displayName: null
   - email: null
   
3. _ensureUserDoc() called
4. Firestore update:
   {
     "name": null,           ← Overwrites existing "John Doe"
     "email": null,          ← Overwrites existing "john@example.com"  
     "phoneNumber": "+1234567890",
     "photoUrl": null
   }
   
5. Result: Data lost! ❌
```

### After Fix (Working)
```
1. User signs in via phone → Firebase Auth User created
2. Firebase Auth User properties:
   - uid: "abc123"
   - phoneNumber: "+1234567890"
   - displayName: null
   - email: null
   
3. _ensureUserDoc() called
4. Check: onboardingComplete == true?
   YES → Preserve existing data path
   
5. Firestore update (minimal):
   {
     "phoneNumber": "+1234567890"  ← Only update what changed
   }
   
6. Existing data preserved:
   - name: "John Doe" ✅
   - email: "john@example.com" ✅
   - carPlate: "ABC123" ✅
   
7. Result: Data intact! ✅
```

## Related Code

### Files Modified
- `lib/services/auth_service.dart` - `_ensureUserDoc()` method

### Files Created
- `test/returning_user_data_preservation_test.dart` - Documentation test
- `docs/RETURNING_USER_DATA_FIX.md` - This document

### Related Methods (Not Modified)
- `updateProfile()` - Still works correctly for explicit updates
- `confirmPhoneUpdate()` - Still works correctly for phone changes
- `completeOnboarding()` - Still works correctly for first-time setup

## Migration Notes

### Existing Users
- **No migration needed**: The fix is backward compatible
- Existing users will have their data preserved on next sign-in
- Users who lost data can re-enter it on the profile screen

### Data Recovery
- Users who experienced data loss can simply re-enter their name/email
- The data will now be properly preserved
- Consider sending a notification to affected users

## Future Considerations

### Possible Enhancements

1. **Firebase Auth Profile Sync**
   - Consider syncing profile updates back to Firebase Auth
   - Would require updating `displayName` and `photoURL` in Firebase Auth
   - Not critical since we store canonical data in Firestore

2. **Profile Completeness Validation**
   - Add validation to ensure name is always set
   - Make email required or clearly mark as optional
   - Prompt users to complete profile if fields are missing

3. **Data Audit Trail**
   - Log when profile fields are updated
   - Track sign-in events and data changes
   - Help identify and debug future data issues

4. **Optimistic Updates**
   - Consider caching user data locally
   - Reduce need to fetch from Firestore on every sign-in
   - Improve app startup performance

## Lessons Learned

1. **Phone Auth Limitations**: Phone authentication doesn't provide profile data - design accordingly
2. **Merge Semantics**: `SetOptions(merge: true)` with null values still overwrites
3. **State Differentiation**: Always distinguish between new users and returning users
4. **Defensive Programming**: Don't write data you don't have
5. **Test Edge Cases**: Test the full user lifecycle, not just happy path

## Related Documentation
- `docs/SELF_REPORT_PREVENTION.md` - Recent feature implementation
- `docs/FIRESTORE_RULES_UPDATE.md` - Security rules updates
- `docs/LIKES_COMMENTS_FEATURE.md` - Social features implementation
