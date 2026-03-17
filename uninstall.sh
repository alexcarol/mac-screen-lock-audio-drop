#!/bin/bash
set -e

BINARY="$HOME/.local/bin/screen-lock-audio-drop"
PLIST_DEST="$HOME/Library/LaunchAgents/com.user.screen-lock-audio-drop.plist"
LABEL="com.user.screen-lock-audio-drop"

launchctl list | grep -q "$LABEL" && launchctl unload "$PLIST_DEST" 2>/dev/null || true
rm -f "$PLIST_DEST" "$BINARY" /tmp/screen-lock-audio-drop.log /tmp/screen-lock-audio-drop.err

echo "Uninstalled."
