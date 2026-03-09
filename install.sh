#!/usr/bin/env bash
#
# dotfiles installer
# https://github.com/jknafou/dotfiles
#
# Quick start:
#   git clone https://github.com/jknafou/dotfiles ~/dotfiles
#   cd ~/dotfiles
#   ./install.sh              Install everything (except kanata)
#   ./install.sh --mac        Install everything (including kanata)
#   ./install.sh --nvim       Install only neovim
#   ./install.sh --tmux       Install only tmux
#   ./install.sh --terminal   Install only shell environment
#   ./install.sh --kanata     Install only kanata
#

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# ─── Defaults ────────────────────────────────────────────────────────────────

INSTALL_NVIM=false
INSTALL_TMUX=false
INSTALL_KANATA=false
INSTALL_TERMINAL=false
HAS_FLAGS=false

# ─── Usage ───────────────────────────────────────────────────────────────────

usage() {
    cat <<EOF
Usage: ./install.sh [OPTIONS]

Options:
  --mac        Install everything (including kanata)
  --nvim       Neovim configuration
  --tmux       Tmux configuration and plugin manager
  --terminal   Zsh, Starship, fzf, and development tools
  --kanata     Kanata keyboard remapper with LaunchDaemon (macOS)
  -h, --help   Show this help message

Running without flags installs everything except kanata.
Flags can be combined: ./install.sh --nvim --tmux
EOF
    exit 0
}

# ─── Parse arguments ────────────────────────────────────────────────────────

for arg in "$@"; do
    case "$arg" in
        --mac)
            INSTALL_NVIM=true
            INSTALL_TMUX=true
            INSTALL_KANATA=true
            INSTALL_TERMINAL=true
            HAS_FLAGS=true
            ;;
        --nvim)     INSTALL_NVIM=true;     HAS_FLAGS=true ;;
        --tmux)     INSTALL_TMUX=true;     HAS_FLAGS=true ;;
        --kanata)   INSTALL_KANATA=true;   HAS_FLAGS=true ;;
        --terminal) INSTALL_TERMINAL=true; HAS_FLAGS=true ;;
        --help|-h)  usage ;;
        *)          echo "Unknown option: $arg"; echo; usage ;;
    esac
done

if ! $HAS_FLAGS; then
    INSTALL_NVIM=true
    INSTALL_TMUX=true
    INSTALL_TERMINAL=true
fi

# ─── Helpers ─────────────────────────────────────────────────────────────────

info()    { printf "\033[1;34m::\033[0m %s\n" "$1"; }
warn()    { printf "\033[1;33m::\033[0m %s\n" "$1"; }
success() { printf "\033[1;32m::\033[0m %s\n" "$1"; }

backup_if_exists() {
    local target="$1"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        warn "Backing up $target → ${target}.bak"
        mv "$target" "${target}.bak"
    fi
}

link_package() {
    local pkg="$1"; shift
    cd "$DOTFILES_DIR"
    stow -v --target="$HOME" "$@" "$pkg"
}

# ─── Homebrew ────────────────────────────────────────────────────────────────

if ! command -v brew &>/dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
fi

if ! command -v stow &>/dev/null; then
    brew install stow
fi
success "Homebrew ready"

# ─── Neovim ──────────────────────────────────────────────────────────────────

if $INSTALL_NVIM; then
    info "Installing neovim..."
    brew install neovim ripgrep fd

    backup_if_exists "$HOME/.config/nvim"
    link_package nvim

    success "Neovim ready"
fi

# ─── Tmux ────────────────────────────────────────────────────────────────────

if $INSTALL_TMUX; then
    info "Installing tmux..."
    brew install tmux tmuxifier

    backup_if_exists "$HOME/.config/tmux"
    link_package tmux

    TPM_DIR="$HOME/.tmux/plugins/tpm"
    if [ ! -d "$TPM_DIR" ]; then
        info "Installing TPM (Tmux Plugin Manager)..."
        git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    fi

    success "Tmux ready — run prefix + I to install plugins"
fi

# ─── Terminal ────────────────────────────────────────────────────────────────

if $INSTALL_TERMINAL; then
    info "Installing shell environment..."
    brew install fzf fd ripgrep starship pyenv pyenv-virtualenv nvm node go

    # Oh My Zsh
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        info "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi

    # Zsh plugins
    ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
        if [ ! -d "$ZSH_CUSTOM/plugins/$plugin" ]; then
            info "Installing $plugin..."
            git clone "https://github.com/zsh-users/$plugin" "$ZSH_CUSTOM/plugins/$plugin"
        fi
    done

    backup_if_exists "$HOME/.zshrc"
    backup_if_exists "$HOME/.zprofile"
    backup_if_exists "$HOME/.config/starship.toml"
    link_package zsh
    link_package starship

    success "Terminal ready"
fi

# ─── Kanata ──────────────────────────────────────────────────────────────────

if $INSTALL_KANATA; then
    info "Installing kanata..."
    brew install kanata

    backup_if_exists "$HOME/.config/kanata"
    link_package kanata --ignore='com\.jknafou\.kanata\.plist'

    # LaunchDaemon
    PLIST_SRC="$DOTFILES_DIR/kanata/com.jknafou.kanata.plist"
    PLIST_DST="/Library/LaunchDaemons/com.jknafou.kanata.plist"
    PLIST_TMP=$(mktemp)

    sed "s|__HOME__|$HOME|g" "$PLIST_SRC" > "$PLIST_TMP"

    info "Installing LaunchDaemon (requires sudo)..."
    sudo mkdir -p /Library/Logs/Kanata
    sudo cp "$PLIST_TMP" "$PLIST_DST"
    sudo chown root:wheel "$PLIST_DST"
    sudo chmod 644 "$PLIST_DST"
    rm "$PLIST_TMP"

    if sudo launchctl list | grep -q com.jknafou.kanata; then
        sudo launchctl unload "$PLIST_DST" 2>/dev/null || true
    fi
    sudo launchctl load "$PLIST_DST"

    success "Kanata ready — daemon running"
fi

# ─── Done ────────────────────────────────────────────────────────────────────

echo
success "Installation complete. Restart your shell or run: exec zsh"
