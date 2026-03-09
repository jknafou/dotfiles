
# Setting PATH for Python 3.10
# The original version is saved in .zprofile.pysave
PATH="/Library/Frameworks/Python.framework/Versions/3.10/bin:${PATH}"
export PATH

# Setting PATH for Python 2.7
# The original version is saved in .zprofile.pysave
PATH="/Library/Frameworks/Python.framework/Versions/2.7/bin:${PATH}"
export PATH

eval "$(/opt/homebrew/bin/brew shellenv)"
export PATH=/Applications/Inkscape.app/Contents/MacOS:$PATH
export PATH="$HOME/.rye/shims:$PATH"

eval "$(/opt/homebrew/bin/brew shellenv)"
