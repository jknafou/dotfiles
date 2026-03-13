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
#   ./install.sh --hpc        Install everything without sudo (HPC/cluster)
#   ./install.sh --nvim       Install only neovim
#   ./install.sh --tmux       Install only tmux
#   ./install.sh --terminal   Install only shell environment
#   ./install.sh --wezterm    Install only wezterm
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
INSTALL_WEZTERM=false
HPC_MODE=false
HAS_FLAGS=false

# ─── Usage ───────────────────────────────────────────────────────────────────

usage() {
    cat <<EOF
Usage: ./install.sh [OPTIONS]

Options:
  --mac        Install everything (including kanata)
  --hpc        Install everything without sudo (HPC/cluster environments)
  --nvim       Neovim configuration
  --tmux       Tmux configuration and plugin manager
  --terminal   Zsh, Starship, fzf, and development tools
  --wezterm    WezTerm terminal emulator configuration (macOS only)
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
            INSTALL_WEZTERM=true
            HAS_FLAGS=true
            ;;
        --hpc)
            INSTALL_NVIM=true
            INSTALL_TMUX=true
            INSTALL_TERMINAL=true
            HPC_MODE=true
            HAS_FLAGS=true
            ;;
        --nvim)     INSTALL_NVIM=true;     HAS_FLAGS=true ;;
        --tmux)     INSTALL_TMUX=true;     HAS_FLAGS=true ;;
        --wezterm)  INSTALL_WEZTERM=true;  HAS_FLAGS=true ;;
        --kanata)   INSTALL_KANATA=true;   HAS_FLAGS=true ;;
        --terminal) INSTALL_TERMINAL=true; INSTALL_WEZTERM=true; HAS_FLAGS=true ;;
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
    if $HPC_MODE; then
        warn "Skipping system package install (HPC mode, no sudo): $*"
        return 1
    elif command -v brew &>/dev/null; then
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

# ─── HPC helpers (no sudo, install to ~/.local) ───────────────────────────────

LOCAL_BIN="$HOME/.local/bin"
LOCAL_PREFIX="$HOME/.local"

hpc_ensure_dirs() {
    mkdir -p "$LOCAL_BIN" "$LOCAL_PREFIX"
}

hpc_install_stow() {
    if command -v stow &>/dev/null; then return 0; fi
    info "Installing stow from source (HPC)..."
    local tmp
    tmp=$(mktemp -d)
    curl -sL https://ftp.gnu.org/gnu/stow/stow-2.4.1.tar.gz | tar xz -C "$tmp"
    cd "$tmp/stow-2.4.1"
    ./configure --prefix="$LOCAL_PREFIX"
    make install
    cd "$DOTFILES_DIR"
    rm -rf "$tmp"
}

hpc_install_nvim() {
    if command -v nvim &>/dev/null; then return 0; fi
    info "Installing Neovim from prebuilt tarball (HPC)..."
    local tmp
    tmp=$(mktemp -d)
    curl -sL https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz | tar xz -C "$tmp"
    rm -rf "$LOCAL_PREFIX/nvim-linux-x86_64"
    mv "$tmp/nvim-linux-x86_64" "$LOCAL_PREFIX/"
    ln -sf "$LOCAL_PREFIX/nvim-linux-x86_64/bin/nvim" "$LOCAL_BIN/nvim"
    rm -rf "$tmp"
}

hpc_install_fd() {
    if command -v fd &>/dev/null; then return 0; fi
    info "Installing fd from GitHub release (HPC)..."
    local tmp
    tmp=$(mktemp -d)
    local version
    version=$(curl -sI https://github.com/sharkdp/fd/releases/latest | grep -i '^location:' | grep -oP 'v[\d.]+' | head -1)
    curl -sL "https://github.com/sharkdp/fd/releases/download/${version}/fd-${version}-x86_64-unknown-linux-musl.tar.gz" | tar xz -C "$tmp"
    cp "$tmp"/fd-*/fd "$LOCAL_BIN/"
    rm -rf "$tmp"
}

hpc_install_rg() {
    if command -v rg &>/dev/null; then return 0; fi
    info "Installing ripgrep from GitHub release (HPC)..."
    local tmp
    tmp=$(mktemp -d)
    local version
    version=$(curl -sI https://github.com/BurntSushi/ripgrep/releases/latest | grep -i '^location:' | grep -oP '[\d.]+$' | head -1)
    curl -sL "https://github.com/BurntSushi/ripgrep/releases/download/${version}/ripgrep-${version}-x86_64-unknown-linux-musl.tar.gz" | tar xz -C "$tmp"
    cp "$tmp"/ripgrep-*/rg "$LOCAL_BIN/"
    rm -rf "$tmp"
}

hpc_install_fzf() {
    if command -v fzf &>/dev/null; then return 0; fi
    info "Installing fzf (HPC)..."
    git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
    "$HOME/.fzf/install" --bin
    ln -sf "$HOME/.fzf/bin/fzf" "$LOCAL_BIN/fzf"
}

hpc_install_starship() {
    if command -v starship &>/dev/null; then return 0; fi
    info "Installing Starship (HPC)..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y --bin-dir "$LOCAL_BIN"
}

# ─── Package manager ────────────────────────────────────────────────────────

if $HPC_MODE; then
    info "HPC mode — installing without sudo to ~/.local"
    hpc_ensure_dirs
    export PATH="$LOCAL_BIN:$PATH"
    hpc_install_stow
    success "HPC prerequisites ready"
elif [[ "$OS" == "Darwin" ]]; then
    if ! command -v brew &>/dev/null; then
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
    fi
    success "Homebrew ready"
else
    info "Detected Linux — using system package manager"
fi

if ! $HPC_MODE; then
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
fi

# ─── Neovim ──────────────────────────────────────────────────────────────────

if $INSTALL_NVIM; then
    info "Installing neovim..."
    if $HPC_MODE; then
        hpc_install_nvim
        hpc_install_rg
        hpc_install_fd
    else
        pkg_install neovim ripgrep fd
    fi

    backup_if_exists "$HOME/.config/nvim"
    link_package nvim

    success "Neovim ready"
fi

# ─── Tmux ────────────────────────────────────────────────────────────────────

if $INSTALL_TMUX; then
    info "Installing tmux..."
    if $HPC_MODE; then
        command -v tmux &>/dev/null || warn "tmux not found — install it via your HPC admin or module system"
    else
        pkg_install tmux
        command -v brew &>/dev/null && brew install tmuxifier
    fi

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

    if $HPC_MODE; then
        hpc_install_fzf
        hpc_install_fd
        hpc_install_rg
        hpc_install_starship
        # pyenv via official installer
        if ! command -v pyenv &>/dev/null; then
            info "Installing pyenv (HPC)..."
            curl -sS https://pyenv.run | bash
        fi
        # nvm via official installer
        if [ ! -d "$HOME/.nvm" ]; then
            info "Installing nvm (HPC)..."
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
        fi
        # Go via module system
        if ! command -v go &>/dev/null; then
            if type module &>/dev/null && module avail Go 2>&1 | grep -q Go; then
                info "Loading Go via module system..."
                module load Go
            else
                warn "Go not found — load it via module system or install manually"
            fi
        fi
    elif command -v brew &>/dev/null; then
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

    # HPC-specific local overrides (not tracked in dotfiles)
    if $HPC_MODE && [ ! -f "$HOME/.zshrc.local" ]; then
        info "Creating ~/.zshrc.local with HPC-specific settings..."
        cat > "$HOME/.zshrc.local" <<'ZSHLOCAL'
# HPC environment — auto-generated by dotfiles installer (--hpc)

# Suppress bash-only function from /etc/profile.d that errors in zsh
print_for_bash_shell() { : }

# Load Go via module system
if type module &>/dev/null 2>&1; then
    module load Go 2>/dev/null
    command -v go &>/dev/null && export PATH="$(go env GOPATH)/bin:$PATH"
fi

# pyenv (installed to ~/.pyenv on HPC)
export PYENV_ROOT="$HOME/.pyenv"
[[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"

# ─── Nvim on local SSD (/tmp) for faster I/O ─────────────────────────────────
# Network filesystems have high latency for small reads; use local disk.
NVIM_LOCAL="/tmp/${USER}-nvim"

nvim-sync() {
    mkdir -p "$NVIM_LOCAL"/{share,state,cache}
    rsync -a --delete ~/.local/share/nvim/ "$NVIM_LOCAL/share/nvim/"
    rsync -a --delete ~/.local/state/nvim/  "$NVIM_LOCAL/state/nvim/"  2>/dev/null
    rsync -a --delete ~/.cache/nvim/        "$NVIM_LOCAL/cache/nvim/"  2>/dev/null
    echo "Synced nvim data to $NVIM_LOCAL"
}

nvim-sync-back() {
    [ -d "$NVIM_LOCAL/share/nvim" ] || return
    rsync -a --delete "$NVIM_LOCAL/share/nvim/" ~/.local/share/nvim/
    rsync -a --delete "$NVIM_LOCAL/state/nvim/"  ~/.local/state/nvim/  2>/dev/null
    rsync -a --delete "$NVIM_LOCAL/cache/nvim/"  ~/.cache/nvim/        2>/dev/null
    echo "Synced nvim data back to home"
}

if [ ! -d "$NVIM_LOCAL/share/nvim/lazy" ]; then
    nvim-sync 2>/dev/null
fi

nvim() {
    XDG_DATA_HOME="$NVIM_LOCAL/share" \
    XDG_STATE_HOME="$NVIM_LOCAL/state" \
    XDG_CACHE_HOME="$NVIM_LOCAL/cache" \
    command nvim "$@"
}
ZSHLOCAL
        success "Created ~/.zshrc.local"
    fi

    success "Terminal ready"
fi

# ─── WezTerm ────────────────────────────────────────────────────────────────

if $INSTALL_WEZTERM; then
    info "Installing WezTerm configuration..."

    if [[ "$OS" == "Darwin" ]]; then
        if ! command -v wezterm &>/dev/null; then
            brew install --cask wezterm
        fi
    else
        warn "WezTerm install is macOS only — skipping binary install on Linux"
    fi

    backup_if_exists "$HOME/.config/wezterm"
    link_package wezterm

    success "WezTerm ready"
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

        # Watcher: restarts kanata when keyboards are connected/disconnected
        WATCHER_DST="/Library/LaunchDaemons/com.jknafou.kanata-watcher.plist"
        info "Installing kanata-watcher LaunchDaemon..."
        sudo cp "$DOTFILES_DIR/kanata/com.jknafou.kanata-watcher.plist" "$WATCHER_DST"
        sudo chown root:wheel "$WATCHER_DST"
        sudo chmod 644 "$WATCHER_DST"

        if sudo launchctl list | grep -q com.jknafou.kanata-watcher; then
            sudo launchctl unload "$WATCHER_DST" 2>/dev/null || true
        fi
        sudo launchctl load "$WATCHER_DST"

        success "Kanata ready — LaunchDaemon running (with keyboard hot-plug watcher)"

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

        # udev rule: restarts kanata when keyboards are connected/disconnected
        info "Installing udev rule for keyboard hot-plug..."
        sudo cp "$DOTFILES_DIR/kanata/99-kanata-reload.rules" /etc/udev/rules.d/
        sudo udevadm control --reload-rules

        success "Kanata ready — systemd service running (with keyboard hot-plug watcher)"
    fi
fi

# ─── Done ────────────────────────────────────────────────────────────────────

echo
success "Installation complete. Restart your shell or run: exec zsh"
