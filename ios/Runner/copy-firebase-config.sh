#!/bin/sh

# iOS Build Phase Script: Copy GoogleService-Info.plist based on configuration
#
# This script runs during the Xcode build process and copies the appropriate
# Firebase configuration file based on the build configuration (Dev or Prod).
#
# Dev builds use: Runner/Dev/GoogleService-Info.plist
# Prod builds use: Runner/Prod/GoogleService-Info.plist

# Determine environment from configuration name
ENVIRONMENT=""
if [[ "${CONFIGURATION}" == *"Dev"* ]]; then
    ENVIRONMENT="Dev"
elif [[ "${CONFIGURATION}" == *"Prod"* ]]; then
    ENVIRONMENT="Prod"
else
    # Default to Dev for Debug builds
    ENVIRONMENT="Dev"
fi

echo "📱 Build Configuration: ${CONFIGURATION}"
echo "🔧 Environment: ${ENVIRONMENT}"

# Source and destination paths
SOURCE_PATH="${SRCROOT}/Runner/${ENVIRONMENT}/GoogleService-Info.plist"
DEST_PATH="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/GoogleService-Info.plist"

# Check if source file exists
if [ ! -f "$SOURCE_PATH" ]; then
    echo "❌ ERROR: GoogleService-Info.plist not found at ${SOURCE_PATH}"
    echo "⚠️  Please add Firebase configuration file for ${ENVIRONMENT} environment"
    exit 1
fi

# Copy the file
echo "📋 Copying ${SOURCE_PATH}"
echo "   to ${DEST_PATH}"
cp "${SOURCE_PATH}" "${DEST_PATH}"

if [ $? -eq 0 ]; then
    echo "✅ Successfully copied GoogleService-Info.plist for ${ENVIRONMENT} environment"
else
    echo "❌ Failed to copy GoogleService-Info.plist"
    exit 1
fi
