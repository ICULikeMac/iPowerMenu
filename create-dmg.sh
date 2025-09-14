#!/bin/bash

# DMG creation script for iPowerMenu
set -e

APP_NAME="iPowerMenu"
VERSION="1.0.0"
BUILD_DIR=".build"
APP_PATH="$BUILD_DIR/$APP_NAME.app"
DMG_NAME="$APP_NAME-$VERSION"
DMG_PATH="$BUILD_DIR/$DMG_NAME.dmg"
TEMP_DMG_PATH="$BUILD_DIR/temp-$DMG_NAME.dmg"

echo "Creating DMG for $APP_NAME v$VERSION..."

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
    echo "Error: App bundle not found at $APP_PATH"
    echo "Please run ./build-app.sh first"
    exit 1
fi

# Clean up any existing DMG
rm -f "$DMG_PATH" "$TEMP_DMG_PATH"

# Create a temporary directory for DMG contents
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Copy app to temp directory
cp -R "$APP_PATH" "$TEMP_DIR/"

# Create a symlink to Applications folder
ln -s /Applications "$TEMP_DIR/Applications"

# Get the size needed for the DMG (add some padding)
SIZE=$(du -sk "$TEMP_DIR" | cut -f1)
SIZE=$((SIZE + 10000))  # Add 10MB padding

# Create temporary DMG
hdiutil create -srcfolder "$TEMP_DIR" -volname "$APP_NAME" -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" -format UDRW -size "${SIZE}k" "$TEMP_DMG_PATH"

# Mount the temporary DMG
MOUNT_DIR=$(mktemp -d)
hdiutil attach "$TEMP_DMG_PATH" -readwrite -noverify -mountpoint "$MOUNT_DIR"

# Set DMG window properties (optional - requires Finder scripting)
# This section could be enhanced with AppleScript for custom DMG appearance

# Unmount the DMG
hdiutil detach "$MOUNT_DIR"
rmdir "$MOUNT_DIR"

# Convert to compressed, read-only DMG
hdiutil convert "$TEMP_DMG_PATH" -format UDZO -imagekey zlib-level=9 -o "$DMG_PATH"

# Clean up temporary DMG
rm -f "$TEMP_DMG_PATH"

# Display results
ls -lh "$DMG_PATH"
echo ""
echo "DMG created successfully: $DMG_PATH"
echo "You can test it by running: open $DMG_PATH"
echo ""
echo "To notarize the DMG for distribution:"
echo "1. Upload to Apple for notarization: xcrun notarytool submit $DMG_PATH --keychain-profile 'notary-profile' --wait"
echo "2. Staple the notarization: xcrun stapler staple $DMG_PATH"