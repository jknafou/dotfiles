#!/bin/bash
# LaunchAgent that stops kanata when the user session ends.
# launchd sends SIGTERM on logout; we trap it and stop kanata.
# Using exec sleep so SIGTERM hits bash directly (no child process blocking).

cleanup() {
    /usr/local/bin/kanata_off >/tmp/kanata-logout.out.log 2>/tmp/kanata-logout.err.log
}

trap cleanup TERM INT
# Infinite wait — bash's `wait` returns immediately on signal (unlike sleep)
while true; do
    sleep 86400 &
    wait $!
done
