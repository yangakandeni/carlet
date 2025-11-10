# Self-Report Prevention Feature

## Overview
This document describes the implementation of the self-report prevention feature, which prevents users from reporting their own vehicles, completed on December 21, 2024.

## Feature Requirement
Users must not be able to report their own car - i.e., the license plate entered in the report form must not match the license plate on their profile.

## Implementation

### 1. Client-Side Validation

#### Location
`lib/screens/report/create_report_screen.dart` - `_submit()` method

#### Logic
Before creating a report, the system performs the following checks:

1. **Normalize License Plates**: Both the user's car plate and the entered license plate are normalized:
   - Converted to uppercase
   - Spaces removed
   
2. **Comparison**: The normalized plates are compared for exact match

3. **Action**: If they match, the report is rejected with an error message

#### Code
```dart
// Check if user is trying to report their own car
if (user?.carPlate != null && user!.carPlate!.isNotEmpty) {
  final normalizedUserPlate = user.carPlate!.toUpperCase().replaceAll(' ', '');
  final normalizedInputPlate = plateText.toUpperCase().replaceAll(' ', '');
  
  if (normalizedUserPlate == normalizedInputPlate) {
    final friendly = 'You cannot report your own vehicle.';
    AppSnackbar.showError(context, friendly);
    setState(() {
      _error = friendly;
      _loading = false;
    });
    return;
  }
}
```

#### User Experience
- User enters a license plate that matches their own
- Clicks "Post alert" button
- Receives immediate feedback: "You cannot report your own vehicle."
- Error message displayed both as a snackbar and in-form text
- Form remains filled, allowing user to correct the plate number

### 2. Server-Side Validation

#### Location
`firestore.rules` - Reports collection create rule

#### Logic
The Firestore security rules provide an additional layer of protection:

1. **Check if license plate is provided** in the report
2. **Check if user has a car plate** in their profile
3. **Compare normalized versions** (lowercase, spaces removed)
4. **Reject if they match**

#### Rule
```javascript
allow create: if request.auth != null &&
  request.resource.data.reporterId == request.auth.uid &&
  request.resource.data.keys().hasAll(['reporterId','status','timestamp']) &&
  request.resource.data.status == 'open' &&
  // Prevent users from reporting their own car
  (
    !request.resource.data.keys().hasAny(['licensePlate']) ||
    !get(/databases/$(database)/documents/users/$(request.auth.uid)).data.keys().hasAny(['carPlate']) ||
    (
      request.resource.data.licensePlate.toLowerCase().replace(' ', '') != 
      get(/databases/$(database)/documents/users/$(request.auth.uid)).data.carPlate.toLowerCase().replace(' ', '')
    )
  );
```

#### Protection Level
This rule provides defense-in-depth:
- Even if client-side validation is bypassed
- Even if a malicious client sends a direct Firestore request
- The report will be rejected at the database level

### 3. Normalization Strategy

Both client and server use the same normalization approach:

**Client-Side**: `toUpperCase().replaceAll(' ', '')`
**Server-Side**: `toLowerCase().replace(' ', '')`

Both approaches are equivalent for comparison purposes:
- Case-insensitive matching
- Space-agnostic matching

#### Examples of Matching Plates
All of these variations would be detected as the same plate:
- `ABC123` = `abc123` = `ABC 123` = `abc 123` = `A BC 123`
- `XYZ789` = `xyz789` = `XYZ 789` = `xyz 789` = `X YZ 789`

## Edge Cases Handled

### 1. User Without Car Plate
**Scenario**: User has not completed onboarding or doesn't have a car plate registered

**Behavior**: User can report any license plate (no comparison possible)

**Reason**: Users without registered vehicles can still report others' cars

### 2. Empty License Plate Field
**Scenario**: User tries to submit without entering a license plate

**Behavior**: Existing validation catches this first ("Please enter the vehicle license plate.")

**Priority**: Empty field validation runs before self-report check

### 3. Report Without License Plate
**Scenario**: Report is created without a licensePlate field (optional field)

**Behavior**: Both client and server allow this (no comparison needed)

**Note**: Current UI requires license plate, but system is flexible

### 4. Case Variations
**Scenario**: User enters "abc123" but their plate is "ABC123"

**Behavior**: Detected as match due to normalization

**Test Coverage**: Verified in test case "case insensitive and space handling"

### 5. Space Variations
**Scenario**: User enters "ABC 123" but their plate is "ABC123"

**Behavior**: Detected as match due to space removal

**Test Coverage**: Verified in test case "case insensitive and space handling"

## Testing

### Test File
`test/self_report_prevention_test.dart`

### Test Cases

1. **User cannot report their own car - exact match**
   - User plate: `ABC123`
   - Entered plate: `ABC123`
   - Expected: Report rejected with error message

2. **User cannot report their own car - case insensitive and space handling**
   - User plate: `ABC123`
   - Entered plate: `abc 123`
   - Expected: Report rejected (normalized plates match)

3. **User can report a different car**
   - User plate: `ABC123`
   - Entered plate: `XYZ789`
   - Expected: Report created successfully

4. **User without car plate can report any car**
   - User plate: `null` or empty
   - Entered plate: `ABC123`
   - Expected: Report created successfully (no comparison possible)

### Test Results
All 4 tests pass ✅

### Total Test Suite
23 tests passing (19 original + 4 new)

## Security Considerations

### Defense in Depth
The feature implements two layers of protection:

1. **Client-Side**: Fast feedback, better UX
2. **Server-Side**: Security guarantee, prevents bypass

### Why Both Layers?

**Client-Side Benefits**:
- Immediate user feedback
- No wasted network requests
- Better user experience
- Reduces server load

**Server-Side Benefits**:
- Cannot be bypassed by malicious clients
- Protects against API misuse
- Ensures data integrity
- Required for security compliance

### Potential Vulnerabilities (Mitigated)

❌ **Client-only validation**: Could be bypassed
✅ **Mitigation**: Server-side rules enforce the policy

❌ **Direct Firestore write**: Could skip app logic
✅ **Mitigation**: Security rules apply to all writes

❌ **Case/space variations**: Could evade simple comparison
✅ **Mitigation**: Normalization handles all variations

## Future Enhancements

### Possible Improvements

1. **Partial Plate Matching**
   - Detect similar plates (e.g., ABC123 vs ABD123)
   - Warn user of potential typo

2. **Historical Check**
   - Prevent reporting plates user has owned in the past
   - Check against profile history

3. **Family Vehicles**
   - Allow users to register multiple vehicles
   - Check against all registered plates

4. **Admin Override**
   - Allow admins to report any vehicle
   - Special permission for moderation

5. **Analytics**
   - Track how often users attempt self-reports
   - Identify potential confusion or UX issues

## User Communication

### Error Message
**Text**: "You cannot report your own vehicle."

**Tone**: Clear, direct, non-judgmental

**Display**: 
- Snackbar notification (dismissible)
- In-form error text (persistent until form changes)

### Help Text (Future)
Consider adding proactive help text:
- Tooltip on license plate field
- Info icon with explanation
- Help center article

## Related Files

### Modified
- `lib/screens/report/create_report_screen.dart` - Client-side validation
- `firestore.rules` - Server-side validation rules

### Created
- `test/self_report_prevention_test.dart` - Comprehensive test coverage
- `docs/SELF_REPORT_PREVENTION.md` - This document

## Related Documentation
- `docs/LIKES_COMMENTS_FEATURE.md` - Social features implementation
- `docs/FIRESTORE_RULES_UPDATE.md` - Security rules documentation
- `docs/LOCATION_REMOVAL_REFACTOR.md` - Previous refactor
