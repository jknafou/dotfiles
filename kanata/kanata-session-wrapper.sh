#!/usr/bin/env bash
#
# Wrapper for kanata that only runs when the specified user is the active
# console user. When another user logs in, kanata is stopped. KeepAlive
# in the LaunchDaemon restarts this wrapper, which checks again.
#
# Usage: kanata-session-wrapper.sh <username> <kanata args...>
#

set -euo pipefail

ALLOWED_USER="$1"; shift

get_console_user() {
    /usr/bin/stat -f '%Su' /dev/console 2>/dev/null
}

CURRENT_USER="$(get_console_user)"

# If the allowed user is not the active console user, exit cleanly.
# KeepAlive (SuccessfulExit=false) only restarts on non-zero exit,
# so we exit with 1 to ensure launchd retries after ThrottleInterval.
if [ "$CURRENT_USER" != "$ALLOWED_USER" ]; then
    echo "Console user is '$CURRENT_USER', not '$ALLOWED_USER' — kanata disabled"
    exit 1
fi

echo "Console user is '$ALLOWED_USER' — starting kanata"

# Launch kanata in the background
/opt/homebrew/bin/kanata "$@" &
KANATA_PID=$!

# Monitor for session changes: if the console user changes, kill kanata
while kill -0 "$KANATA_PID" 2>/dev/null; do
    CURRENT_USER="$(get_console_user)"
    if [ "$CURRENT_USER" != "$ALLOWED_USER" ]; then
        echo "Console user changed to '$CURRENT_USER' — stopping kanata"
        kill "$KANATA_PID" 2>/dev/null || true
        wait "$KANATA_PID" 2>/dev/null || true
        exit 1
    fi
    sleep 2
done

# If kanata exited on its own, propagate its exit code
wait "$KANATA_PID" 2>/dev/null
