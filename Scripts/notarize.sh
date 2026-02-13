#!/bin/bash
set -euo pipefail

# Notarize the DMG for distribution outside the Mac App Store
# Requires:
#   - APPLE_ID: Apple Developer account email
#   - APPLE_PASSWORD: App-specific password
#   - TEAM_ID: Apple Developer Team ID

if [ -z "${APPLE_ID:-}" ] || [ -z "${APPLE_PASSWORD:-}" ] || [ -z "${TEAM_ID:-}" ]; then
    echo "Error: Set APPLE_ID, APPLE_PASSWORD, and TEAM_ID environment variables"
    exit 1
fi

DMG_PATH="${1:?Usage: $0 <path-to-dmg>}"

if [ ! -f "$DMG_PATH" ]; then
    echo "Error: DMG not found at $DMG_PATH"
    exit 1
fi

echo "Submitting for notarization..."
xcrun notarytool submit "$DMG_PATH" \
    --apple-id "$APPLE_ID" \
    --password "$APPLE_PASSWORD" \
    --team-id "$TEAM_ID" \
    --wait

echo "Stapling notarization ticket..."
xcrun stapler staple "$DMG_PATH"

echo "Verifying..."
spctl --assess --type open --context context:primary-signature -v "$DMG_PATH"

echo "Notarization complete!"
