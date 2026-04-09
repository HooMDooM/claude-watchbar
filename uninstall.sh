#!/bin/bash

APP_NAME="Claude Usage"

pkill -f ClaudeUsageBar 2>/dev/null || true

# Remove Login Item
osascript -e "
    tell application \"System Events\"
        if exists login item \"$APP_NAME\" then
            delete login item \"$APP_NAME\"
        end if
    end tell
" 2>/dev/null

rm -rf "$HOME/Applications/$APP_NAME.app"
rm -f "$HOME/.claude/usage-bar.json"

echo "Claude Usage uninstalled."
