#!/bin/bash
# Wraps the release binary into EngHelper.app — LSUIElement=1 so the
# app lives in the menu bar with no Dock icon (design D-02), ad-hoc
# signed so the Accessibility grant persists — and copies it to
# /Applications. This is how the app is actually run.
set -euo pipefail

cd "$(dirname "$0")/.."

swift build -c release
BIN="$(swift build -c release --show-bin-path)/EngHelperApp"

APP="build/EngHelper.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>EngHelper</string>
    <key>CFBundleIdentifier</key>
    <string>local.eng-helper</string>
    <key>CFBundleName</key>
    <string>EngHelper</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
PLIST

cp "$BIN" "$APP/Contents/MacOS/EngHelper"
codesign --force --sign - "$APP"

rm -rf /Applications/EngHelper.app
ditto "$APP" /Applications/EngHelper.app
echo "Installed /Applications/EngHelper.app"
