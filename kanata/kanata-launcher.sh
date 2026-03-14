#!/bin/bash
# Launcher for kanata that kills conflicting Karabiner processes first.
# Karabiner-Core-Service grabs keyboards exclusively at boot, preventing
# kanata from intercepting keystrokes. We only need Karabiner's DEXT
# driver and VirtualHIDDevice-Daemon.

ps aux | grep -i karabiner | grep -v grep \
    | grep -v "VirtualHIDDevice-Daemon" \
    | grep -v "VirtualHIDDevice.dext" \
    | awk '{print $2}' | xargs kill -9 2>/dev/null || true
sleep 2

exec /opt/homebrew/bin/kanata "$@"
