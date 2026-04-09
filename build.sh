#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="Claude Usage"
BUNDLE_DIR="$SCRIPT_DIR/$APP_NAME.app"

echo "Building Claude Usage..."

# Compile
swiftc "$SCRIPT_DIR/main.swift" -o "$SCRIPT_DIR/ClaudeUsageBar" -lsqlite3 -O -swift-version 5 2>&1 | { grep -v "warning:" || true; }

# Create .app bundle
mkdir -p "$BUNDLE_DIR/Contents/MacOS"
cp "$SCRIPT_DIR/ClaudeUsageBar" "$BUNDLE_DIR/Contents/MacOS/"

cat > "$BUNDLE_DIR/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Claude Usage</string>
    <key>CFBundleDisplayName</key>
    <string>Claude Usage</string>
    <key>CFBundleIdentifier</key>
    <string>com.claudeusage.bar</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>ClaudeUsageBar</string>
    <key>LSUIElement</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
</dict>
</plist>
PLIST

echo "Built: $BUNDLE_DIR"
