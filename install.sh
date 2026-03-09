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
OS="$(uname -s)"

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
  --kanata     Kanata keyboard remapper (macOS: LaunchDaemon, Linux: systemd)
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
    if [ -L "$target" ]; then
        # Symlink exists — remove if it doesn't point into our dotfiles
        local link_target
        link_target="$(readlink "$target")"
        if [[ "$link_target" != *dotfiles* ]]; then
            warn "Removing stale symlink $target → $link_target"
            rm "$target"
        fi
    elif [ -e "$target" ]; then
        warn "Backing up $target → ${target}.bak"
        mv "$target" "${target}.bak"
    fi
}

link_package() {
    local pkg="$1"; shift
    cd "$DOTFILES_DIR"
    # --adopt: if a target file exists, move it into the repo then symlink.
    # We git checkout right after to restore our version.
    stow -v --adopt --target="$HOME" "$@" "$pkg"
    git -C "$DOTFILES_DIR" checkout -- "$pkg" 2>/dev/null || true
}

pkg_install() {
    if command -v brew &>/dev/null; then
        brew install "$@"
    elif command -v apt-get &>/dev/null; then
        sudo apt-get install -y "$@"
    elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm "$@"
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y "$@"
    else
        warn "No supported package manager found — install manually: $*"
        return 1
    fi
}

# ─── Package manager ────────────────────────────────────────────────────────

if [[ "$OS" == "Darwin" ]]; then
    if ! command -v brew &>/dev/null; then
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
    fi
    success "Homebrew ready"
else
    info "Detected Linux — using system package manager"
fi

if ! command -v stow &>/dev/null; then
    info "Installing stow..."
    pkg_install stow
fi

if ! command -v zsh &>/dev/null; then
    info "Installing zsh..."
    pkg_install zsh
fi

if ! command -v git &>/dev/null; then
    info "Installing git..."
    pkg_install git
fi

# ─── Neovim ──────────────────────────────────────────────────────────────────

if $INSTALL_NVIM; then
    info "Installing neovim..."
    pkg_install neovim ripgrep fd

    backup_if_exists "$HOME/.config/nvim"
    link_package nvim

    success "Neovim ready"
fi

# ─── Tmux ────────────────────────────────────────────────────────────────────

if $INSTALL_TMUX; then
    info "Installing tmux..."
    pkg_install tmux
    command -v brew &>/dev/null && brew install tmuxifier

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

    if command -v brew &>/dev/null; then
        brew install fzf fd ripgrep starship pyenv pyenv-virtualenv nvm node go
    else
        pkg_install fzf ripgrep
        # fd is named fd-find on some distros
        pkg_install fd-find 2>/dev/null || pkg_install fd 2>/dev/null || true
        # starship via official installer
        if ! command -v starship &>/dev/null; then
            info "Installing Starship..."
            curl -sS https://starship.rs/install.sh | sh -s -- -y
        fi
        # pyenv via official installer
        if ! command -v pyenv &>/dev/null; then
            info "Installing pyenv..."
            curl -sS https://pyenv.run | bash
        fi
        # nvm via official installer
        if [ ! -d "$HOME/.nvm" ]; then
            info "Installing nvm..."
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
        fi
        pkg_install golang-go 2>/dev/null || pkg_install go 2>/dev/null || true
    fi

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

    backup_if_exists "$HOME/.config/kanata"

    if [[ "$OS" == "Darwin" ]]; then
        brew install kanata
        link_package kanata --ignore='com\.jknafou\.kanata\.plist' --ignore='kanata\.service'

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

        success "Kanata ready — LaunchDaemon running"

    else
        # Linux: install kanata from cargo or package manager
        if ! command -v kanata &>/dev/null; then
            if command -v cargo &>/dev/null; then
                cargo install kanata
            else
                warn "Install kanata manually: https://github.com/jtroo/kanata"
            fi
        fi

        link_package kanata --ignore='com\.jknafou\.kanata\.plist' --ignore='kanata\.service'

        # systemd service
        SERVICE_SRC="$DOTFILES_DIR/kanata/kanata.service"
        SERVICE_TMP=$(mktemp)
        sed "s|__HOME__|$HOME|g" "$SERVICE_SRC" > "$SERVICE_TMP"

        sudo mkdir -p /etc/systemd/system
        sudo cp "$SERVICE_TMP" /etc/systemd/system/kanata.service
        rm "$SERVICE_TMP"

        sudo systemctl daemon-reload
        sudo systemctl enable --now kanata

        success "Kanata ready — systemd service running"
    fi
fi

# ─── Done ────────────────────────────────────────────────────────────────────

echo
success "Installation complete. Restart your shell or run: exec zsh"
