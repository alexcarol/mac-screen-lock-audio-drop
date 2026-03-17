#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.local/bin"
BINARY="$INSTALL_DIR/screen-lock-audio-drop"
PLIST_DEST="$HOME/Library/LaunchAgents/com.user.screen-lock-audio-drop.plist"
LABEL="com.user.screen-lock-audio-drop"

# Check for Swift compiler
if ! command -v swiftc &> /dev/null; then
    echo "Error: Swift compiler not found. Run: xcode-select --install"
    exit 1
fi

# Unload existing agent if present
launchctl list | grep -q "$LABEL" && launchctl unload "$PLIST_DEST" 2>/dev/null || true

# Compile and install
mkdir -p "$INSTALL_DIR" ~/Library/LaunchAgents
echo "Compiling..."
swiftc -O "$SCRIPT_DIR/screen-lock-audio-drop.swift" -o "$BINARY"

# Install launch agent
sed "s|__SCRIPT_PATH__|$BINARY|g" "$SCRIPT_DIR/com.user.screen-lock-audio-drop.plist" > "$PLIST_DEST"
launchctl load "$PLIST_DEST"

echo "Done! Test by locking your screen (Ctrl+Cmd+Q)"
echo "Uninstall: $SCRIPT_DIR/uninstall.sh"
