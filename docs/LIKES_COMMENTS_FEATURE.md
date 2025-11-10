# Likes and Comments Feature Implementation

## Overview
This document describes the implementation of the social engagement features (likes/hearts and comments with reactions) for the Carlet app, completed on December 21, 2024.

## Feature Requirements
Based on user acceptance criteria:
1. Display heart icon with like count and comment icon with comment count on reports
2. Hide counts if they are 0
3. Toggle likes by clicking the heart icon
4. Add comments with threading support (replies)
5. Long-press comments to show reaction picker with 4 reactions: 👍👎❤️😂
6. Delete all comments when a post is deleted or marked resolved
7. Disable likes and comments on resolved posts

## Implementation Details

### 1. Data Models

#### Report Model Updates (`lib/models/report_model.dart`)
Added three new fields:
- `likeCount` (int, default 0): Total number of likes
- `commentCount` (int, default 0): Total number of comments
- `likedBy` (List<String>, default []): Array of user IDs who liked the report

#### Comment Model (`lib/models/comment_model.dart`)
New model with the following structure:
- `id` (String): Unique comment ID
- `reportId` (String): Parent report ID
- `userId` (String): Author's user ID
- `userName` (String?): Author's display name
- `userPhotoUrl` (String?): Author's profile photo
- `text` (String): Comment content
- `parentCommentId` (String?): Parent comment ID for threading (null for top-level comments)
- `reactions` (Map<String, String>): Map of userId -> emoji for reactions
- `timestamp` (DateTime): When the comment was created

Computed properties:
- `isTopLevel`: True if parentCommentId is null
- `isReply`: True if parentCommentId is not null
- `reactionCounts`: Aggregated counts of each reaction emoji

Reaction options:
- `CommentReaction` enum: thumbsUp (👍), thumbsDown (👎), heart (❤️), laugh (😂)

### 2. Service Layer

#### CommentService (`lib/services/comment_service.dart`)
Provides methods for managing likes, comments, and reactions:

**Likes:**
- `toggleLike(String reportId, String userId)`: Adds or removes userId from likedBy array, updates likeCount atomically using Firestore transaction

**Comments:**
- `addComment(...)`: Creates a new comment with optional parentCommentId for replies, increments report commentCount
- `streamComments(String reportId)`: Returns real-time stream of all comments for a report
- `deleteComment(String commentId, String reportId)`: Deletes a comment and decrements commentCount
- `deleteCommentsForReport(String reportId)`: Batch deletes all comments (used when report is resolved)

**Reactions:**
- `addReaction(String commentId, String userId, CommentReaction reaction)`: Adds or toggles a reaction on a comment using Firestore transaction
- `removeReaction(String commentId, String userId)`: Removes a user's reaction from a comment

#### ReportService Updates
Added cascade delete to `markResolved()`:
- When a report is marked resolved, all comments are automatically deleted via `CommentService.deleteCommentsForReport()`

### 3. UI Components

#### ReportCard Updates (`lib/widgets/report_card.dart`)
Added social engagement row below message:
- Heart icon with like count (hidden if 0)
- Comment icon with comment count (hidden if 0)
- Click heart to toggle like
- Click comment icon to open CommentsScreen
- Greyed out and disabled on resolved posts

New callbacks:
- `onLike`: Triggered when heart is clicked
- `onComment`: Triggered when comment icon is clicked

#### CommentsScreen (`lib/screens/comments/comments_screen.dart`)
Full-featured comments interface:
- Real-time stream of comments from Firestore
- Threaded display: top-level comments with indented replies
- Comment input field at bottom (hidden on resolved posts)
- Reply functionality with "Replying to" banner
- Long-press comments to show reaction picker
- Delete button for own comments (author only)
- User avatars and names
- Relative timestamps (e.g., "5m ago", "2h ago")
- Reaction counts displayed on each comment
- Read-only banner for resolved posts

Features:
- `_CommentTile` widget handles display of comments and replies
- Reply button adds parent comment context
- Cancel button to exit reply mode
- Send button or Enter key to post comment

#### ReactionPickerDialog (`lib/widgets/reaction_picker_dialog.dart`)
Modal dialog for adding reactions:
- Shows all 4 reaction options in a row
- Highlights user's current reaction
- Click reaction to toggle it
- Automatically closes on selection
- Cancel button to dismiss

### 4. Feed Screen Integration
Updated `FeedScreen` to connect the callbacks:
- `onLike`: Calls `CommentService.toggleLike()` with current user ID
- `onComment`: Navigates to `CommentsScreen` with the report

### 5. Data Flow

**Liking a Report:**
1. User clicks heart icon in ReportCard
2. FeedScreen's onLike callback fires
3. CommentService.toggleLike() runs a transaction:
   - Reads current likedBy array
   - Adds or removes user ID
   - Updates likedBy and likeCount atomically
4. Firestore updates trigger report stream refresh
5. UI updates automatically via StreamBuilder

**Adding a Comment:**
1. User types in CommentsScreen text field and clicks send
2. CommentService.addComment() creates comment document
3. Firestore increments report's commentCount
4. Comment appears in real-time via streamComments()
5. Parent screen's comment count updates

**Adding a Reaction:**
1. User long-presses a comment
2. ReactionPickerDialog appears
3. User selects reaction emoji
4. CommentService.addReaction() runs transaction:
   - Reads current reactions map
   - Toggles user's reaction (add if new, remove if same)
   - Updates reactions map atomically
5. Comment updates in real-time
6. Reaction counts recomputed and displayed

**Marking Report Resolved:**
1. User clicks "Mark resolved" button
2. ReportService.markResolved() updates report status
3. CommentService.deleteCommentsForReport() batch deletes all comments
4. UI shows resolved state with greyed icons
5. CommentsScreen displays read-only banner

## Firestore Structure

### Reports Collection
```
/reports/{reportId}
  - likeCount: 5
  - commentCount: 12
  - likedBy: ['userId1', 'userId2', ...]
  - (other existing fields)
```

### Comments Collection
```
/comments/{commentId}
  - reportId: 'report123'
  - userId: 'user456'
  - userName: 'John Doe'
  - userPhotoUrl: 'https://...'
  - text: 'Great report!'
  - parentCommentId: null  // or commentId for replies
  - reactions: {
      'userId1': '👍',
      'userId2': '❤️'
    }
  - timestamp: DateTime
```

## Testing
- All existing tests pass (19 tests)
- No errors from `flutter analyze` (only pre-existing info-level lints)
- Feature ready for manual testing with Firebase emulators

## Usage Instructions

### For Users:
1. **Like a report:** Click the heart icon on any report card
2. **View comments:** Click the comment icon to open comments screen
3. **Add comment:** Type in the text field and click send
4. **Reply to comment:** Click "Reply" button on a comment
5. **React to comment:** Long-press any comment to show reaction picker
6. **Delete your comment:** Click trash icon on your own comments

### For Developers:
1. Comments are stored in separate `comments` collection, indexed by reportId
2. Use transactions for atomic updates to prevent race conditions
3. Resolved posts automatically disable social features (check `status == 'resolved'`)
4. CommentService handles all Firestore operations
5. UI updates in real-time via StreamBuilder

## Files Created
- `lib/models/comment_model.dart` - Comment data model with reactions
- `lib/services/comment_service.dart` - Comment and like operations
- `lib/screens/comments/comments_screen.dart` - Comments interface
- `lib/widgets/reaction_picker_dialog.dart` - Reaction selection dialog

## Files Modified
- `lib/models/report_model.dart` - Added social fields
- `lib/widgets/report_card.dart` - Added like/comment UI
- `lib/screens/feed/feed_screen.dart` - Connected callbacks
- `lib/services/report_service.dart` - Added cascade delete
- `docs/LIKES_COMMENTS_FEATURE.md` - This document

## Future Enhancements
Potential improvements:
- Notifications for likes and comments
- Comment editing
- Mention users in comments (@username)
- Rich text formatting
- Image attachments in comments
- Comment moderation/reporting
- Sort options (newest, oldest, most liked)
- Pagination for large comment threads
