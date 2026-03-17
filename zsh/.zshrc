# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Plugins
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
bindkey '^ ' autosuggest-accept

source $ZSH/oh-my-zsh.sh

# ─── Development tools ──────────────────────────────────────────────────────

# pyenv
if command -v pyenv &>/dev/null; then
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
fi

# Rye
[ -f "$HOME/.rye/env" ] && . "$HOME/.rye/env"
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# Starship prompt
eval "$(starship init zsh)"

# Compilers
export CXX=g++
export CC=gcc

# Go
if command -v go &>/dev/null; then
    export PATH="$(go env GOPATH)/bin:$PATH"
elif [ -d "$HOME/apps/go1.23.4" ]; then
    export PATH="$HOME/apps/go1.23.4/bin:$PATH"
fi

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# npm global
[ -d "$HOME/.npm-global/bin" ] && export PATH="$HOME/.npm-global/bin:$PATH"

# tmuxifier
if command -v tmuxifier &>/dev/null; then
    export PATH="$HOME/.tmuxifier/bin:$PATH"
    eval "$(tmuxifier init -)"
fi

# fzf
if command -v fzf &>/dev/null; then
    [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
    source <(fzf --zsh)
fi

# ─── Aliases ─────────────────────────────────────────────────────────────────

alias fcd='cd "$(fd --type d --hidden --exclude ".*" . | fzf)"'
alias fnvim='nvim "$(fd --type f --hidden --exclude ".*" . | fzf)"'

# ─── Kanata ─────────────────────────────────────────────────────────────────

if [[ "$OSTYPE" == darwin* ]]; then
    kanata_on() {
        sudo launchctl bootstrap system /Library/LaunchDaemons/com.jknafou.vhid-daemon.plist 2>/dev/null || true
        sudo launchctl bootstrap system /Library/LaunchDaemons/com.jknafou.kanata.plist 2>/dev/null || true
        sudo launchctl kickstart -k system/com.jknafou.kanata 2>/dev/null || true
        echo "kanata started"
    }

    kanata_off() {
        sudo launchctl bootout system/com.jknafou.kanata 2>/dev/null || true
        sudo pkill -x kanata 2>/dev/null || true
        echo "kanata stopped"
    }
fi

# ─── Local overrides ────────────────────────────────────────────────────────

export PATH="$HOME/.local/bin:$PATH"

# Homebrew extras (util-linux, etc.)
if [[ "$OSTYPE" == darwin* ]] && [ -d /opt/homebrew/opt/util-linux ]; then
    export PATH="/opt/homebrew/opt/util-linux/bin:$PATH"
    export PATH="/opt/homebrew/opt/util-linux/sbin:$PATH"
fi

# Machine-specific overrides (not tracked in dotfiles)
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
