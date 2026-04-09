#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="Claude Usage"
SRC_APP="$SCRIPT_DIR/$APP_NAME.app"
DEST_APP="$HOME/Applications/$APP_NAME.app"
SCANNER_DIR="$HOME/.claude-usage-scanner"

echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║       Claude WatchBar Installer     ║"
echo "  ╚══════════════════════════════════════╝"
echo ""

# ── Step 1: Check Xcode Command Line Tools ──
echo "[1/5] Checking Xcode Command Line Tools..."
if ! xcode-select -p &>/dev/null; then
    echo "  Xcode CLT not found. Installing..."
    echo "  A system dialog will appear. Click 'Install' and wait."
    xcode-select --install
    echo ""
    echo "  After installation completes, run this script again:"
    echo "    ./install.sh"
    exit 0
fi
echo "  OK"

# ── Step 2: Check Python 3 ──
echo "[2/5] Checking Python 3..."
if ! command -v python3 &>/dev/null; then
    echo "  ERROR: Python 3 not found."
    echo "  Install it: https://www.python.org/downloads/"
    exit 1
fi
echo "  OK ($(python3 --version 2>&1))"

# ── Step 3: Install/update scanner ──
echo "[3/5] Setting up token scanner..."
if [ -d "$SCANNER_DIR" ]; then
    echo "  Updating scanner..."
    cd "$SCANNER_DIR" && git pull --quiet 2>/dev/null || true
else
    echo "  Downloading scanner..."
    git clone --quiet https://github.com/phuryn/claude-usage "$SCANNER_DIR"
fi

echo "  Scanning Claude Code logs..."
cd "$SCANNER_DIR"
python3 cli.py scan 2>/dev/null | tail -5
echo "  OK"

# ── Step 4: Build app ──
echo "[4/5] Building app..."
cd "$SCRIPT_DIR"
bash "$SCRIPT_DIR/build.sh"
echo "  OK"

# ── Step 5: Install ──
echo "[5/5] Installing..."
pkill -f ClaudeUsageBar 2>/dev/null || true
sleep 1
mkdir -p "$HOME/Applications"
rm -rf "$DEST_APP"
cp -R "$SRC_APP" "$DEST_APP"

# Add to Login Items
osascript -e "
    tell application \"System Events\"
        if not (exists login item \"$APP_NAME\") then
            make login item at end with properties {path:\"$DEST_APP\", hidden:false}
        end if
    end tell
" 2>/dev/null || true

# Launch
open "$DEST_APP"

echo ""
echo "  ✓ Installed to: ~/Applications/Claude Usage.app"
echo "  ✓ Added to Login Items (starts on boot)"
echo "  ✓ Running in menu bar"
echo ""
echo "  Config: ~/.claude/usage-bar.json"
echo "  To uninstall: ./uninstall.sh"
echo ""
