#!/bin/bash
set -euo pipefail

# Build the app
echo "Building FreeUpSpace..."
xcodebuild -project FreeUpSpace.xcodeproj \
    -scheme FreeUpSpace \
    -configuration Release \
    -derivedDataPath build \
    -arch arm64 -arch x86_64 \
    ONLY_ACTIVE_ARCH=NO \
    clean build

APP_PATH="build/Build/Products/Release/FreeUpSpace.app"

if [ ! -d "$APP_PATH" ]; then
    echo "Error: Build failed - FreeUpSpace.app not found"
    exit 1
fi

# Create DMG
echo "Creating DMG..."
DMG_NAME="FreeUpSpace-$(date +%Y%m%d).dmg"
STAGING_DIR="build/dmg-staging"

rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/"

# Create symlink to Applications
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create -volname "FreeUpSpace" \
    -srcfolder "$STAGING_DIR" \
    -ov -format UDZO \
    "Distribution/$DMG_NAME"

echo "DMG created: Distribution/$DMG_NAME"
echo "Done!"
