#!/bin/bash

# Build script for iPowerMenu macOS app
set -e

APP_NAME="iPowerMenu"
BUILD_DIR=".build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "Building iPowerMenu for release..."

# Clean previous builds
rm -rf "$BUILD_DIR/$APP_NAME.app"

# Build the Swift package in release mode
swift build -c release

# Create app bundle structure
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy executable
cp ".build/release/iPowerMenu" "$MACOS_DIR/$APP_NAME"

# Copy Info.plist
cp "Sources/HomeAssistantMenuBar/Info.plist" "$CONTENTS_DIR/"

# Make executable
chmod +x "$MACOS_DIR/$APP_NAME"

echo "App bundle created at: $APP_DIR"
echo "To run: open $APP_DIR"

# Code sign with Developer ID Application certificate
DEVELOPER_ID="Developer ID Application: Alexander Hart (M9QW4CBDY8)"

echo "Code signing with Developer ID: $DEVELOPER_ID"
echo "Signing executable..."
codesign --force --options runtime --sign "$DEVELOPER_ID" "$MACOS_DIR/$APP_NAME"

echo "Signing app bundle..."
codesign --force --options runtime --sign "$DEVELOPER_ID" "$APP_DIR"

echo "Verifying code signature..."
codesign --verify --verbose "$APP_DIR"

echo "Checking signature details..."
codesign -dv "$APP_DIR"

echo "App signed successfully ✅"

echo "Build complete!"