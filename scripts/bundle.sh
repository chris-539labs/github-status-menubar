#!/bin/bash
set -e

APP_NAME="GitHub Status"
BUNDLE_ID="com.539ventures.github-status"
EXECUTABLE="GitHubStatus"
APP_DIR="$APP_NAME.app"
BUILD_DIR="$(dirname "$0")/.."

echo "Building release binary..."
cd "$BUILD_DIR"
swift build -c release

echo "Creating app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp .build/release/$EXECUTABLE "$APP_DIR/Contents/MacOS/$EXECUTABLE"

cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>$EXECUTABLE</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>

echo "Installing to /Applications..."
rm -rf "/Applications/$APP_DIR"
cp -R "$APP_DIR" /Applications/
rm -rf "$APP_DIR"

echo ""
echo "Done! '$APP_NAME' installed to /Applications."
echo ""
echo "To launch at login:"
echo "  System Settings > General > Login Items > '+' > select '$APP_NAME'"
echo ""
echo "Launching now..."
open "/Applications/$APP_DIR"
