#!/usr/bin/env bash
set -euo pipefail

# iOS Schemes Setup Script
# Automates the creation of Dev and Prod schemes for Xcode
#
# This script configures:
# - Build configurations (Dev-Debug, Dev-Release, Prod-Debug, Prod-Release)
# - Bundle identifiers per configuration
# - Display names per configuration
# - Build phase for copying Firebase config

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_PATH="$SCRIPT_DIR/Runner.xcodeproj"
PBXPROJ="$PROJECT_PATH/project.pbxproj"
SCHEMES_DIR="$PROJECT_PATH/xcshareddata/xcschemes"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🚀 iOS Schemes Setup for Carlet"
echo "================================"
echo

# Check if Xcode project exists
if [[ ! -f "$PBXPROJ" ]]; then
  echo -e "${RED}Error: Cannot find $PBXPROJ${NC}"
  echo "Run this script from the ios/ directory"
  exit 1
fi

# Check if xcodeproj command-line tool is available
if ! command -v xcodebuild &> /dev/null; then
  echo -e "${RED}Error: xcodebuild not found. Install Xcode Command Line Tools:${NC}"
  echo "  xcode-select --install"
  exit 1
fi

echo -e "${YELLOW}⚠️  IMPORTANT: This script requires manual Xcode configuration${NC}"
echo
echo "This script will guide you through the setup process, but some steps"
echo "must be completed manually in Xcode due to limitations of automated"
echo "project file editing."
echo
echo "The following must be done in Xcode:"
echo "  1. Create build configurations (Dev-Debug, Dev-Release, Prod-Debug, Prod-Release)"
echo "  2. Set bundle identifiers per configuration"
echo "  3. Add build phase to copy Firebase config"
echo "  4. Create Dev and Prod schemes"
echo
read -p "Press Enter to see detailed instructions..."
echo

cat <<'EOF'

═══════════════════════════════════════════════════════════════════
STEP 1: Open Xcode
═══════════════════════════════════════════════════════════════════

Run this command:

    open ios/Runner.xcworkspace

═══════════════════════════════════════════════════════════════════
STEP 2: Create Build Configurations
═══════════════════════════════════════════════════════════════════

1. Select "Runner" project in the Project Navigator (left sidebar)
2. Select "Runner" under PROJECT (not TARGETS)
3. Click the "Info" tab
4. Under "Configurations", click the "+" button:
   
   • Duplicate "Debug" → Rename to "Dev-Debug"
   • Duplicate "Release" → Rename to "Dev-Release"
   • Duplicate "Profile" → Rename to "Dev-Profile"
   • Duplicate "Debug" → Rename to "Prod-Debug"
   • Duplicate "Release" → Rename to "Prod-Release"
   • Duplicate "Profile" → Rename to "Prod-Profile"

   You should now have 9 configurations total (including the originals).

═══════════════════════════════════════════════════════════════════
STEP 3: Set Bundle Identifiers
═══════════════════════════════════════════════════════════════════

1. Select "Runner" under TARGETS
2. Click "Build Settings" tab
3. Search for "Product Bundle Identifier"
4. Click the disclosure triangle to expand it
5. Set values for each configuration:

   Dev-Debug:    com.techolosh.carletdev
   Dev-Release:  com.techolosh.carletdev
   Dev-Profile:  com.techolosh.carletdev
   Prod-Debug:   com.techolosh.carlet
   Prod-Release: com.techolosh.carlet
   Prod-Profile: com.techolosh.carlet

═══════════════════════════════════════════════════════════════════
STEP 4: Set Display Names
═══════════════════════════════════════════════════════════════════

1. Still in "Build Settings" tab
2. Click "+" → "Add User-Defined Setting"
3. Name it: APP_DISPLAY_NAME
4. Set values:
   
   Dev-Debug:    Carlet (Dev)
   Dev-Release:  Carlet (Dev)
   Dev-Profile:  Carlet (Dev)
   Prod-Debug:   Carlet
   Prod-Release: Carlet
   Prod-Profile: Carlet

5. Open Info.plist (in Runner folder)
6. Find "Bundle display name" or add it if missing
7. Set value to: $(APP_DISPLAY_NAME)

═══════════════════════════════════════════════════════════════════
STEP 5: Add Firebase Config Copy Script
═══════════════════════════════════════════════════════════════════

1. Select "Runner" target
2. Click "Build Phases" tab
3. Click "+" → "New Run Script Phase"
4. Rename it to "Copy Firebase Config" (double-click the title)
5. Drag it to run BEFORE "Compile Sources"
6. Paste this script in the box:

    "${SRCROOT}/Runner/copy-firebase-config.sh"

7. Ensure "Run script only when installing" is UNCHECKED
8. Leave "Based on dependency analysis" UNCHECKED

═══════════════════════════════════════════════════════════════════
STEP 6: Create Dev Scheme
═══════════════════════════════════════════════════════════════════

1. Go to Product → Scheme → Manage Schemes
2. Click "+" to add a new scheme
3. Name: Dev
4. Target: Runner
5. Click "OK"
6. Select "Dev" and click "Edit"
7. Set configurations for each action:
   
   Run:     Dev-Debug
   Test:    Dev-Debug
   Profile: Dev-Profile
   Analyze: Dev-Debug
   Archive: Dev-Release

8. Check "Shared" checkbox at the bottom
9. Click "Close"

═══════════════════════════════════════════════════════════════════
STEP 7: Create Prod Scheme
═══════════════════════════════════════════════════════════════════

1. Repeat Step 6, but:
   - Name: Prod
   - Use Prod configurations:
     Run:     Prod-Debug
     Test:    Prod-Debug
     Profile: Prod-Profile
     Analyze: Prod-Debug
     Archive: Prod-Release

2. Check "Shared" checkbox
3. Click "Close"

═══════════════════════════════════════════════════════════════════
STEP 8: Clean and Test
═══════════════════════════════════════════════════════════════════

1. In Xcode: Product → Clean Build Folder (Cmd+Shift+K)
2. Close Xcode
3. Run from terminal:

    flutter build ios --flavor dev --dart-define=APP_ENV=dev
    flutter build ios --flavor prod --dart-define=APP_ENV=prod

4. If successful, you should see different bundle IDs in the output

═══════════════════════════════════════════════════════════════════
VERIFICATION
═══════════════════════════════════════════════════════════════════

Run these commands to verify:

    # List schemes
    xcodebuild -list -workspace ios/Runner.xcworkspace

    # Should show "Dev" and "Prod" schemes

    # Build and check bundle ID
    flutter build ios --flavor dev --dart-define=APP_ENV=dev
    /usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" \
      build/ios/iphoneos/Runner.app/Info.plist
    
    # Should output: com.techolosh.carletdev

═══════════════════════════════════════════════════════════════════

EOF

echo
echo -e "${GREEN}✅ Instructions displayed!${NC}"
echo
echo "Follow the steps above in Xcode, then run:"
echo "  flutter build ios --flavor dev --dart-define=APP_ENV=dev"
echo
echo "For more details, see: docs/IOS_SCHEME_SETUP.md"
echo
