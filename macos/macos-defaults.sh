#!/usr/bin/env bash
#
# macOS sensible defaults
# Apply with: ./macos-defaults.sh
# Most changes require a logout or restart to take effect.
#

set -euo pipefail

info() { printf "\033[1;34m::\033[0m %s\n" "$1"; }

# ─── Dock ──────────────────────────────────────────────────────────────────
info "Configuring Dock..."

defaults write com.apple.dock tilesize -int 75
defaults write com.apple.dock magnification -bool true
defaults write com.apple.dock autohide -bool false
defaults write com.apple.dock minimize-to-application -bool true
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock launchanim -bool true
defaults write com.apple.dock orientation -string bottom

# ─── Finder ────────────────────────────────────────────────────────────────
info "Configuring Finder..."

# Column view by default
defaults write com.apple.finder FXPreferredViewStyle -string clmv
# Search current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string SCcf
# Sort folders first
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder _FXSortFoldersFirstOnDesktop -bool true
# Show drives on desktop
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true

# ─── Keyboard ──────────────────────────────────────────────────────────────
info "Configuring keyboard..."

# Fast key repeat
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 25
# Disable auto-correct annoyances
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# ─── Trackpad ──────────────────────────────────────────────────────────────
info "Configuring trackpad..."

# Tap to click
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
# Three-finger drag
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
defaults write com.apple.AppleMultitouchTrackpad DragLock -bool false

# ─── Global ────────────────────────────────────────────────────────────────
info "Configuring global preferences..."

# Show all file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# Auto-switch dark/light mode
defaults write NSGlobalDomain AppleInterfaceStyleSwitchesAutomatically -bool true

# ─── Menu bar clock ───────────────────────────────────────────────────────
info "Configuring menu bar..."

defaults write com.apple.menuextra.clock ShowDate -int 0

# ─── Apply changes ─────────────────────────────────────────────────────────
info "Restarting affected apps..."

killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true

printf "\033[1;32m::\033[0m macOS defaults applied. Some changes may require logout.\n"
