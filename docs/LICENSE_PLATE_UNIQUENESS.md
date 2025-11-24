# License Plate Uniqueness Implementation

## Overview
This feature ensures that each license plate number can only be registered to one user account during onboarding. This prevents data integrity issues and maintains the security principle that users cannot report their own vehicles.

## Implementation Details

### Changes Made

#### 1. `lib/services/auth_service.dart`
- Modified `completeOnboarding()` method to check for duplicate license plates
- Added Firestore query to search for existing plates before saving:
  ```dart
  final existingPlateQuery = await _db
      .collection('users')
      .where('carPlate', isEqualTo: normalizedPlate)
      .limit(1)
      .get();
  ```
- Throws exception if plate is already registered to another user
- Normalization: Plates are stored in uppercase without spaces (e.g., "ABC 123" → "ABC123")

#### 2. `lib/screens/auth/onboarding_screen.dart`
- Enhanced error handling in `_submit()` method
- Detects duplicate plate errors and displays user-friendly message
- Error message: "This license plate is already registered. Please verify your plate number."
- Shows error both as snackbar and inline error container

#### 3. `test/onboarding_widget_test.dart`
- Added `simulateDuplicatePlate` flag to MockAuthService
- Created new test case: "error path: shows duplicate plate error"
- Verifies that duplicate plate errors are properly displayed and prevent onboarding

## How It Works

1. **User Input**: User enters license plate during onboarding (e.g., "ABC 123")
2. **Normalization**: Plate is normalized to uppercase without spaces ("ABC123")
3. **Uniqueness Check**: System queries Firestore users collection for existing plate
4. **Validation**:
   - If no match found: Proceed with registration
   - If match found for different user: Throw exception
   - If match found for same user: Allow (handles retry scenarios)
5. **Error Display**: Show specific error message if duplicate detected

## Benefits

1. **Data Integrity**: Ensures one license plate = one user
2. **Security**: Complements self-report prevention (users can't report own cars)
3. **User Experience**: Clear error message helps users identify typos
4. **Fraud Prevention**: Prevents account creation with duplicate plates

## Edge Cases Handled

- **Normalization**: Handles different input formats (spaces, case)
- **Same User Retry**: Allows same user to retry with same plate (e.g., if onboarding interrupted)
- **Empty Plates**: Handled by existing validation (required field)
- **Special Characters**: Plate validation already enforces South African format

## Testing

All tests pass (4/4):
- ✅ Happy path: successful onboarding
- ✅ Already onboarded: redirects to home
- ✅ Write failure: shows generic error
- ✅ Duplicate plate: shows specific error

## Future Considerations

1. **Firestore Index**: Add index on `carPlate` field for query performance
2. **Bulk Import**: Consider uniqueness check for admin bulk user imports
3. **Plate Updates**: Currently vehicle details cannot be changed after onboarding
4. **Analytics**: Track duplicate plate attempts for fraud detection

## Related Features

- Self-report prevention in `create_report_screen.dart`
- License plate validation in `plate_utils.dart`
- Photo requirement for report verification
