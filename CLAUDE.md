# Claude Code Project Context

## Kanata (macOS keyboard remapper)

### Architecture
kanata on macOS requires three components:
1. **Karabiner DEXT** — DriverKit system extension, activated once, macOS loads at boot
2. **VirtualHIDDevice-Daemon** — bridges kanata to the DEXT (LaunchDaemon: `com.jknafou.vhid-daemon`)
3. **kanata** — grabs keyboards via IOHIDManager, remaps through DEXT (LaunchDaemon: `com.jknafou.kanata`)

### Critical details
- **Karabiner-Core-Service conflicts**: It grabs keyboards exclusively. The launcher (`kanata-launcher.sh`) kills it RIGHT BEFORE exec-ing kanata — no delay between kill and exec, or Karabiner respawns and grabs first.
- **TCC/Input Monitoring**: Required even for root LaunchDaemons on macOS 26+. Permission is tied to the **exact binary hash** (not path). The Cellar path changes on brew upgrade, invalidating TCC. kanata is pinned with `brew pin kanata`.
- **Boot timing**: DEXT and VirtualHIDDevice-Daemon may not be ready when kanata starts. The launcher waits up to 60s for both before starting kanata.
- **`--nodelay` flag**: Must be used when running kanata as a daemon (skips 2s keyboard-release wait).

### Files
- `kanata/kanata-launcher.sh` → deployed to `/usr/local/bin/kanata-launcher.sh`
- `kanata/com.jknafou.kanata.plist` → template (uses `__KANATA_PROGRAM_ARGS__` placeholder)
- `kanata/com.jknafou.vhid-daemon.plist` → VirtualHIDDevice-Daemon LaunchDaemon
- `kanata/com.jknafou.kanata-watcher.plist` → watches /dev for keyboard hotplug
- `kanata/.config/kanata/kanata.kdb` → home-row mods config (symlinked)

### Shell functions
`kanata_on` / `kanata_off` in `zsh/.zshrc` — control the LaunchDaemon.

### Fresh Mac install
1. `./install.sh --kanata` (installs everything)
2. If DEXT not activated: open Karabiner Elements once, approve in System Settings → Privacy & Security
3. Grant Input Monitoring for the kanata Cellar binary path shown by the installer
4. Re-run `./install.sh --kanata`

## Working practices
- **Don't layer untested fixes**: For system-level changes (LaunchDaemons, launchctl, TCC), verify each change works (including reboot) before committing.
- **stow creates symlinks**: `git pull` auto-applies config changes for stow-managed files (starship, wezterm, zsh). No install needed.
- **BSD sed**: macOS sed can't handle newlines in replacement patterns. Use single-line values.
