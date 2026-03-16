#!/bin/bash
# Launcher for kanata that ensures the right Karabiner components are running.
# Kanata needs: DEXT (macOS loads automatically) + VirtualHIDDevice-Daemon.
# Kanata conflicts with: Karabiner-Core-Service, grabber, observer, etc.

# Kill conflicting Karabiner processes (keep VirtualHIDDevice-Daemon and DEXT)
ps aux | grep -i karabiner | grep -v grep \
    | grep -v "VirtualHIDDevice-Daemon" \
    | grep -v "VirtualHIDDevice.dext" \
    | awk '{print $2}' | xargs kill -9 2>/dev/null || true

# Ensure VirtualHIDDevice-Daemon is running (bridges kanata to the DEXT)
VHID_DAEMON="/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon"
if [ -x "$VHID_DAEMON" ] && ! pgrep -f "Karabiner-VirtualHIDDevice-Daemon" >/dev/null 2>&1; then
    "$VHID_DAEMON" &
fi

sleep 2

exec /usr/local/bin/kanata "$@"
