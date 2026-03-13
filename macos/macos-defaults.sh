#!/usr/bin/env bash
#
# macOS sensible defaults
# Apply with: ./macos-defaults.sh
# Idempotent: only restarts Dock/Finder if values actually changed.
#

set -euo pipefail

info() { printf "\033[1;34m::\033[0m %s\n" "$1"; }

CHANGED=false

# Write a default only if the current value differs
set_default() {
    local domain="$1" key="$2" type="$3" value="$4"
    local current
    current="$(defaults read "$domain" "$key" 2>/dev/null || echo "__UNSET__")"
    if [ "$current" != "$value" ]; then
        defaults write "$domain" "$key" "$type" "$value"
        CHANGED=true
    fi
}

# ─── Dock ──────────────────────────────────────────────────────────────────
info "Configuring Dock..."

set_default com.apple.dock tilesize -int 75
set_default com.apple.dock magnification -bool true
set_default com.apple.dock autohide -bool false
set_default com.apple.dock minimize-to-application -bool true
set_default com.apple.dock show-recents -bool false
set_default com.apple.dock launchanim -bool true
set_default com.apple.dock orientation -string bottom

# ─── Finder ────────────────────────────────────────────────────────────────
info "Configuring Finder..."

# Column view by default
set_default com.apple.finder FXPreferredViewStyle -string clmv
# Search current folder by default
set_default com.apple.finder FXDefaultSearchScope -string SCcf
# Sort folders first
set_default com.apple.finder _FXSortFoldersFirst -bool true
set_default com.apple.finder _FXSortFoldersFirstOnDesktop -bool true
# Show drives on desktop
set_default com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
set_default com.apple.finder ShowHardDrivesOnDesktop -bool true

# ─── Keyboard ──────────────────────────────────────────────────────────────
info "Configuring keyboard..."

# Fast key repeat
set_default NSGlobalDomain KeyRepeat -int 2
set_default NSGlobalDomain InitialKeyRepeat -int 25
# Disable auto-correct annoyances
set_default NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
set_default NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
set_default NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# ─── Trackpad ──────────────────────────────────────────────────────────────
info "Configuring trackpad..."

# Tap to click
set_default com.apple.AppleMultitouchTrackpad Clicking -bool true
# Three-finger drag
set_default com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
set_default com.apple.AppleMultitouchTrackpad DragLock -bool false

# ─── Global ────────────────────────────────────────────────────────────────
info "Configuring global preferences..."

# Show all file extensions
set_default NSGlobalDomain AppleShowAllExtensions -bool true
# Auto-switch dark/light mode
set_default NSGlobalDomain AppleInterfaceStyleSwitchesAutomatically -bool true

# ─── Menu bar clock ───────────────────────────────────────────────────────
info "Configuring menu bar..."

set_default com.apple.menuextra.clock ShowDate -int 0

# ─── Apply changes ─────────────────────────────────────────────────────────
if $CHANGED; then
    info "Restarting Dock and Finder to apply changes..."
    killall Dock 2>/dev/null || true
    killall Finder 2>/dev/null || true
    printf "\033[1;32m::\033[0m macOS defaults applied. Some changes may require logout.\n"
else
    printf "\033[1;32m::\033[0m macOS defaults — already up to date (no restart needed).\n"
fi
