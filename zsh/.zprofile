# Homebrew
if [ -f /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -f /home/linuxbrew/.linuxbrew/bin/brew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Rye
export PATH="$HOME/.rye/shims:$PATH"

# macOS-specific
if [[ "$OSTYPE" == darwin* ]]; then
    export PATH=/Applications/Inkscape.app/Contents/MacOS:$PATH
fi
