#!/bin/bash
# Logout hook: stop kanata when any user logs out.
# Installed via: sudo defaults write com.apple.loginwindow LogoutHook /usr/local/bin/kanata-logout-hook.sh
/usr/local/bin/kanata_off
