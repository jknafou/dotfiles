# dotfiles

Personal development environment — neovim, tmux, zsh, starship, and kanata — managed with [GNU Stow](https://www.gnu.org/software/stow/).

Works on **macOS** and **Linux**.

## Quick start

```bash
git clone https://github.com/jknafou/dotfiles ~/dotfiles
cd ~/dotfiles
./install.sh              # everything except kanata
./install.sh --mac        # everything including kanata (always on)
./install.sh --shared-mac # like --mac but kanata only runs in your session
```

`--shared-mac` can also be combined with individual flags (e.g. `--kanata --shared-mac`).

### Manual steps

Some components need interactive setup:

- **Karabiner-Elements** — required by kanata. The installer will open it and prompt you to approve the system extension in **System Settings > Privacy & Security**, then reboot.
- **Logi Options+** — requires sudo: `brew install --cask logi-options+`
- **Moom Classic** — install from the App Store (Purchased tab), then re-run `./install.sh --moom` to import presets.

## Modules

| Flag | What it installs |
|------|-----------------|
| `--nvim` | Neovim config with Lazy.nvim, LSP, Telescope, Treesitter, Harpoon, and 30+ plugins |
| `--tmux` | Tmux config with Catppuccin theme, vim-tmux-navigator, and TPM |
| `--terminal` | Zsh (Oh My Zsh + autosuggestions + syntax highlighting), Starship prompt, fzf, pyenv, nvm |
| `--kanata` | Kanata keyboard remapper with home-row mods (macOS: LaunchDaemon, Linux: systemd) |
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
└── kanata/                  # Config + LaunchDaemon plist + systemd service
```

Each directory is a [Stow package](https://www.gnu.org/software/stow/) — it mirrors the target file layout relative to `$HOME`. Existing configs are backed up as `.bak` before symlinking.

## Cross-platform

| | macOS | Linux |
|---|---|---|
| Package manager | Homebrew | apt / dnf / pacman (auto-detected) |
| Kanata daemon | LaunchDaemon | systemd service |
| Shell tools | Homebrew | Official installers (starship, pyenv, nvm) + system packages |

The `.zshrc` and `.zprofile` use runtime detection (`$OSTYPE`, `command -v`) so the same files work on both platforms.

## Syncing changes across machines

Configs are symlinked — editing `~/.config/tmux/tmux.conf` directly modifies the repo.

```bash
# After editing any config
cd ~/dotfiles && git add -A && git commit -m "update tmux" && git push

# On another machine
cd ~/dotfiles && git pull
```

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

Installed automatically by the installer:

`neovim` `tmux` `tmuxifier` `fzf` `fd` `ripgrep` `starship` `stow` `pyenv` `nvm` `node` `go` `kanata`

## Uninstall

Remove symlinks without deleting configs:

```bash
cd ~/dotfiles
stow -D nvim tmux zsh starship kanata
```
