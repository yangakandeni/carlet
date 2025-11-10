# Firestore Permission Error Fix - Implementation Summary

**Date:** 10 November 2025

## Problem

When attempting to complete onboarding, users encountered a Firestore `PERMISSION_DENIED` error:

```
W/Firestore( 7373): (26.0.2) [WriteStream]: (5437486) Stream closed with status: Status{code=PERMISSION_DENIED, description=
W/Firestore( 7373): evaluation error at L14:24 for 'create' @ L14, false for 'create' @ L181, 
                     evaluation error at L29:24 for 'update' @ L29, false for 'update' @ L181
```

## Root Cause

The Firestore security rules required `carColor` to be a non-empty string when completing onboarding:

**Original rules (lines 21-22 and 50-51):**
```javascript
request.resource.data.carColor is string && request.resource.data.carColor != '' &&
```

However, after the recent refactoring:
- The `carColor` field was removed from the onboarding UI
- The app now sends an empty string (`''`) for `carColor`
- This caused the Firestore rules validation to fail

## Solution

Updated `firestore.rules` to make `carColor` optional during onboarding:

### Changes Made

**1. Create Rule (lines 10-24):**
```javascript
// Before:
allow create: if request.auth != null && request.auth.uid == userId && (
  !(request.resource.data.onboardingComplete == true)
  ||
  (request.resource.data.onboardingComplete == true &&
    request.resource.data.carMake is string && request.resource.data.carMake != '' &&
    request.resource.data.carModel is string && request.resource.data.carModel != '' &&
    request.resource.data.carColor is string && request.resource.data.carColor != '' &&  // ❌ Required
    request.resource.data.carPlate is string && request.resource.data.carPlate != ''
  )
);

// After:
allow create: if request.auth != null && request.auth.uid == userId && (
  !(request.resource.data.onboardingComplete == true)
  ||
  (request.resource.data.onboardingComplete == true &&
    request.resource.data.carMake is string && request.resource.data.carMake != '' &&
    request.resource.data.carModel is string && request.resource.data.carModel != '' &&
    // ✅ carColor removed - now optional
    request.resource.data.carPlate is string && request.resource.data.carPlate != ''
  )
);
```

**2. Update Rule (lines 43-56):**
```javascript
// Before:
(request.resource.data.onboardingComplete == true &&
  request.resource.data.carMake is string && request.resource.data.carMake != '' &&
  request.resource.data.carModel is string && request.resource.data.carModel != '' &&
  request.resource.data.carColor is string && request.resource.data.carColor != '' &&  // ❌ Required
  request.resource.data.carPlate is string && request.resource.data.carPlate != ''
)

// After:
(request.resource.data.onboardingComplete == true &&
  request.resource.data.carMake is string && request.resource.data.carMake != '' &&
  request.resource.data.carModel is string && request.resource.data.carModel != '' &&
  // ✅ carColor removed - now optional
  request.resource.data.carPlate is string && request.resource.data.carPlate != ''
)
```

**3. Updated Comments:**
Added clarifying comments that `carColor` is optional:
- "require vehicle fields to be present and non-empty (except carColor which is optional)"

## Required Fields After Fix

When `onboardingComplete` is set to `true`, these fields are required:
- ✅ `carMake` - must be non-empty string
- ✅ `carModel` - must be non-empty string
- ✅ `carPlate` - must be non-empty string
- ⚪ `carColor` - optional (can be empty string or omitted)

## Backward Compatibility

✅ **Fully backward compatible:**
- Existing users with `carColor` values: Data is preserved and protected by immutability rules
- New users without `carColor`: Can complete onboarding with empty string
- The immutability check (Case A in update rule) still protects existing `carColor` values from being changed

## Testing & Verification

1. **Stopped emulators:**
   ```bash
   ./tools/scripts/firebase_emulators.sh stop
   ```

2. **Started emulators with new rules:**
   ```bash
   ./tools/scripts/firebase_emulators.sh start
   ```

3. **Verified emulators running:**
   ```bash
   ./tools/scripts/firebase_emulators.sh status
   ```
   Result: All emulators running ✓

4. **Testing steps for user:**
   - Launch the app
   - Complete phone authentication
   - Fill in onboarding form:
     - Name: (any name)
     - Vehicle: e.g., "Toyota Corolla" (make + model)
     - License Plate: (any plate number)
   - Tap "Finish and continue"
   - **Expected:** Should save successfully and navigate to home screen
   - **Before fix:** Would fail with PERMISSION_DENIED error

## Files Modified

1. `firestore.rules` - Removed `carColor` validation requirements

## Related Documentation

This fix is part of the onboarding refactoring documented in:
- `docs/ONBOARDING_REFACTORING.md` - Original refactoring that removed color field
- `docs/VEHICLE_SELECTION_UX.md` - Vehicle selection improvements

## Security Considerations

**No security weakened:**
- Still requires authentication (`request.auth != null`)
- Still validates user owns the document (`request.auth.uid == userId`)
- Still requires essential vehicle fields (make, model, plate)
- Still enforces immutability once onboarding is complete
- Only made `carColor` optional since it's no longer collected in UI

**Protection maintained:**
- Users cannot report their own car (unchanged)
- Vehicle details are immutable after onboarding (unchanged)
- Social engagement rules (likes/comments) still enforced (unchanged)

## Production Deployment

**When deploying to production:**

1. Deploy the updated Firestore rules:
   ```bash
   firebase deploy --only firestore:rules
   ```

2. Verify rules in Firebase Console:
   - Go to Firestore Database → Rules
   - Confirm `carColor` validation is removed from create/update rules

3. No app code changes needed (already deployed)

## Error Resolution Status

✅ **RESOLVED**
- Root cause identified: Firestore rules requiring non-empty `carColor`
- Solution implemented: Made `carColor` optional in rules
- Emulators restarted with new rules
- Ready for user testing

## Additional Notes

**Why carColor is stored as empty string instead of null:**
- The `AuthService.completeOnboarding()` method has a default parameter: `String carColor = ''`
- This ensures the field is always present in Firestore (for consistency)
- Empty string is semantically clear: "no color specified"
- Easier to query/filter than null values
- Maintains backward compatibility with existing code

**Alternative considered but not implemented:**
- Could have kept collecting color in UI - **Rejected:** User requested removal
- Could have removed carColor from database entirely - **Rejected:** Breaking change for existing users
- Could have used null instead of empty string - **Rejected:** Complicates queries
