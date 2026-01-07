#!/bin/bash
set -e

BINARY="$HOME/.local/bin/bluetooth-lock"
PLIST_DEST="$HOME/Library/LaunchAgents/com.user.bluetooth-lock.plist"
LABEL="com.user.bluetooth-lock"

launchctl list | grep -q "$LABEL" && launchctl unload "$PLIST_DEST" 2>/dev/null || true
rm -f "$PLIST_DEST" "$BINARY" /tmp/bluetooth-lock.log /tmp/bluetooth-lock.err

echo "Uninstalled."
