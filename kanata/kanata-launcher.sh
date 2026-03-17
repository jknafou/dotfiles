#!/bin/bash
# Launcher for kanata on macOS.
# Waits for DEXT + daemon, kills conflicting Karabiner, then execs kanata.

log() { echo "[$(date '+%H:%M:%S')] kanata-launcher: $*" >&2; }

VHID_DAEMON="/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon"

# 1. Start VirtualHIDDevice-Daemon if not running
if [ -x "$VHID_DAEMON" ] && ! pgrep -f "Karabiner-VirtualHIDDevice-Daemon" >/dev/null 2>&1; then
    log "Starting VirtualHIDDevice-Daemon"
    "$VHID_DAEMON" &
fi

# 2. Wait for DEXT + daemon (up to 60s)
log "Waiting for DEXT and daemon..."
for i in $(seq 1 30); do
    DEXT_OK=false
    DAEMON_OK=false
    systemextensionsctl list 2>&1 | grep -q "org.pqrs.Karabiner-DriverKit-VirtualHIDDevice.*activated.*enabled" && DEXT_OK=true
    pgrep -f "Karabiner-VirtualHIDDevice-Daemon" >/dev/null 2>&1 && DAEMON_OK=true
    if $DEXT_OK && $DAEMON_OK; then
        log "Ready after ${i}x2s"
        break
    fi
    sleep 2
done

# 3. Kill conflicting Karabiner RIGHT BEFORE exec (no gap for respawn)
PIDS=$(ps aux | grep -i karabiner | grep -v grep \
    | grep -v "VirtualHIDDevice-Daemon" \
    | grep -v "VirtualHIDDevice.dext" \
    | awk '{print $2}') || true
if [ -n "$PIDS" ]; then
    log "Killing conflicting Karabiner: $PIDS"
    echo "$PIDS" | xargs kill -9 2>/dev/null || true
fi

# 4. Start kanata (--nodelay skips 2s startup wait)
log "Starting kanata"
exec /opt/homebrew/bin/kanata --nodelay "$@"
