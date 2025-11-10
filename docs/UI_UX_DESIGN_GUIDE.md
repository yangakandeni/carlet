# Carlet - UI/UX Design Guide

**Version:** 1.0  
**Date:** November 2025  
**Purpose:** Complete design specification for creating a production-ready, aesthetically pleasing mobile app

---

## Table of Contents

1. [App Overview](#app-overview)
2. [Design Philosophy](#design-philosophy)
3. [User Journey & Flow](#user-journey--flow)
4. [Screen-by-Screen Specifications](#screen-by-screen-specifications)
5. [Color Palette & Theme](#color-palette--theme)
6. [Typography](#typography)
7. [Iconography](#iconography)
8. [Component Library](#component-library)
9. [Animations & Interactions](#animations--interactions)
10. [Accessibility Considerations](#accessibility-considerations)

---

## App Overview

**Carlet** is a community-driven mobile application that allows users to report vehicle-related alerts (e.g., "your headlights are on", "your car is blocking the driveway") to help car owners. Users can post reports with photos, license plates, and messages, and the app notifies the vehicle owner if they're registered on the platform.

### Core Features
- Phone-only authentication (OTP-based)
- Report creation with photo, license plate, and message
- Real-time feed of reports
- Social features: likes, comments, and emoji reactions
- Report resolution by car owners
- Push notifications

### Target Audience
- Urban car owners and drivers
- Community-minded individuals
- Age range: 25-55 (primary), but accessible to all
- Tech-savvy to moderate digital literacy

---

## Design Philosophy

### Design Principles

1. **Trust & Safety First**
   - Clear visual hierarchy emphasizing important information (license plates, status)
   - Professional, mature aesthetic that conveys reliability
   - Transparency in actions (anonymous vs. identified reports)

2. **Simplicity & Speed**
   - Quick report creation (3 taps: photo → plate → post)
   - Minimal cognitive load with clear CTAs
   - Single-purpose screens where possible

3. **Community & Helpfulness**
   - Warm, friendly tone without being childish
   - Positive reinforcement (success messages, thank-yous)
   - Social engagement features that feel natural, not forced

4. **Material 3 Modern**
   - Contemporary design language
   - Adaptive layouts for various screen sizes
   - System-level dark/light mode support

### Mood & Tone
- **Professional yet approachable**: Like a helpful neighbor, not a corporate app
- **Calm and reassuring**: Dealing with vehicle issues can be stressful
- **Action-oriented**: Empowers users to help others and resolve issues quickly

---

## User Journey & Flow

### Primary User Flows

#### Flow 1: New User Onboarding
```
Splash Screen → Login/Phone Input → OTP Verification → Onboarding (Profile Setup) → Home Feed
```

#### Flow 2: Returning User
```
Splash Screen → Home Feed (if onboarding complete)
```

#### Flow 3: Creating a Report
```
Home Feed → Create Report (camera/gallery) → Enter License Plate → Optional Message → Post → Success → Back to Feed
```

#### Flow 4: Engaging with Reports
```
Home Feed → View Report Card → Like/Comment → Comments Thread → Emoji Reactions → Back
```

#### Flow 5: Resolving Own Report
```
Home Feed → See Report with "Mark Resolved" Button → Confirm → Report Marked Resolved → Success Message
```

---

## Screen-by-Screen Specifications

### 1. Splash Screen

**Purpose:** Brief loading state while checking authentication status

**Visual Elements:**
- **Center Stage:** App logo (FlutterLogo placeholder currently - needs custom branding)
- **Below Logo:** Circular progress indicator
- **Background:** Solid color matching theme (surface color)

**Design Recommendations:**
- **Logo Design:** Create a custom icon that represents:
  - Cars/vehicles (subtle outline or abstract shape)
  - Community/connection (circular motif, overlapping elements)
  - Alert/notification (optional badge or highlight)
  - Colors: Primary brand color with accent highlights
  
- **Animation:** 
  - Fade in logo with slight scale animation (0.9 → 1.0)
  - Progress indicator appears after 200ms delay
  - Smooth transition to next screen (no jarring cuts)

- **Duration:** 1-2 seconds maximum (authentication check is fast)

**Key Metrics:**
- Logo size: 96dp (current) - can be larger (120-140dp)
- Spacing below logo: 16dp
- Progress indicator size: 48dp diameter

---

### 2. Login Screen (Phone Verification)

**Purpose:** Secure phone-based authentication with OTP verification

#### Phase 1: Phone Number Input

**Layout Structure:**
```
┌─────────────────────────────┐
│         [Back Button]       │  ← Hidden on first load
├─────────────────────────────┤
│                             │
│   "Login or Signup"         │  ← Headline
│   (Subtitle text)           │  ← Body text
│                             │
│   [Country Flag] [Phone]    │  ← International phone field
│                             │
│   [Get OTP Button]          │  ← Primary CTA
│                             │
│   [Error Container]         │  ← Conditional, if error
│                             │
└─────────────────────────────┘
```

**Visual Details:**

- **Header:**
  - Title: "Login or Signup" (Headline Small, ~24sp)
  - Subtitle: "We'll send you a security code to verify it's you" (Body Medium, muted)
  - Alignment: Center
  - Top padding: 32dp from bottom of AppBar

- **Phone Input Field:**
  - Component: International phone field with country picker
  - Country flag icon on left
  - Placeholder: "Phone Number"
  - Icon: Phone icon prefix
  - Border: Rounded (12dp radius)
  - Focus state: Primary color border (2dp)
  - Error state: Error color border (2dp)
  - Initial country: South Africa (ZA)
  - Helper text: None (clear design)

- **CTA Button:**
  - Label: "Get OTP" or "Sending..." (when loading)
  - Style: ElevatedButton (filled)
  - Width: Full width (minus padding)
  - Height: 48dp
  - Border radius: 12dp
  - Icon: Send icon (left) or spinner (when loading)
  - State: Disabled when loading (grayed out)

- **Error Display:**
  - Container with rounded corners (8dp)
  - Background: Error container color (light red/pink)
  - Icon: Error outline icon (left)
  - Text: Error message (Body Medium)
  - Padding: 12dp all sides
  - Margin top: 16dp

**Color & Typography:**
- Headline: onSurface, bold
- Subtitle: onSurface with 60% opacity
- Input: Standard Material 3 text field colors
- Button: primary background, onPrimary text

#### Phase 2: OTP Verification

**Layout Structure:**
```
┌─────────────────────────────┐
│    [Back Button]            │
├─────────────────────────────┤
│                             │
│   "Enter verification code" │  ← Headline
│   "We sent a code to +27..."│  ← Phone display
│                             │
│   [▢][▢][▢][▢][▢][▢]       │  ← 6-digit PIN input
│                             │
│   [Resend Code Button]      │  ← Countdown or resend
│                             │
│   [Error Container]         │  ← Conditional
│                             │
└─────────────────────────────┘
```

**Visual Details:**

- **PIN Input (Pinput):**
  - 6 individual boxes in a row
  - Each box: 56dp width × 60dp height
  - Spacing: 8dp between boxes
  - Border: outline color (default)
  - Focus: Primary color, 2dp border
  - Submitted: Primary container background, primary border
  - Error: Error color, 2dp border
  - Typography: Headline Medium (large, bold numbers)
  - Auto-focus on mount
  - SMS autofill support

- **Resend Button:**
  - Style: TextButton with icon
  - Label: "Resend code" or "Resend code in 60s" (countdown)
  - Icon: Refresh icon (left)
  - State: Disabled during countdown (gray text)
  - Countdown: Updates every second

- **Back Button Behavior:**
  - Returns to phone input
  - Clears verification state
  - Cancels countdown timer

**Micro-interactions:**
- PIN boxes: Subtle scale animation on focus (1.0 → 1.05)
- Auto-submit when 6th digit entered
- Shake animation on error
- Success checkmark animation before navigation

---

### 3. Onboarding Screen

**Purpose:** Collect user profile and vehicle information (one-time setup)

**Layout Structure:**
```
┌─────────────────────────────┐
│    [AppBar: "Welcome"]      │
├─────────────────────────────┤
│                             │
│   [Full Name Input]         │
│                             │
│   [Vehicle Input]           │
│   hint: "e.g., Toyota..."   │
│                             │
│   [License Plate Input]     │
│                             │
│   [Submit Button]           │
│                             │
│   [Info Text]               │  ← Small disclaimer
│                             │
└─────────────────────────────┘
```

**Visual Details:**

- **Form Fields:**
  - Style: Standard outlined text fields
  - Border radius: 4dp (Material default)
  - Labels: "Full name", "Vehicle", "License plate number"
  - Spacing: 12dp between fields
  - Input action: next → next → done
  - Validation: Required fields (inline error messages)

- **Vehicle Input:**
  - Hint text: "e.g., Toyota Corolla"
  - Validation: Must contain at least 2 words (make + model)
  - Error message: "Please enter both make and model"

- **Submit Button:**
  - Label: "Finish and continue"
  - Style: ElevatedButton
  - Full width
  - Height: 48dp
  - Loading state: Spinner replaces text

- **Disclaimer Text:**
  - Below button (8dp margin)
  - Body Small (12-13sp)
  - Center aligned
  - Color: onSurface with reduced opacity
  - Message: "Note: vehicle details cannot be changed after completing onboarding."

**Validation & Error Handling:**
- Real-time validation on blur
- Submit disabled until all required fields valid
- Error container (similar to login) for submission errors

**Progressive Disclosure:**
- If user returns to this screen with partial data, pre-fill fields
- If onboarding already complete, auto-redirect to Home

---

### 4. Home Screen (Feed)

**Purpose:** Main hub showing all reports, navigation to create report and profile

**Layout Structure:**
```
┌─────────────────────────────┐
│ [+] "Alerts" [Profile Icon] │  ← AppBar
├─────────────────────────────┤
│                             │
│   ┌─────────────────────┐   │
│   │ Report Card 1       │   │  ← Feed items
│   └─────────────────────┘   │
│                             │
│   ┌─────────────────────┐   │
│   │ Report Card 2       │   │
│   └─────────────────────┘   │
│                             │
│   ...                       │
│                             │
└─────────────────────────────┘
```

**AppBar Design:**

- **Leading Icon (Left):**
  - Icon: add_box_rounded (filled square with plus)
  - Size: 24dp
  - Color: onSurface (theme aware)
  - Tooltip: "Report issue"
  - Action: Navigate to Create Report

- **Title (Center):**
  - Text: "Alerts"
  - Style: Title Large
  - Color: onSurface

- **Trailing Icon (Right):**
  - If user has photo: CircleAvatar with NetworkImage
  - If no photo: CircleAvatar with initials (1-2 uppercase letters)
  - Size: 32dp diameter
  - Tooltip: "Profile"
  - Action: Navigate to Profile

**Feed Layout:**
- ListView with separation
- Padding: 12dp all sides
- Separator: 12dp spacing (SizedBox)
- Scroll physics: Standard bouncing scroll
- Pull-to-refresh: Not implemented (real-time stream)

**Empty State:**
- Center-aligned text
- Message: "No alerts yet. Be the first to report!"
- Illustration recommendation: Simple line art of a car with a speech bubble

**Error State:**
- Center-aligned text with error icon
- Message: "Failed to load reports: [error]"
- Retry button

---

### 5. Report Card Component

**Purpose:** Display individual report in feed with engagement actions

**Layout Structure:**
```
┌─────────────────────────────┐
│ ┌─────────────────────────┐ │  ← Card container
│ │                         │ │
│ │   [Photo - 16:9]        │ │  ← Optional image
│ │                         │ │
│ ├─────────────────────────┤ │
│ │ [Plate] [Status Badge]  │ │  ← Header row
│ │                         │ │
│ │ "Message text here..."  │ │  ← Report message
│ │                         │ │
│ │ [❤️ 5] [💬 2]          │ │  ← Social engagement
│ │                         │ │
│ │ "Reported: 2025-11-10"  │ │  ← Timestamp
│ │                         │ │
│ │ [Mark Resolved Button]  │ │  ← Conditional CTA
│ │                         │ │
│ │ "Will be deleted in 2h" │ │  ← Expiry hint
│ └─────────────────────────┘ │
└─────────────────────────────┘
```

**Card Container:**
- Component: Material Card with elevation
- Elevation: 1dp (subtle shadow)
- Border radius: 12dp
- Clip behavior: antiAlias (for image)
- Background: surface color

**Photo Section:**
- Aspect ratio: 16:9
- Fit: cover (fills area, may crop)
- Conditional: Only shown if photoUrl exists
- Placeholder: Gray background if image loading fails

**Header Row:**
- Flex layout: space-between
- Height: Auto (padding: 16dp)

  - **License Plate Badge:**
    - Background: primaryContainer
    - Text color: onPrimaryContainer
    - Font weight: Bold
    - Font size: 16sp
    - Padding: 10dp horizontal, 6dp vertical
    - Border radius: 6dp
    - Text: License plate (e.g., "CAA123456")

  - **Status Badge:**
    - OPEN status:
      - Background: errorContainer
      - Text color: onErrorContainer
    - RESOLVED status:
      - Background: secondaryContainer
      - Text color: onSecondaryContainer
    - Font weight: Bold
    - Font size: 12sp
    - Letter spacing: 0.5
    - Padding: 10dp horizontal, 6dp vertical
    - Border radius: 6dp
    - Text: "OPEN" or "RESOLVED"

**Message Section:**
- Padding: 16dp horizontal, 0 vertical
- Typography: Title Medium
- Font weight: 500 (medium)
- Line height: 1.4
- Color: onSurface
- Max lines: None (full message shown)

**Social Engagement Row:**
- Padding: 12dp horizontal
- Flex layout: start-aligned

  - **Like Button:**
    - InkWell with ripple effect
    - Border radius: 20dp (pill shape)
    - Icon: Heart (favorite icon)
    - Size: 20dp
    - Color: primary (active), gray (resolved)
    - Counter: Shown only if > 0
    - Spacing: 4dp between icon and count
    - Disabled if report resolved

  - **Comment Button:**
    - InkWell with ripple effect
    - Border radius: 20dp
    - Icon: Comment bubble
    - Size: 20dp
    - Color: primary (active), gray (resolved)
    - Counter: Shown only if > 0
    - Disabled if report resolved

**Timestamp:**
- Padding: 12dp horizontal
- Typography: Body Small
- Color: onSurface with reduced opacity
- Format: "Reported: YYYY-MM-DD HH:MM:SS"

**Resolve Button:**
- Conditional: Only shown if:
  - User is logged in
  - User's carPlate matches report licensePlate
  - Report status is "open"
- Component: FilledButton.icon
- Alignment: Right
- Icon: check_circle_outline
- Label: "Mark resolved"
- Background: primary
- Text color: onPrimary

**Expiry Hint:**
- Conditional: Only shown if:
  - Report status is "resolved"
  - expireAt timestamp exists
- Typography: Body Small
- Color: onSurface (muted)
- Format: "Will be deleted in Xh/Xm"

**Visual States:**
- **Default:** Full color, interactive
- **Resolved:** Muted colors, social actions disabled
- **Hover (desktop):** Subtle elevation increase
- **Press:** Slight scale down (0.98)

---

### 6. Create Report Screen

**Purpose:** Capture photo, license plate, and message to create a new report

**Layout Structure:**
```
┌─────────────────────────────┐
│ [←] "Report car"            │  ← AppBar
├─────────────────────────────┤
│                             │
│ [Take Photo] [Upload Photo] │  ← Photo buttons
│                             │
│ [Photo Preview]             │  ← Conditional
│                             │
│ [License Plate Input]       │  ← Required field
│                             │
│ [Message Input]             │  ← Optional field
│                             │
│ [☐ Post anonymously]        │  ← Toggle switch
│                             │
│ [Error Text]                │  ← Conditional
│                             │
│ [Post Alert Button]         │  ← Primary CTA
│                             │
└─────────────────────────────┘
```

**Photo Capture Section:**

- **Buttons (Row):**
  - Two equal-width OutlinedButtons
  - Spacing: 12dp between
  - Height: 48dp
  - Border radius: 4dp
  - Icon + Label layout
  
  - **Take Photo:**
    - Icon: photo_camera_outlined
    - Label: "Take photo"
    - Action: Open camera
  
  - **Upload Photo:**
    - Icon: photo_library_outlined
    - Label: "Upload photo"
    - Action: Open gallery

- **Photo Preview:**
  - Conditional: Only shown after photo selected
  - Height: 200dp
  - Fit: cover
  - Border radius: 8dp
  - Margin: 12dp vertical

**Form Fields:**

- **License Plate Input:**
  - Label: "License plate"
  - Icon: directions_car_outlined (prefix)
  - Text capitalization: CHARACTERS (auto-uppercase)
  - Border: Outlined
  - Required: Yes
  - Validation: Cannot be empty, cannot match user's own plate
  - Error: Inline below field

- **Message Input:**
  - Label: "Message (optional)"
  - Hint: "e.g. Your headlights are on"
  - Icon: message_outlined (prefix)
  - Max length: 120 characters
  - Counter: Shows remaining characters
  - Multiline: No (single line)

**Anonymous Toggle:**
- Component: SwitchListTile
- Title: "Post anonymously"
- Default: false (show user identity)
- Padding: 0 horizontal (full width)

**Submit Button:**
- Label: "Post alert"
- Icon: send (right)
- Style: ElevatedButton.icon
- Width: Full
- Height: 48dp
- Loading state: Disabled with spinner
- Disabled: If loading or validation fails

**Validation & Error Handling:**
- Pre-submit validation:
  - License plate required
  - Cannot report own car (normalized comparison)
- Inline error display (red text below submit)
- Snackbar for success/failure after submit
- Success: Close screen with `true` result
- Back navigation: Discard confirmation if fields filled

**Success Flow:**
- On successful post, pop screen with `true`
- Home screen shows "Report posted" snackbar
- Feed updates automatically (real-time stream)

---

### 7. Comments Screen

**Purpose:** Display threaded comments and allow users to reply and react

**Layout Structure:**
```
┌─────────────────────────────┐
│ [←] "Comments"              │  ← AppBar
├─────────────────────────────┤
│                             │
│   ┌─────────────────────┐   │
│   │ Comment 1           │   │
│   │ [Reactions] [Reply] │   │
│   │   ├─ Reply 1.1      │   │  ← Indented replies
│   │   └─ Reply 1.2      │   │
│   └─────────────────────┘   │
│                             │
│   ┌─────────────────────┐   │
│   │ Comment 2           │   │
│   └─────────────────────┘   │
│                             │
├─────────────────────────────┤
│ "Replying to [name]" [X]    │  ← Reply indicator (conditional)
├─────────────────────────────┤
│ [Comment Input] [Send]      │  ← Bottom input bar
└─────────────────────────────┘
```

**Comment List:**
- Padding: 12dp all sides
- Scroll: Standard ListView
- Empty state: "No comments yet. Be the first!"

**Comment Tile (Top-level):**

- **Avatar:**
  - Size: 32dp diameter (16dp radius)
  - If photo: NetworkImage in CircleAvatar
  - If no photo: Text (first letter of name)
  - Background: primaryContainer

- **User Info:**
  - Name: Body Medium, bold
  - Timestamp: Body Small, muted
  - Format: "Just now", "5m ago", "2h ago", "3d ago", or date

- **Comment Text:**
  - Typography: Body Medium
  - Color: onSurface
  - Margin top: 8dp

- **Reactions Row:**
  - If reactions exist: Pill-shaped container
  - Background: surfaceVariant
  - Padding: 8dp horizontal, 4dp vertical
  - Border radius: 12dp
  - Format: "👍 3 ❤️ 5"
  - Typography: Body Small

- **Reply Button:**
  - Style: TextButton.icon
  - Icon: reply (16dp)
  - Label: "Reply"
  - Padding: 8dp horizontal
  - Compact visual density
  - Disabled if report resolved

- **Delete Button:**
  - Conditional: Only shown if comment.userId == currentUserId
  - Icon: delete_outline (20dp)
  - Size: IconButton
  - Color: error (red)
  - Confirmation: Not implemented (instant delete)

**Reply Tiles (Nested):**
- Left margin: 32dp (indented)
- Avatar size: 28dp (14dp radius) - smaller
- Typography: Body Small (smaller than top-level)
- Same structure as top-level but more compact

**Long-press Interaction:**
- Action: Open reaction picker dialog
- Disabled if report resolved
- Haptic feedback on long-press

**Reply Indicator (Conditional):**
- Background: secondaryContainer
- Padding: 16dp horizontal, 8dp vertical
- Icon: reply (16dp)
- Text: "Replying to [userName]"
- Close button: X icon (18dp)
- Color: onSecondaryContainer

**Comment Input Bar:**
- Background: surface with shadow
- Shadow: 4dp blur, offset (0, -2), 10% opacity black
- Padding: 12dp
- SafeArea: Yes (respects notch/keyboard)

  - **Text Field:**
    - Border: OutlineInputBorder
    - Hint: "Add a comment..."
    - Content padding: 12dp horizontal, 8dp vertical
    - Max lines: null (grows with text)
    - Text input action: send
    - On submit: Post comment

  - **Send Button:**
    - IconButton.filled
    - Icon: send
    - Background: primary
    - Icon color: onPrimary
    - Size: 48dp (tappable area)

**Resolved State:**
- If report resolved:
  - Bottom bar replaced with locked message:
    - Background: surfaceVariant
    - Icon: lock_outline (18dp)
    - Text: "This post is resolved. Comments are read-only."
    - Padding: 16dp
    - Center aligned

---

### 8. Reaction Picker Dialog

**Purpose:** Allow users to add emoji reactions to comments

**Layout Structure:**
```
┌─────────────────────────────┐
│                             │
│   "React to comment"        │  ← Title
│                             │
│   😀 ❤️ 👍 🔥 😮 😢       │  ← Emoji grid
│                             │
│   [Cancel Button]           │  ← Dismiss action
│                             │
└─────────────────────────────┘
```

**Dialog Design:**
- Component: Dialog (Material 3)
- Padding: 20dp all sides
- Border radius: 28dp (large)
- Background: surface

**Title:**
- Text: "React to comment"
- Typography: Title Medium
- Center aligned
- Margin bottom: 20dp

**Emoji Grid:**
- Layout: Wrap (horizontal flow)
- Spacing: 12dp horizontal and vertical
- Alignment: Center

  - **Emoji Button:**
    - Size: 56dp circle
    - InkWell with ripple
    - Border radius: 40dp (circular)
    - Background: 
      - Selected: primaryContainer with primary border (2dp)
      - Unselected: surfaceVariant
    - Emoji: 28sp font size
    - Tap action: Select reaction, close dialog

**Available Reactions:**
- 😀 (thumbs up equivalent)
- ❤️ (heart)
- 👍 (like)
- 🔥 (fire/hot take)
- 😮 (wow)
- 😢 (sad/sympathy)

**Cancel Button:**
- Style: TextButton
- Label: "Cancel"
- Alignment: Center
- Margin top: 16dp

**Interaction:**
- Open: Long-press on comment
- Close: Tap emoji or cancel
- Effect: Adds/updates user's reaction on comment

---

### 9. Profile Screen

**Purpose:** View and edit user profile, sign out

**Layout Structure:**
```
┌─────────────────────────────┐
│ [←] "Profile"               │  ← AppBar
├─────────────────────────────┤
│                             │
│ [Full Name Input]           │
│                             │
│ [Email Input]               │
│                             │
│ ┌─────────────────────────┐ │
│ │ Phone number            │ │  ← Read-only display
│ │ +27 72 145 7788         │ │
│ │         [Update Button] │ │
│ └─────────────────────────┘ │
│                             │
│ ──────────────────────────  │  ← Divider
│                             │
│ Vehicle (read-only)         │
│ Make: Toyota                │
│ Model: Corolla              │
│ Plate: CAA123456            │
│                             │
│ [Save Button]               │
│                             │
│ [Sign Out Button]           │
│                             │
└─────────────────────────────┘
```

**Editable Fields:**

- **Full Name:**
  - Text field (outlined)
  - Border radius: 4dp
  - Label: "Full name"
  - Input action: next

- **Email:**
  - Text field (outlined)
  - Border radius: 4dp
  - Label: "Email address"
  - Hint: "Enter your email"
  - Keyboard type: emailAddress
  - Input action: done
  - Optional field

**Phone Number Section:**
- Container with border
- Border: 1dp dividerColor
- Border radius: 4dp
- Padding: 16dp
- Layout: Row with space-between

  - **Label & Value:**
    - Label: "Phone number" (Body Small, muted)
    - Value: User's phone (Body Large)
    - Spacing: 4dp vertical

  - **Update Button:**
    - Style: TextButton.icon
    - Icon: edit (18dp)
    - Label: "Update"
    - Action: Open phone update dialog

**Vehicle Section:**
- Read-only display (cannot be changed after onboarding)
- Title: "Vehicle (read-only)" with bold weight
- Margin top: 16dp after divider
- Display format:
  - Make: [value]
  - Model: [value]
  - Plate: [value]
- Typography: Body Medium
- Color: onSurface

**Action Buttons:**

- **Save Button:**
  - Style: ElevatedButton
  - Label: "Save" or CircularProgressIndicator (loading)
  - Width: Full
  - Height: 48dp
  - Margin: 24dp top
  - Action: Update name and email

- **Sign Out Button:**
  - Style: OutlinedButton.icon
  - Icon: logout
  - Label: "Sign out"
  - Width: Full
  - Height: 48dp
  - Margin: 12dp top
  - Action: Show confirmation dialog → sign out → navigate to login

**Sign Out Confirmation Dialog:**
- Title: "Sign out"
- Content: "Are you sure you want to sign out?"
- Actions:
  - Cancel (TextButton)
  - Sign out (TextButton, primary color)

---

### 10. Phone Update Dialog

**Purpose:** Change user's phone number with OTP verification

**Layout:** Similar to Phone Verification Screen but in a dialog format

**Phases:**
1. Enter new phone number
2. Receive and enter OTP
3. Confirmation and success

**Key Differences from Login Screen:**
- Dialog format (not fullscreen)
- Close button in header
- Shows current phone number for reference
- "Change number" button in OTP phase to go back
- Success closes dialog with result (no navigation)

**Design Specs:** See Login Screen specifications, adapted for dialog sizing

---

## Color Palette & Theme

### Current Theme (Material 3)
- **Seed Color:** Indigo (`Colors.indigo`)
- **Light Mode:** ColorScheme.fromSeed(seedColor: Colors.indigo)
- **Dark Mode:** ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: Brightness.dark)
- **Adaptation:** System theme mode (follows OS setting)

### Recommended Custom Palette

**Primary Brand Colors:**

```
Primary: #4A90E2 (Sky Blue)
- Conveys trust, safety, community
- Modern and approachable
- Good contrast for accessibility

Primary Dark: #2E5C8A
- Darker shade for emphasis and CTAs

Primary Light: #7AB8F5
- Lighter tint for containers and hover states
```

**Secondary Colors:**

```
Secondary: #FF9500 (Warm Orange)
- Alert/notification accent
- Attention-grabbing without being alarming
- Friendly, helpful tone

Secondary Dark: #CC7700
Secondary Light: #FFB84D
```

**Semantic Colors:**

```
Success: #34C759 (Green)
- Report resolved
- Success messages
- Positive reinforcement

Error: #FF3B30 (Red)
- Open reports (alert state)
- Form validation errors
- Critical actions

Warning: #FFD60A (Yellow)
- Caution states
- Time-sensitive info
```

**Neutral Colors:**

```
Surface: #FFFFFF (Light), #121212 (Dark)
Background: #F5F5F5 (Light), #000000 (Dark)
On Surface: #1C1C1E (Light), #FFFFFF (Dark)
Surface Variant: #E5E5EA (Light), #2C2C2E (Dark)
Outline: #C6C6C8 (Light), #48484A (Dark)
```

### Color Usage Guidelines

**License Plate Badges:**
- Background: Primary Container (light blue tint)
- Text: On Primary Container (dark blue)
- Effect: Stands out as most important info

**Status Badges:**
- OPEN: Error Container (light red) + On Error Container text
- RESOLVED: Secondary Container (light gray/green) + On Secondary Container text

**Social Actions:**
- Active: Primary color (blue)
- Disabled/Resolved: Gray (onSurface @ 40% opacity)

**Buttons:**
- Primary CTA: Filled (primary background, onPrimary text)
- Secondary: Outlined (outline border, primary text)
- Tertiary: Text button (primary text, no background)

---

## Typography

### Material 3 Type Scale

**Current:** Default Material 3 typography (Roboto on Android, SF Pro on iOS)

**Recommended Custom Font Pairing:**

**Primary Font: Inter**
- Modern, highly legible sans-serif
- Excellent for UI text at all sizes
- Good number legibility (important for license plates)
- Weights: 400 (Regular), 500 (Medium), 600 (SemiBold), 700 (Bold)

**Display Font: Poppins (Optional)**
- For headlines and app name/logo
- Friendly, rounded letterforms
- Weights: 600 (SemiBold), 700 (Bold)

### Type Hierarchy

```
Display Large (57sp, Bold)
- App logo/splash (if text-based)

Headline Large (32sp, Bold)
- Not currently used

Headline Medium (28sp, Bold)
- PIN input numbers

Headline Small (24sp, Bold)
- Screen titles in content (Login, Onboarding)

Title Large (22sp, Regular)
- AppBar titles ("Alerts", "Profile", "Comments")

Title Medium (16sp, Medium)
- Report card messages
- Comment text

Body Large (16sp, Regular)
- Standard content text
- Form inputs

Body Medium (14sp, Regular)
- Descriptions, subtitles
- Helper text

Body Small (12sp, Regular)
- Timestamps
- Captions
- Disclaimers

Label Large (14sp, Medium)
- Button text

Label Medium (12sp, Medium)
- Small button text

Label Small (11sp, Medium)
- Badges, tags
```

### Typography Usage

**License Plates:** Title Medium, Bold, All Caps
**Status Badges:** Label Small, Bold, All Caps, 0.5 letter spacing
**Report Messages:** Title Medium, Medium weight, 1.4 line height
**Comments:** Body Medium (top-level), Body Small (replies)
**Timestamps:** Body Small, muted color
**Hints/Helper Text:** Body Small, 60% opacity

---

## Iconography

### Icon Style
- **Design System:** Material Symbols (Outlined variant)
- **Weight:** Regular (400)
- **Grade:** Default (0)
- **Optical Size:** 24dp

### Key Icons

**Navigation:**
- `add_box_rounded` - Create report (filled square with plus)
- `arrow_back` - Back navigation
- `person_outline` - Profile (when no photo)
- `close` - Dismiss/cancel

**Actions:**
- `send` - Submit, post, send code
- `photo_camera_outlined` - Take photo
- `photo_library_outlined` - Upload photo
- `refresh` - Resend code
- `check_circle_outline` - Mark resolved, success
- `logout` - Sign out
- `edit` - Edit/update
- `delete_outline` - Delete comment

**Social:**
- `favorite` - Like (filled heart)
- `comment` - Comment
- `reply` - Reply to comment

**Status:**
- `error_outline` - Error state
- `lock_outline` - Locked/read-only

**Input:**
- `phone` - Phone number
- `directions_car_outlined` - Vehicle/license plate
- `message_outlined` - Message/text

**Reactions (Emoji):**
- Use Unicode emoji directly, not icon fonts:
  - ❤️, 👍, 🔥, 😮, 😢, 😀

### Icon Sizes
- **AppBar Actions:** 24dp
- **Button Icons:** 20dp (inline), 24dp (FAB)
- **Form Prefix Icons:** 24dp
- **Social Action Icons:** 20dp
- **Comment Reply Icons:** 16dp
- **Status Icons:** 18-20dp

### Icon Colors
- Default: onSurface (theme-aware)
- Active state: primary
- Disabled: onSurface @ 40% opacity
- Error: error color
- Success: success color

---

## Component Library

### Buttons

**1. Elevated Button (Primary CTA)**
- Background: primary
- Text: onPrimary
- Elevation: 1dp
- Height: 48dp
- Border radius: 12dp (custom) or 4dp (default)
- Padding: 16dp horizontal
- State changes: Elevation 3dp on hover, scale 0.98 on press
- Usage: Main actions (Get OTP, Post Alert, Save)

**2. Outlined Button (Secondary CTA)**
- Border: 1dp outline color
- Text: primary
- Background: transparent
- Height: 48dp
- Border radius: 4dp
- Usage: Secondary actions (Take Photo, Upload Photo, Sign Out)

**3. Text Button (Tertiary)**
- Text: primary
- Background: transparent
- No border
- Height: Auto (compact)
- Padding: 8dp horizontal
- Usage: Cancel, Resend, Reply

**4. Icon Button**
- Size: 48dp tappable area
- Icon: 24dp
- Ripple: Circular
- Usage: Navigation, delete, close

**5. Filled Icon Button**
- Background: primary
- Icon color: onPrimary
- Size: 48dp
- Border radius: 12dp
- Usage: Send message

### Cards

**Report Card:**
- Elevation: 1dp
- Border radius: 12dp
- Padding: 16dp (content area)
- Background: surface
- Hover: Elevation 2dp (desktop)

### Input Fields

**Standard Text Field:**
- Border: OutlineInputBorder
- Border radius: 4dp (default) or 12dp (custom)
- Border color: outline (default), primary (focused), error (invalid)
- Border width: 1dp (default), 2dp (focused/error)
- Label: Floating label (Material 3)
- Helper text: Body Small below field
- Error text: Error color, Body Small

**International Phone Field:**
- Custom component (intl_phone_field package)
- Country picker: Flag + dropdown
- Same styling as standard text field
- Digit-only input with length validation

**PIN Input:**
- Custom component (pinput package)
- 6 individual boxes
- Large, bold numbers
- Animated transitions
- Auto-focus and auto-submit

### Dialogs

**Standard Dialog:**
- Border radius: 28dp
- Padding: 24dp
- Background: surface
- Title: Title Large
- Content: Body Medium
- Actions: Row, right-aligned, 8dp spacing

**Custom Dialogs:**
- Phone Update Dialog: Scrollable content, close button in header
- Reaction Picker: Grid layout, larger touch targets

### Switches & Toggles

**SwitchListTile:**
- Title: Body Medium
- Switch: Material 3 switch (thumb + track)
- Active color: primary
- Inactive color: surfaceVariant
- Full-width tappable area

### Badges

**License Plate Badge:**
- Background: primaryContainer
- Text: onPrimaryContainer
- Padding: 10dp horizontal, 6dp vertical
- Border radius: 6dp
- Font: 16sp bold

**Status Badge:**
- Background: errorContainer (open) or secondaryContainer (resolved)
- Text: onErrorContainer / onSecondaryContainer
- Padding: 10dp horizontal, 6dp vertical
- Border radius: 6dp
- Font: 12sp bold, uppercase, 0.5 letter spacing

**Reaction Badge:**
- Background: surfaceVariant
- Text: Body Small
- Padding: 8dp horizontal, 4dp vertical
- Border radius: 12dp
- Content: Emoji + count (e.g., "❤️ 5")

### Avatars

**User Avatar:**
- Size: 32dp (standard), 28dp (small in replies), 16dp (AppBar)
- Shape: Circle
- Content: NetworkImage or initials text
- Background: primaryContainer (if no photo)
- Border: None

---

## Animations & Interactions

### Screen Transitions

**Standard Navigation:**
- Push: Slide from right (Android), cupertino (iOS)
- Pop: Slide to right
- Duration: 300ms
- Curve: easeInOut

**Modal Dialogs:**
- Fade in + scale up (0.9 → 1.0)
- Duration: 200ms
- Barrier: Semi-transparent black (50% opacity)

### Micro-interactions

**Button Press:**
- Scale down: 1.0 → 0.98
- Duration: 100ms
- Ripple effect: Material ink splash

**PIN Input:**
- Focus: Scale 1.0 → 1.05, primary border
- Error: Horizontal shake (5 cycles, ±10dp)
- Success: Check icon fade-in + scale

**Card Tap:**
- Ripple effect on press
- Optional: Subtle scale down (0.99)

**Pull-to-Refresh:**
- Not implemented (real-time stream)
- Could add: Circular progress indicator at top

**Loading States:**
- Spinner: CircularProgressIndicator
- Button: Replace text with spinner (20dp)
- Overlay: Full-screen with centered spinner + backdrop

**Social Actions:**
- Like: Heart icon pulse (scale 1.0 → 1.2 → 1.0)
- Counter: Number fade + slide up on increment

### Haptic Feedback

**Trigger Points:**
- Long-press (reaction picker)
- Error state (PIN shake)
- Success action (report posted, resolved)

**Types:**
- Light impact: Long-press
- Medium impact: Error
- Success notification: Report posted

---

## Accessibility Considerations

### Color Contrast

**WCAG AA Compliance:**
- Text: Minimum 4.5:1 contrast ratio (Body, Small)
- Large text: Minimum 3:1 contrast ratio (Headline, Title)
- Interactive elements: 3:1 contrast with background

**High Contrast Mode:**
- Test in device high-contrast settings
- Ensure borders visible on focus states
- Increase outline thickness if needed

### Typography

**Readability:**
- Minimum font size: 12sp (Small captions only)
- Standard body: 14-16sp
- Line height: 1.4-1.5 for readability
- Avoid all-caps for long text (only short badges)

**Dynamic Type:**
- Support system font scaling (iOS)
- Test at 200% text size
- Ensure layouts don't break at large sizes

### Touch Targets

**Minimum Size:**
- All interactive elements: 48dp × 48dp tappable area
- Exception: Inline icons with padding (e.g., delete in comment)

**Spacing:**
- Minimum 8dp between adjacent touch targets
- Increase to 16dp for frequently-used actions

### Screen Reader Support

**Semantic Labels:**
- All icons: Tooltip or semantic label
- Images: Alt text (photo descriptions)
- Form fields: Associated labels (not just placeholders)
- Dynamic content: Announce changes (e.g., "Report posted")

**Focus Order:**
- Logical tab order (top → bottom, left → right)
- Skip links for long feeds (future enhancement)
- Keyboard navigation: All actions accessible via keyboard

**Announcements:**
- Error messages: Auto-announced
- Success messages: Auto-announced
- Loading states: "Loading" announced

### Visual Feedback

**Focus States:**
- Clear focus indicator (2dp outline, primary color)
- Visible on all interactive elements
- High contrast in dark mode

**Loading States:**
- Skeleton screens (future enhancement)
- Progress indicators with labels
- Disable actions during loading (prevent double-submit)

**Error States:**
- Red outline on invalid fields
- Error icon + text
- Persistent until resolved
- Don't rely on color alone (use icons)

### Internationalization

**Text Expansion:**
- Allow for 30-40% text expansion (other languages)
- Avoid fixed-width containers
- Use flexible layouts (Flex, Wrap)

**RTL Support:**
- Test in RTL languages (Arabic, Hebrew)
- Mirror directional icons (back arrow)
- Flip layouts (leading/trailing, not left/right)

**Date/Time Formats:**
- Use localized formats (MM/DD vs DD/MM)
- Relative timestamps ("2h ago") in user's locale

---

## Design Assets Needed

### Brand Identity

1. **App Icon:**
   - 1024×1024 (iOS App Store)
   - Adaptive icon (Android)
   - Foreground + background layers
   - Various sizes for different contexts

2. **Logo:**
   - Horizontal lockup (full logo + wordmark)
   - Icon-only version (for splash, AppBar)
   - Light and dark variants
   - Vector format (SVG) and exported PNGs

3. **Splash Screen:**
   - Logo on solid background
   - Light and dark variants
   - Animated version (optional): Logo fade-in + scale

### Illustrations

1. **Empty States:**
   - No reports: Simple line art of car with speech bubble
   - No comments: Friendly icon or illustration
   - Error state: Broken/disconnected icon

2. **Onboarding (Optional):**
   - 3-slide carousel explaining app features
   - Illustrations: Report creation, Feed, Notifications

### Icons

1. **Custom Icons (if needed):**
   - Report status icons (beyond Material)
   - Custom badges or achievements (future)

2. **Export Sizes:**
   - 1x, 2x, 3x (iOS)
   - mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi (Android)

### Imagery

1. **Sample Photos:**
   - Car photos for testing/demo
   - Various license plate formats
   - Different lighting conditions

2. **Backgrounds (Optional):**
   - Gradient or texture for splash
   - Pattern for empty states

---

## Responsive Design

### Breakpoints

**Mobile (Primary Target):**
- Small phones: 320-375dp width
- Standard phones: 375-414dp width
- Large phones: 414-480dp width

**Tablet (Future):**
- Small tablets: 600-840dp width
- Large tablets: 840dp+ width
- Adaptive layouts: 2-column feed, side navigation

**Desktop (Web/Future):**
- 1024dp+ width
- Centered content (max-width 600dp for feed)
- Hover states for interactive elements

### Layout Adaptation

**Feed:**
- Mobile: Single column, full width
- Tablet: 2 columns, grid layout
- Desktop: Centered column, max-width constraint

**Forms:**
- Mobile: Full-width inputs, vertical stacking
- Tablet/Desktop: 2-column layout for short fields (name/email)

**Dialogs:**
- Mobile: Full-screen or near-full (with margins)
- Tablet/Desktop: Fixed width (400-500dp), centered

---

## Platform-Specific Considerations

### iOS

**Design Conventions:**
- AppBar: Centered titles (already implemented)
- Navigation: Cupertino transitions
- Form inputs: Rounded corners (12dp)
- Haptic feedback: Use `HapticFeedback.lightImpact()`
- Status bar: Light content on dark backgrounds
- Safe areas: Respect notch and home indicator

**Differences:**
- SMS autofill: Automatic (no user action)
- Phone field: May show iOS-style country picker

### Android

**Design Conventions:**
- AppBar: Centered titles (custom, default is left)
- Navigation: Material transitions
- Form inputs: Outlined style
- Haptic feedback: `HapticFeedback.vibrate()`
- Status bar: System-managed color
- Gesture navigation: Respect gesture areas

**Differences:**
- SMS autofill: Requires permission prompt
- Phone field: Material dropdown for country

---

## Performance Considerations

### Image Optimization

**Loading:**
- Lazy load images in feed (already implemented with NetworkImage)
- Placeholder: Gray background or shimmer
- Error placeholder: Broken image icon

**Size:**
- Thumbnails: 800×450 (16:9, suitable for cards)
- Full images: Max 1920×1080
- Quality: 80% JPEG compression

**Caching:**
- NetworkImage uses caching by default
- Clear cache on logout (privacy)

### Animation Performance

**60 FPS Target:**
- Use `AnimatedContainer`, `AnimatedOpacity` (implicit animations)
- Avoid animating expensive properties (shadows, blurs)
- Use `RepaintBoundary` for isolated animations

**Reduce Motion:**
- Check system "Reduce Motion" setting (accessibility)
- Disable/simplify animations if enabled
- Keep essential feedback (loading spinners)

### List Performance

**Feed Optimization:**
- ListView.builder (already implemented): Only renders visible items
- Separator builder: Efficient spacing without extra widgets
- StreamBuilder: Real-time updates without manual refresh

---

## Future Enhancements (Design Prep)

### Features Not Yet Implemented

1. **Map View:**
   - Google Maps integration showing reports as pins
   - Cluster markers for nearby reports
   - Current location indicator
   - Filter by distance radius

2. **Search & Filters:**
   - Search bar in AppBar
   - Filter by status (open/resolved)
   - Filter by date range
   - Sort options (recent, most liked)

3. **User Profiles (Public):**
   - View other users' profiles
   - Report history
   - Reputation score (helpful reports)

4. **Notifications Center:**
   - List of all notifications
   - Mark as read
   - Notification settings (mute, frequency)

5. **Report Details Page:**
   - Full-screen photo viewer
   - Map showing report location
   - More detailed timestamp info

6. **Achievements/Gamification:**
   - Badges for helpful reports
   - Community leaderboard
   - Streak tracking

7. **Report Categories:**
   - Predefined message templates ("Lights on", "Blocking driveway", "Flat tire")
   - Category icons for quick visual scanning

8. **Multi-photo Upload:**
   - Up to 5 photos per report
   - Carousel view in card
   - Thumbnail grid

---

## Design Checklist

### Before Handoff to Development

- [ ] Brand colors defined (primary, secondary, semantic)
- [ ] Typography scale documented (fonts, sizes, weights)
- [ ] Icon set selected (Material Symbols or custom)
- [ ] App icon designed (all sizes)
- [ ] Logo created (horizontal, icon-only, light/dark)
- [ ] Splash screen designed
- [ ] Empty state illustrations
- [ ] Button styles defined (primary, secondary, tertiary)
- [ ] Card styles defined (elevation, radius, padding)
- [ ] Form field styles defined (default, focused, error)
- [ ] Badge/tag styles defined
- [ ] Animation specifications (durations, curves, triggers)
- [ ] Accessibility guidelines reviewed (contrast, touch targets, labels)
- [ ] Responsive breakpoints planned (mobile, tablet, desktop)
- [ ] Platform-specific conventions noted (iOS, Android)

### During Development

- [ ] Design system implemented in theme
- [ ] Custom widgets match specifications
- [ ] Animations tested on device (60 FPS)
- [ ] Dark mode tested (all screens)
- [ ] Accessibility tested (screen reader, font scaling)
- [ ] Platform-specific builds tested (iOS, Android)
- [ ] Error states handled gracefully
- [ ] Loading states provide feedback
- [ ] Success states celebrate user actions

---

## Appendix: Design Tools & Resources

### Design Tools
- **Figma:** For UI mockups, prototypes, design system
- **Adobe Illustrator:** For logo and icon design
- **Sketch:** Alternative to Figma (Mac only)

### Prototyping
- **Figma Prototype Mode:** For interactive flows
- **Principle:** For advanced animations
- **ProtoPie:** For complex interactions

### Assets & Resources
- **Material Design 3:** https://m3.material.io/
- **Google Fonts:** https://fonts.google.com/ (Inter, Poppins)
- **Material Symbols:** https://fonts.google.com/icons
- **Unsplash:** https://unsplash.com/ (stock photos)

### Color Tools
- **Coolors:** Color palette generator
- **Material Theme Builder:** Generate M3 theme from seed color
- **WebAIM Contrast Checker:** Test WCAG compliance

### Accessibility Tools
- **Stark (Figma plugin):** Contrast checking, colorblind simulation
- **Able (Figma plugin):** Accessibility checklist
- **iOS VoiceOver, Android TalkBack:** Screen reader testing

---

## Summary

This comprehensive guide provides all the information needed to create a beautiful, modern, and accessible design for the Carlet app. The design should prioritize:

1. **Trust**: Professional, clean aesthetic that conveys safety
2. **Simplicity**: Clear hierarchy, minimal friction, obvious actions
3. **Community**: Warm, helpful tone with social features
4. **Accessibility**: Inclusive design for all users
5. **Performance**: Smooth animations, fast load times

With this guide, a UI/UX designer can create high-fidelity mockups, a comprehensive design system, and all necessary assets to bring the Carlet app to a production-ready state.

---

**End of Document**
