#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

TEAM_ID="8836WUYZD5"
SIGNING_IDENTITY="Developer ID Application: a2zCreative, LLC ($TEAM_ID)"

# Regenerate Xcode project
echo "Regenerating Xcode project..."
xcodegen generate

# Build the app
echo "Building FreeUpSpace (Release)..."
xcodebuild -project FreeUpSpace.xcodeproj \
    -scheme FreeUpSpace \
    -configuration Release \
    -derivedDataPath build/DerivedData \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY="$SIGNING_IDENTITY" \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    ENABLE_HARDENED_RUNTIME=YES \
    "OTHER_CODE_SIGN_FLAGS=--timestamp" \
    CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
    clean build

APP_PATH="build/DerivedData/Build/Products/Release/FreeUpSpace.app"

if [ ! -d "$APP_PATH" ]; then
    echo "Error: Build failed - FreeUpSpace.app not found"
    exit 1
fi

echo "Verifying code signature..."
codesign --verify --deep --strict "$APP_PATH"
codesign -dvv "$APP_PATH" 2>&1 | head -5 || true

# Create DMG
echo ""
echo "Creating DMG..."
DMG_NAME="FreeUpSpace-$(date +%Y%m%d).dmg"
DMG_PATH="Distribution/$DMG_NAME"
STAGING_DIR="build/dmg-staging"

rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
mkdir -p Distribution
cp -R "$APP_PATH" "$STAGING_DIR/"

# Create symlink to Applications
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create -volname "FreeUpSpace" \
    -srcfolder "$STAGING_DIR" \
    -ov -format UDZO \
    "$DMG_PATH"

# Sign the DMG itself
codesign --force --sign "$SIGNING_IDENTITY" --timestamp "$DMG_PATH"

echo ""
echo "=== Build Complete ==="
echo "DMG: $DMG_PATH"
echo ""
echo "To notarize, run:"
echo "  APPLE_ID=simsketch@yahoo.com APPLE_PASSWORD=<app-specific-pwd> TEAM_ID=$TEAM_ID ./Scripts/notarize.sh $DMG_PATH"
