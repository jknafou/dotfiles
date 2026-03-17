#!/bin/bash
# Runs as a LaunchAgent — stays alive and calls kanata_off on session teardown.
# When the user logs out, launchd sends SIGTERM to all session agents.
trap '/usr/local/bin/kanata_off' TERM
# Sleep forever, waiting for SIGTERM
while true; do sleep 3600; done
