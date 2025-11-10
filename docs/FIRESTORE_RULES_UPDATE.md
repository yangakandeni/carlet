# Firestore Security Rules Update for Social Features

## Overview
This document describes the Firestore security rules updates made to support the likes and comments feature, completed on December 21, 2024.

## Issues Fixed

### Issue 1: Permission Denied When Liking Reports
**Error:** `[cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.`

**Cause:** Security rules didn't allow updating social engagement fields.

**Fix:** Added update path for authenticated users to modify `likeCount`, `commentCount`, and `likedBy` fields on open reports.

### Issue 2: Permission Denied When Creating Comments
**Error:** `PERMISSION_DENIED... evaluation error at L153:24 for 'update' @ L153`

**Cause:** The Comment model was serializing `timestamp` as an ISO8601 string (`timestamp.toIso8601String()`), but the security rule was checking for a Firestore Timestamp type (`request.resource.data.timestamp is timestamp`).

**Fix:** Changed `Comment.toMap()` to use `Timestamp.fromDate(timestamp)` instead of `timestamp.toIso8601String()`.

### Issue 3: RenderFlex Overflow in ReactionPickerDialog
**Error:** `A RenderFlex overflowed by 8.0 pixels on the right.` in ReactionPickerDialog Row

**Cause:** The Row with 4 reaction buttons (60px each = 240px) plus spacing was overflowing on smaller screens, especially with the 24px padding on each side of the dialog.

**Fix:** 
- Changed `Row` to `Wrap` to allow wrapping on small screens
- Reduced button size from 60x60 to 56x56 pixels
- Reduced emoji font size from 32 to 28
- Reduced dialog padding from 24 to 20 pixels
- Added explicit spacing (12px) and alignment for better control

## Changes Made

### 1. Reports Collection Updates

#### Create Rule Changes
**Before:** Required `location` field with `lat` and `lng` numbers
```javascript
allow create: if request.auth != null &&
  request.resource.data.reporterId == request.auth.uid &&
  request.resource.data.keys().hasAll(['reporterId','location','status','timestamp']) &&
  (request.resource.data.location.lat is number) &&
  (request.resource.data.location.lng is number) &&
  request.resource.data.status == 'open';
```

**After:** Removed location requirement (aligned with location removal refactor)
```javascript
allow create: if request.auth != null &&
  request.resource.data.reporterId == request.auth.uid &&
  request.resource.data.keys().hasAll(['reporterId','status','timestamp']) &&
  request.resource.data.status == 'open';
```

#### Update Rule Changes
**Before:** Only allowed vehicle owner to mark reports as resolved

**After:** Added two update paths:
1. **Vehicle owner can mark as resolved** (existing functionality)
2. **Any authenticated user can update social engagement fields** (NEW)

The new social engagement update allows:
- Updating `likeCount`, `commentCount`, and `likedBy` fields
- Only on reports with `status == 'open'` (resolved posts are read-only)
- Core fields (`reporterId`, `status`, `timestamp`, etc.) must remain unchanged
- Prevents tampering with report content while allowing social interactions

**Key constraint:** Social engagement updates are blocked on resolved reports to maintain data integrity after resolution.

### 2. Comments Collection (NEW)

Added comprehensive rules for the new `comments` collection:

#### Read Rule
```javascript
allow read: if true;
```
- Public read access (anyone can view comments)
- Aligns with the public feed design

#### Create Rule
```javascript
allow create: if request.auth != null &&
  request.resource.data.userId == request.auth.uid &&
  request.resource.data.keys().hasAll(['reportId', 'userId', 'text', 'timestamp']) &&
  request.resource.data.reportId is string &&
  request.resource.data.text is string &&
  request.resource.data.timestamp is timestamp;
```
- Authenticated users only
- Must set `userId` to their own auth UID (prevents impersonation)
- Validates presence and types of required fields
- Allows optional fields (`parentCommentId`, `userName`, `userPhotoUrl`, `reactions`)

#### Update Rule
```javascript
allow update: if request.auth != null && (
  // Can update reactions map only
  request.resource.data.keys().hasOnly(['id', 'reportId', 'userId', 'userName', 
    'userPhotoUrl', 'text', 'parentCommentId', 'reactions', 'timestamp']) &&
  request.resource.data.reportId == resource.data.reportId &&
  request.resource.data.userId == resource.data.userId &&
  request.resource.data.text == resource.data.text &&
  request.resource.data.timestamp == resource.data.timestamp &&
  (!request.resource.data.keys().hasAny(['parentCommentId']) || 
    request.resource.data.parentCommentId == resource.data.parentCommentId)
);
```
- Authenticated users only
- Allows updating the `reactions` map (any user can react to any comment)
- Core fields must remain unchanged (`text`, `userId`, `timestamp`, etc.)
- Prevents comment editing after creation (only reactions can change)

#### Delete Rule
```javascript
allow delete: if request.auth != null && 
  request.auth.uid == resource.data.userId;
```
- Only the comment author can delete their own comment
- Prevents unauthorized comment deletion

## Security Considerations

### Protection Against Abuse

1. **Like Bombing Prevention:**
   - While users can like/unlike freely, the `likedBy` array in reports prevents duplicate likes from the same user
   - Client-side logic (CommentService) manages this, but malicious users could still manipulate counts
   - Consider adding server-side validation via Cloud Functions if this becomes an issue

2. **Comment Spam:**
   - No rate limiting in security rules (requires Cloud Functions or App Check)
   - Consider implementing:
     - Comment count limit per user per report
     - Time-based throttling
     - Content length limits

3. **Reaction Spam:**
   - Users can change reactions freely
   - Each user can only have one reaction per comment (enforced in client logic)
   - Malicious users could rapidly toggle reactions to create noise

4. **Data Integrity:**
   - Core report fields are immutable during social engagement updates
   - Comment text cannot be edited after creation
   - Only comment author can delete their comments
   - Comments are cascade-deleted when report is resolved (handled by application code with emulator auth bypass)

### Recommended Enhancements

For production deployment, consider:

1. **App Check Integration:**
   ```javascript
   allow create: if request.auth != null && 
     request.auth.token.firebase.sign_in_provider != null &&
     // Add App Check validation
   ```

2. **Rate Limiting (via Cloud Functions):**
   - Limit comments per user per hour
   - Limit likes/unlikes per user per minute
   - Throttle reaction changes

3. **Content Moderation:**
   - Profanity filter for comment text
   - Report/flag system for inappropriate comments
   - Admin moderation tools

4. **Audit Logging:**
   - Track social engagement actions for abuse detection
   - Log suspicious patterns (rapid likes, spam comments)

## Testing with Emulator

The security rules work with the Firebase emulator. To test:

1. **Start emulators:**
   ```bash
   ./tools/scripts/firebase_emulators.sh start
   ```

2. **Test authenticated operations:**
   - Sign in with test user
   - Like a report (should succeed)
   - Comment on a report (should succeed)
   - Try to edit someone else's comment (should fail)

3. **Test permission denials:**
   - Try to like without authentication (should fail)
   - Try to comment on resolved report (should fail at app level)
   - Try to delete someone else's comment (should fail)

4. **Bypass rules for admin operations:**
   ```bash
   # Using insert_report.sh which includes bypass header
   ./tools/scripts/insert_report.sh --reporter-id userId --message "Test"
   ```

## Migration Notes

### Existing Data
- Old reports in Firestore may not have `likeCount`, `commentCount`, or `likedBy` fields
- The Report model defaults these to 0 or empty array in `fromMap()`
- No migration needed; fields will be added when users first interact

### Backward Compatibility
- Removed `location` field from security rules (aligns with earlier refactor)
- Old reports with location data can still be read (rules don't prevent extra fields)
- New reports cannot include location fields (validated at app level, not enforced by rules)

### Timestamp Serialization
- **Important:** Comment timestamps must be serialized as Firestore Timestamp objects, not strings
- Use `Timestamp.fromDate(dateTime)` in `toMap()` methods
- Security rules validate type with `request.resource.data.timestamp is timestamp`
- This ensures consistent timestamp handling across the platform

## Rule Validation

To validate the rules syntax:
```bash
# Rules are automatically validated when emulator starts
./tools/scripts/firebase_emulators.sh start

# Or use Firebase CLI directly
firebase deploy --only firestore:rules --project carlet-dev-6be6a
```

## Files Modified
- `firestore.rules` - Updated reports collection rules, added comments collection rules
- `lib/models/comment_model.dart` - Fixed timestamp serialization to use Firestore Timestamp type
- `lib/widgets/reaction_picker_dialog.dart` - Fixed RenderFlex overflow by using Wrap instead of Row

## Related Documentation
- `docs/LIKES_COMMENTS_FEATURE.md` - Feature implementation details
- `docs/LOCATION_REMOVAL_REFACTOR.md` - Location field removal (explains why location checks were removed)
- `docs/SECURITY.md` - General security documentation
