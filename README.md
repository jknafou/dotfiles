# dotfiles

Personal development environment — neovim, tmux, zsh, starship, and kanata — managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Quick start

```bash
git clone https://github.com/jknafou/dotfiles ~/dotfiles
cd ~/dotfiles
./install.sh        # everything except kanata
./install.sh --mac  # everything including kanata
```

## Modules

| Flag | What it installs |
|------|-----------------|
| `--nvim` | Neovim config with Lazy.nvim, LSP, Telescope, Treesitter, Harpoon, and 30+ plugins |
| `--tmux` | Tmux config with Catppuccin theme, vim-tmux-navigator, and TPM |
| `--terminal` | Zsh (Oh My Zsh + autosuggestions + syntax highlighting), Starship prompt, fzf, pyenv, nvm |
| `--kanata` | Kanata keyboard remapper with home-row mods and macOS LaunchDaemon |
| `--mac` | All of the above |

Running without flags installs everything **except** kanata. Flags can be combined.

## Structure

```
dotfiles/
├── install.sh
├── nvim/.config/nvim/       # Neovim (Lazy.nvim + plugins)
├── tmux/.config/tmux/       # Tmux (Catppuccin + TPM)
├── zsh/                     # .zshrc, .zprofile
├── starship/.config/        # Starship prompt (Catppuccin Mocha)
└── kanata/                  # Kanata config + LaunchDaemon plist
```

Each directory is a [Stow package](https://www.gnu.org/software/stow/) — it mirrors the target file layout relative to `$HOME`. Existing configs are backed up as `.bak` before symlinking.

## Key bindings (Kanata)

Home-row mods on the base layer:

| Key | Tap | Hold |
|-----|-----|------|
| `Caps Lock` | `Esc` | Arrow layer |
| `A` | `a` | `Super` |
| `S` | `s` | `Alt` |
| `D` | `d` | `Shift` |
| `F` | `f` | `Ctrl` |
| `G` / `H` | `g` / `h` | Fn layer |
| `J` | `j` | `Ctrl` |
| `K` | `k` | `Shift` |
| `L` | `l` | `Alt` |
| `;` | `;` | `Super` |

Arrow layer maps `H J K L` to arrow keys and `;` to Backspace.

## Dependencies

Installed automatically via [Homebrew](https://brew.sh/):

`neovim` `tmux` `tmuxifier` `fzf` `fd` `ripgrep` `starship` `stow` `pyenv` `nvm` `node` `go` `kanata`

## Uninstall

To remove symlinks without deleting configs:

```bash
cd ~/dotfiles
stow -D nvim tmux zsh starship kanata
```
