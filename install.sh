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
#   ./install.sh --moom       Install only Moom Classic
#   ./install.sh --logi       Restore Logi Options+ mouse config
#   ./install.sh --macos      Apply macOS defaults (Dock, Finder, keyboard, trackpad)
#   ./install.sh --kanata     Install only kanata
#   ./install.sh --shared-mac  Like --mac but kanata only runs in your session
#   ./install.sh --check      Verify all dependencies are installed (dry run)
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
INSTALL_MOOM=false
INSTALL_BETTERDISPLAY=false
INSTALL_LOGI=false
INSTALL_MACOS=false
CHECK_ONLY=false
SHARED_MAC=false
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
  --moom       Moom Classic window manager presets (macOS only)
  --betterdisplay  BetterDisplay configuration (macOS only)
  --logi       Logi Options+ mouse configuration (macOS only)
  --macos      Apply macOS defaults (Dock, Finder, keyboard, trackpad)
  --kanata     Kanata keyboard remapper (macOS: LaunchDaemon, Linux: systemd)
  --shared-mac Like --mac but kanata only runs in your user session
  --check      Verify all dependencies are installed (dry run, no changes)
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
            INSTALL_MOOM=true
            INSTALL_BETTERDISPLAY=true
            INSTALL_LOGI=true
            INSTALL_MACOS=true
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
        --moom)     INSTALL_MOOM=true;     HAS_FLAGS=true ;;
        --betterdisplay) INSTALL_BETTERDISPLAY=true; HAS_FLAGS=true ;;
        --logi)     INSTALL_LOGI=true;     HAS_FLAGS=true ;;
        --macos)    INSTALL_MACOS=true;    HAS_FLAGS=true ;;
        --shared-mac)
            INSTALL_NVIM=true
            INSTALL_TMUX=true
            INSTALL_KANATA=true
            INSTALL_TERMINAL=true
            INSTALL_WEZTERM=true
            INSTALL_MOOM=true
            INSTALL_BETTERDISPLAY=true
            INSTALL_LOGI=true
            INSTALL_MACOS=true
            SHARED_MAC=true
            HAS_FLAGS=true
            ;;
        --check)    CHECK_ONLY=true;       HAS_FLAGS=true ;;
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

# ─── Dependency check (--check) ──────────────────────────────────────────────

if $CHECK_ONLY; then
    missing=0
    check_cmd() {
        if command -v "$1" &>/dev/null; then
            printf "  \033[1;32m✓\033[0m %s\n" "$1"
        else
            printf "  \033[1;31m✗\033[0m %s\n" "$1"
            missing=$((missing + 1))
        fi
    }
    check_dir() {
        if [ -d "$2" ]; then
            printf "  \033[1;32m✓\033[0m %s\n" "$1"
        else
            printf "  \033[1;31m✗\033[0m %s\n" "$1"
            missing=$((missing + 1))
        fi
    }
    check_app() {
        if ls /Applications/"$1"* &>/dev/null; then
            printf "  \033[1;32m✓\033[0m %s\n" "$1"
        else
            printf "  \033[1;31m✗\033[0m %s\n" "$1"
            missing=$((missing + 1))
        fi
    }

    echo
    info "Core tools"
    check_cmd brew
    check_cmd git
    check_cmd stow
    check_cmd zsh

    info "Terminal & shell"
    check_cmd fzf
    check_cmd fd
    check_cmd rg
    check_cmd starship
    check_cmd bat
    check_cmd tree
    check_cmd htop
    check_cmd wget
    check_cmd gh
    check_cmd lazygit
    check_dir "Oh My Zsh" "$HOME/.oh-my-zsh"

    info "Editors"
    check_cmd nvim
    check_cmd tmux
    check_cmd tmuxifier
    check_dir "TPM" "$HOME/.tmux/plugins/tpm"

    info "Languages & version managers"
    check_cmd go
    check_cmd node
    check_cmd pyenv
    check_cmd pipx
    check_dir "nvm" "$HOME/.nvm"

    if [[ "$OS" == "Darwin" ]]; then
        info "macOS apps"
        check_app "WezTerm"
        check_app "Moom"
        check_app "BetterDisplay"
        check_app "Karabiner"
        check_app "logioptionsplus"

        info "macOS services"
        if ps aux | grep -q '[k]anata'; then
            printf "  \033[1;32m✓\033[0m kanata (running)\n"
        else
            printf "  \033[1;31m✗\033[0m kanata (not running)\n"
            missing=$((missing + 1))
        fi
    fi

    info "Symlinks"
    for link in ~/.config/nvim ~/.config/tmux ~/.config/starship.toml ~/.zshrc ~/.config/kanata ~/.config/wezterm; do
        name="$(basename "$link")"
        if [ -L "$link" ] && [[ "$(readlink "$link")" == *dotfiles* ]]; then
            printf "  \033[1;32m✓\033[0m %s → dotfiles\n" "$name"
        elif [ -e "$link" ]; then
            printf "  \033[1;33m~\033[0m %s (exists but not linked to dotfiles)\n" "$name"
        else
            printf "  \033[1;31m✗\033[0m %s (missing)\n" "$name"
            missing=$((missing + 1))
        fi
    done

    echo
    if [ "$missing" -eq 0 ]; then
        success "All dependencies are installed!"
    else
        warn "$missing missing — run ./install.sh --mac to install everything"
    fi
    exit 0
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

# Add an app to login items (macOS only, idempotent)
ensure_login_item() {
    local app_name="$1"
    local app_path="$2"
    if [ ! -d "$app_path" ]; then return; fi
    if osascript -e "tell application \"System Events\" to get the name of every login item" 2>/dev/null | grep -q "$app_name"; then
        return
    fi
    info "Adding $app_name to login items..."
    osascript -e "tell application \"System Events\" to make login item at end with properties {path:\"$app_path\", hidden:false}" 2>/dev/null || true
}

# Compare two files; returns 0 (true) if identical or both missing
files_identical() {
    if [ ! -f "$1" ] || [ ! -f "$2" ]; then
        return 1
    fi
    cmp -s "$1" "$2"
}

# Compare a defaults domain against a saved plist; returns 0 if identical
defaults_identical() {
    local domain="$1" saved="$2"
    local tmp
    tmp=$(mktemp)
    defaults export "$domain" "$tmp" 2>/dev/null || { rm -f "$tmp"; return 1; }
    cmp -s "$tmp" "$saved"
    local rc=$?
    rm -f "$tmp"
    return $rc
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

    # Install all formulae and casks from Brewfile
    if [ -f "$DOTFILES_DIR/macos/Brewfile" ]; then
        info "Installing packages from Brewfile..."
        brew bundle --file="$DOTFILES_DIR/macos/Brewfile" --no-upgrade || warn "Some Brewfile entries failed (casks requiring sudo?) — continuing"
    fi

    success "Homebrew ready — all packages installed"
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
        # tmuxifier via git (not in Homebrew)
        if [ ! -d "$HOME/.tmuxifier" ]; then
            info "Installing tmuxifier..."
            git clone https://github.com/jimeh/tmuxifier.git "$HOME/.tmuxifier"
        fi
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

# ─── Moom Classic ────────────────────────────────────────────────────────────

if $INSTALL_MOOM; then
    if [[ "$OS" != "Darwin" ]]; then
        warn "Moom Classic is macOS only — skipping"
    else
        if ! ls /Applications/Moom* &>/dev/null; then
            warn "Moom Classic not found — install it from the App Store (Purchased tab)"
        fi

        if defaults_identical com.manytricks.Moom "$DOTFILES_DIR/moom/com.manytricks.Moom.plist"; then
            success "Moom Classic — already up to date (skipping restart)"
        else
            info "Importing Moom Classic presets..."
            killall "Moom Classic" 2>/dev/null || killall Moom 2>/dev/null || true
            defaults import com.manytricks.Moom "$DOTFILES_DIR/moom/com.manytricks.Moom.plist"
            open -a "Moom Classic" 2>/dev/null || open -a "Moom" 2>/dev/null || true
            success "Moom Classic ready — presets restored"
        fi
        ensure_login_item "Moom Classic" "/Applications/Moom Classic.app"
    fi
fi

# ─── BetterDisplay ──────────────────────────────────────────────────────────

if $INSTALL_BETTERDISPLAY; then
    if [[ "$OS" != "Darwin" ]]; then
        warn "BetterDisplay is macOS only — skipping"
    else
        if ! ls /Applications/BetterDisplay* &>/dev/null; then
            info "Installing BetterDisplay..."
            brew install --cask betterdisplay
        fi

        if defaults_identical pro.betterdisplay.BetterDisplay "$DOTFILES_DIR/betterdisplay/pro.betterdisplay.BetterDisplay.plist"; then
            success "BetterDisplay — already up to date (skipping restart)"
        else
            info "Importing BetterDisplay configuration..."
            killall BetterDisplay 2>/dev/null || true
            defaults import pro.betterdisplay.BetterDisplay "$DOTFILES_DIR/betterdisplay/pro.betterdisplay.BetterDisplay.plist"
            open -a "BetterDisplay" 2>/dev/null || true
            success "BetterDisplay ready — configuration restored"
        fi
        ensure_login_item "BetterDisplay" "/Applications/BetterDisplay.app"
    fi
fi

# ─── Logi Options+ ──────────────────────────────────────────────────────────

if $INSTALL_LOGI; then
    if [[ "$OS" != "Darwin" ]]; then
        warn "Logi Options+ is macOS only — skipping"
    else
        if ! ls /Applications/logioptionsplus* &>/dev/null; then
            info "Installing Logi Options+..."
            brew install --cask logi-options+ || warn "Logi Options+ requires sudo — install manually: brew install --cask logi-options+"
        fi

        LOGI_DIR="$HOME/Library/Application Support/LogiOptionsPlus"
        mkdir -p "$LOGI_DIR"

        if files_identical "$DOTFILES_DIR/logioptionsplus/settings.db" "$LOGI_DIR/settings.db" \
        && files_identical "$DOTFILES_DIR/logioptionsplus/macros.db" "$LOGI_DIR/macros.db"; then
            success "Logi Options+ — already up to date (skipping restart)"
        else
            info "Restoring Logi Options+ configuration..."
            killall "logioptionsplus" 2>/dev/null || true
            killall "LogiOptionsPlus" 2>/dev/null || true
            sleep 1
            cp "$DOTFILES_DIR/logioptionsplus/settings.db" "$LOGI_DIR/settings.db"
            cp "$DOTFILES_DIR/logioptionsplus/macros.db" "$LOGI_DIR/macros.db"
            open -a "logioptionsplus" 2>/dev/null || true
            success "Logi Options+ ready — mouse config restored"
        fi
    fi
fi

# ─── macOS defaults ─────────────────────────────────────────────────────────

if $INSTALL_MACOS; then
    if [[ "$OS" != "Darwin" ]]; then
        warn "macOS defaults only apply on macOS — skipping"
    else
        info "Applying macOS defaults..."
        bash "$DOTFILES_DIR/macos/macos-defaults.sh"
        success "macOS defaults applied"
    fi
fi

# ─── Kanata ──────────────────────────────────────────────────────────────────

if $INSTALL_KANATA; then
    info "Installing kanata..."

    backup_if_exists "$HOME/.config/kanata"

    if [[ "$OS" == "Darwin" ]]; then
        # ── Install kanata & Karabiner Elements (DEXT driver) ────────────
        # Kanata needs Karabiner's DriverKit virtual HID device to emit
        # remapped keystrokes. We only use the DEXT — not Karabiner's app.
        if [ ! -d "/Applications/Karabiner-Elements.app" ]; then
            info "Installing Karabiner Elements (virtual HID driver for kanata)..."
            brew install --cask karabiner-elements
        fi
        brew install kanata
        # Copy kanata binary to a stable path so macOS Input Monitoring
        # (TCC) permission survives brew upgrades. The Cellar path changes
        # with every version, invalidating the TCC entry.
        sudo cp "$(readlink -f /opt/homebrew/bin/kanata)" /usr/local/bin/kanata
        sudo chmod 755 /usr/local/bin/kanata
        link_package kanata --ignore='\.plist$' --ignore='\.service$' --ignore='\.rules$' --ignore='\.kdb$' --ignore='kanata-session-wrapper' --ignore='kanata-launcher'

        # Symlink the right config based on mode (both are editable in the repo).
        # If stow created a directory symlink for ~/.config/kanata/ pointing
        # into the repo, remove it — we need a real directory so ln -sf
        # doesn't create a circular symlink inside the repo.
        if [ -L "$HOME/.config/kanata" ]; then
            rm "$HOME/.config/kanata"
        fi
        mkdir -p "$HOME/.config/kanata"
        if $SHARED_MAC; then
            ln -sf "$DOTFILES_DIR/kanata/.config/kanata/kanata-shared.kdb" "$HOME/.config/kanata/kanata.kdb"
        else
            ln -sf "$DOTFILES_DIR/kanata/.config/kanata/kanata.kdb" "$HOME/.config/kanata/kanata.kdb"
        fi

        # ── Karabiner DEXT setup ──────────────────────────────────────────
        # Kanata needs two things from Karabiner:
        #   1. The DriverKit DEXT — activated & approved (macOS loads it at boot)
        #   2. The VirtualHIDDevice-Daemon — bridges kanata to the DEXT
        # It does NOT need: Karabiner-Elements app, grabber, or observer.

        # Check if DEXT is already activated
        if systemextensionsctl list 2>&1 | grep -q "org.pqrs.Karabiner-DriverKit-VirtualHIDDevice.*activated.*enabled"; then
            success "Karabiner DEXT — activated and enabled"
        else
            # Only run activation if not yet activated
            DEXT_ACTIVATE="/Applications/Karabiner-Elements.app/Contents/Library/Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager"
            if [ -x "$DEXT_ACTIVATE" ]; then
                info "Activating Karabiner DriverKit virtual HID device..."
                if [ "$EUID" -eq 0 ]; then
                    sudo -u "${SUDO_USER:-$(logname)}" "$DEXT_ACTIVATE" activate 2>&1 || true
                else
                    "$DEXT_ACTIVATE" activate 2>&1 || true
                fi
                sleep 3
                # Kill any Karabiner UI that may have opened during activation
                pkill -f "Karabiner-Elements" 2>/dev/null || true
                pkill -f "Karabiner-NotificationWindow" 2>/dev/null || true
            fi
            if systemextensionsctl list 2>&1 | grep -q "org.pqrs.Karabiner-DriverKit-VirtualHIDDevice.*activated.*enabled"; then
                success "Karabiner DEXT — activated and enabled"
            else
                warn "Karabiner DEXT needs manual approval:"
                warn "  1. Open Karabiner Elements from /Applications"
                warn "  2. Approve the system extension in System Settings → Privacy & Security"
                warn "  3. Close Karabiner Elements"
                warn "  4. Re-run: ./install.sh --kanata"
            fi
        fi

        # ── Disable Karabiner's own keyboard grabber ─────────────────────
        # Karabiner-Core-Service and other Karabiner processes grab keyboards
        # exclusively, causing "IOHIDDeviceOpen: not permitted" for kanata.
        # We only need the DEXT + VirtualHIDDevice-Daemon.
        info "Disabling Karabiner Elements services (only the DEXT driver is needed)..."
        # Use modern launchctl API to bootout and disable services.
        # System domain (root services: Core-Service, session_monitor)
        sudo launchctl list 2>/dev/null | grep -i karabiner | grep -iv VirtualHIDDevice \
            | awk '{print $3}' | while read -r label; do
            sudo launchctl bootout "system/$label" 2>/dev/null || true
            sudo launchctl disable "system/$label" 2>/dev/null || true
        done || true
        # User domain (user services: Elements app, Menu, console_user_server)
        launchctl list 2>/dev/null | grep -i karabiner | grep -iv VirtualHIDDevice \
            | awk '{print $3}' | while read -r label; do
            launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
            launchctl disable "gui/$(id -u)/$label" 2>/dev/null || true
        done || true
        # Also disable via legacy API for any plists not yet caught
        for plist in /Library/LaunchAgents/org.pqrs.* /Library/LaunchDaemons/org.pqrs.*; do
            [ -f "$plist" ] || continue
            case "$plist" in *VirtualHIDDevice*) continue ;; esac
            sudo launchctl unload -w "$plist" 2>/dev/null || true
        done
        # Kill any remaining Karabiner processes (except VirtualHIDDevice-Daemon and DEXT)
        KARABINER_PIDS=$(ps aux | grep -i karabiner | grep -v grep \
            | grep -v "VirtualHIDDevice-Daemon" \
            | grep -v "VirtualHIDDevice.dext" \
            | awk '{print $2}') || true
        if [ -n "$KARABINER_PIDS" ]; then
            echo "$KARABINER_PIDS" | xargs sudo kill -9 2>/dev/null || true
        fi
        osascript -e 'tell application "System Events" to delete login item "Karabiner-Elements"' 2>/dev/null || true
        sleep 2
        # Verify they're gone
        REMAINING=$(ps aux | grep -i karabiner | grep -v grep | grep -v "VirtualHIDDevice-Daemon" | grep -v "VirtualHIDDevice.dext") || true
        if [ -n "$REMAINING" ]; then
            warn "Some Karabiner processes are still running — they may need a reboot to fully stop"
        fi

        # ── Ensure VirtualHIDDevice-Daemon is running ────────────────────
        # This daemon bridges kanata to the DEXT. Without it:
        #   "driver activated: true, driver connected: false"
        VHID_DAEMON="/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon"
        if [ -x "$VHID_DAEMON" ]; then
            if ! pgrep -f "Karabiner-VirtualHIDDevice-Daemon" >/dev/null 2>&1; then
                info "Starting Karabiner VirtualHIDDevice daemon..."
                sudo "$VHID_DAEMON" &
                sleep 2
            fi
            if pgrep -f "Karabiner-VirtualHIDDevice-Daemon" >/dev/null 2>&1; then
                success "VirtualHIDDevice daemon — running"
            else
                warn "VirtualHIDDevice daemon failed to start"
            fi
        else
            warn "VirtualHIDDevice daemon not found at expected path"
            warn "  → Try: brew reinstall --cask karabiner-elements"
        fi

        # ── LaunchDaemon setup ───────────────────────────────────────────
        PLIST_SRC="$DOTFILES_DIR/kanata/com.jknafou.kanata.plist"
        PLIST_DST="/Library/LaunchDaemons/com.jknafou.kanata.plist"
        PLIST_TMP=$(mktemp)
        WATCHER_DST="/Library/LaunchDaemons/com.jknafou.kanata-watcher.plist"
        WRAPPER_DST="/usr/local/bin/kanata-session-wrapper.sh"
        LAUNCHER_DST="/usr/local/bin/kanata-launcher.sh"

        # Install launcher that kills conflicting Karabiner processes
        # before starting kanata (Karabiner-Core-Service grabs keyboards
        # at boot via SMAppService, which launchctl can't disable)
        sudo cp "$DOTFILES_DIR/kanata/kanata-launcher.sh" "$LAUNCHER_DST"
        sudo chmod 755 "$LAUNCHER_DST"

        # Build ProgramArguments based on shared-mac mode
        # Single-line XML to avoid BSD sed newline issues
        if $SHARED_MAC; then
            sudo cp "$DOTFILES_DIR/kanata/kanata-session-wrapper.sh" "$WRAPPER_DST"
            sudo chmod 755 "$WRAPPER_DST"
            KANATA_ARGS="<array><string>$WRAPPER_DST</string><string>$(whoami)</string><string>--cfg</string><string>$HOME/.config/kanata/kanata.kdb</string></array>"
        else
            KANATA_ARGS="<array><string>$LAUNCHER_DST</string><string>--cfg</string><string>$HOME/.config/kanata/kanata.kdb</string></array>"
        fi

        sed -e "s|__HOME__|$HOME|g" -e "s|__KANATA_PROGRAM_ARGS__|$KANATA_ARGS|g" "$PLIST_SRC" > "$PLIST_TMP"

        KANATA_NEEDS_RELOAD=false
        if ! files_identical "$PLIST_TMP" "$PLIST_DST"; then
            KANATA_NEEDS_RELOAD=true
        fi
        if ! files_identical "$DOTFILES_DIR/kanata/com.jknafou.kanata-watcher.plist" "$WATCHER_DST"; then
            KANATA_NEEDS_RELOAD=true
        fi
        # Also reload if the .kdb config changed (symlink target vs repo)
        if $SHARED_MAC; then
            KDB_SRC="$DOTFILES_DIR/kanata/.config/kanata/kanata-shared.kdb"
        else
            KDB_SRC="$DOTFILES_DIR/kanata/.config/kanata/kanata.kdb"
        fi
        if [ -L "$HOME/.config/kanata/kanata.kdb" ]; then
            if ! files_identical "$KDB_SRC" "$HOME/.config/kanata/kanata.kdb"; then
                KANATA_NEEDS_RELOAD=true
            fi
        else
            KANATA_NEEDS_RELOAD=true
        fi

        if $KANATA_NEEDS_RELOAD; then
            info "Installing LaunchDaemons (requires sudo)..."
            sudo mkdir -p /Library/Logs/Kanata

            # Only reload plists if they changed
            if ! files_identical "$PLIST_TMP" "$PLIST_DST"; then
                sudo cp "$PLIST_TMP" "$PLIST_DST"
                sudo chown root:wheel "$PLIST_DST"
                sudo chmod 644 "$PLIST_DST"
                if sudo launchctl list | grep -q com.jknafou.kanata; then
                    sudo launchctl unload "$PLIST_DST" 2>/dev/null || true
                fi
                sudo launchctl load "$PLIST_DST"
            fi

            if ! files_identical "$DOTFILES_DIR/kanata/com.jknafou.kanata-watcher.plist" "$WATCHER_DST"; then
                sudo cp "$DOTFILES_DIR/kanata/com.jknafou.kanata-watcher.plist" "$WATCHER_DST"
                sudo chown root:wheel "$WATCHER_DST"
                sudo chmod 644 "$WATCHER_DST"
                if sudo launchctl list | grep -q com.jknafou.kanata-watcher; then
                    sudo launchctl unload "$WATCHER_DST" 2>/dev/null || true
                fi
                sudo launchctl load "$WATCHER_DST"
            fi

            # If only the .kdb config changed, just signal kanata to restart
            # (KeepAlive will relaunch it with the new config)
            if ps aux | grep -q '[k]anata'; then
                info "Restarting kanata to pick up config changes..."
                sudo pkill -x kanata
            fi

            success "Kanata ready — reloaded"
        else
            success "Kanata — already up to date (skipping reload)"
        fi

        rm -f "$PLIST_TMP"

        # ── Check Input Monitoring permission (TCC) ────────────────────
        # kanata needs Input Monitoring even when running as root.
        # SIP prevents granting this programmatically — user must do it.
        # We check for /usr/local/bin/kanata (stable path that survives upgrades).
        HAS_INPUT_MONITORING=false
        if sqlite3 "/Library/Application Support/com.apple.TCC/TCC.db" \
            "SELECT auth_value FROM access WHERE service='kTCCServiceListenEvent' AND client='/usr/local/bin/kanata' AND auth_value=2" 2>/dev/null \
            | grep -q "2"; then
            HAS_INPUT_MONITORING=true
        fi
        if ! $HAS_INPUT_MONITORING; then
            warn "kanata needs Input Monitoring permission (one-time setup):"
            warn "  1. System Settings → Privacy & Security → Input Monitoring"
            warn "  2. Click + → press ⌘⇧G → type: /usr/local/bin/kanata"
            warn "  3. Enable it, then re-run: ./install.sh --kanata"
        fi

        # ── Verify kanata is running ─────────────────────────────────────
        sleep 3
        if ps aux | grep -q '[k]anata'; then
            success "Kanata is running"
        else
            if ! $HAS_INPUT_MONITORING; then
                warn "Kanata is not running — grant Input Monitoring first (see above)"
            else
                warn "Kanata is not running — check logs:"
                warn "  sudo cat /Library/Logs/Kanata/kanata.err.log"
                warn "  sudo cat /Library/Logs/Kanata/kanata.out.log"
            fi
        fi

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
