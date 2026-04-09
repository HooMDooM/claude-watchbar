#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="Claude Usage"
SRC_APP="$SCRIPT_DIR/$APP_NAME.app"
DEST_APP="$HOME/Applications/$APP_NAME.app"

# Build first
echo "Building..."
bash "$SCRIPT_DIR/build.sh"

# Kill if running
pkill -f ClaudeUsageBar 2>/dev/null || true
sleep 1

# Install
mkdir -p "$HOME/Applications"
rm -rf "$DEST_APP"
cp -R "$SRC_APP" "$DEST_APP"
echo "Installed to: $DEST_APP"

# Launch
open "$DEST_APP"
echo "Launched."
echo ""
echo "To start on login, run:"
echo "  $SCRIPT_DIR/install.sh --login"
echo ""

# Add to Login Items if requested
if [ "$1" = "--login" ]; then
    osascript -e "
        tell application \"System Events\"
            if not (exists login item \"$APP_NAME\") then
                make login item at end with properties {path:\"$DEST_APP\", hidden:false}
                log \"Added to Login Items\"
            else
                log \"Already in Login Items\"
            end if
        end tell
    " 2>&1
    echo "Auto-start on login: enabled"
fi
