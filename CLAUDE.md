# Claude Code Project Context

## Kanata (macOS keyboard remapper)

### Architecture
kanata on macOS requires three components:
1. **Karabiner DEXT** — DriverKit system extension, activated once, macOS loads at boot
2. **VirtualHIDDevice-Daemon** — bridges kanata to the DEXT (LaunchDaemon: `com.jknafou.vhid-daemon`)
3. **kanata** — grabs keyboards via IOHIDManager, remaps through DEXT (LaunchDaemon: `com.jknafou.kanata`)

### Two modes
- **`--kanata`** (personal Mac): kanata auto-starts at boot via LaunchDaemon
- **`--shared-mac`** (multi-user): kanata starts at installing user's login, stops at any logout. All users can `kanata_on`/`kanata_off`.

### Critical details
- **Karabiner-Core-Service conflicts**: It grabs keyboards exclusively. The launcher (`kanata-launcher.sh`) kills it RIGHT BEFORE exec-ing kanata — no delay between kill and exec, or Karabiner respawns and grabs first.
- **TCC/Input Monitoring**: Required even for root LaunchDaemons on macOS 26+. Permission is tied to the **exact binary hash** (not path). The Cellar path changes on brew upgrade, invalidating TCC. kanata is pinned with `brew pin kanata`.
- **Boot timing**: DEXT and VirtualHIDDevice-Daemon may not be ready when kanata starts. The launcher waits up to 60s for both before starting kanata.
- **`--nodelay` flag**: Must be used when running kanata as a daemon (skips 2s keyboard-release wait).

### Files
- `kanata/kanata-launcher.sh` → `/usr/local/bin/kanata-launcher.sh`
- `kanata/kanata_on` → `/usr/local/bin/kanata_on` (available to all users)
- `kanata/kanata_off` → `/usr/local/bin/kanata_off` (available to all users)
- `kanata/kanata-sudoers` → `/etc/sudoers.d/kanata` (passwordless for all users)
- `kanata/kanata-logout-hook.sh` → `/usr/local/bin/kanata-logout-hook.sh` (--shared-mac only)
- `kanata/com.jknafou.kanata.plist` → template (uses `__KANATA_PROGRAM_ARGS__` placeholder)
- `kanata/com.jknafou.kanata-login.plist` → LaunchAgent for --shared-mac auto-start at login
- `kanata/com.jknafou.vhid-daemon.plist` → VirtualHIDDevice-Daemon LaunchDaemon
- `kanata/com.jknafou.kanata-watcher.plist` → watches /dev for keyboard hotplug
- `kanata/.config/kanata/kanata.kdb` → home-row mods config (symlinked)

### Fresh Mac install
1. `./install.sh --kanata` or `./install.sh --shared-mac`
2. If DEXT not activated: open Karabiner Elements once, approve in System Settings → Privacy & Security
3. Grant Input Monitoring for the kanata Cellar binary path shown by the installer
4. Re-run the install command

### Debugging checklist
If kanata isn't working after install or reboot, check in order:
1. **Is kanata running?** `ps aux | grep kanata`
2. **DEXT activated?** `systemextensionsctl list 2>&1 | grep karabiner` → should say `[activated enabled]`
3. **VirtualHIDDevice-Daemon running?** `pgrep -f VirtualHIDDevice-Daemon`
4. **Karabiner conflicts?** `ps aux | grep -i karabiner | grep -v VirtualHIDDevice` → should be empty (Core-Service grabs keyboards)
5. **TCC/Input Monitoring?** `sudo sqlite3 "/Library/Application Support/com.apple.TCC/TCC.db" "SELECT client FROM access WHERE service='kTCCServiceListenEvent' AND client LIKE '%kanata%'"` → must match current Cellar path
6. **Logs:** `sudo cat /Library/Logs/Kanata/kanata.err.log` and `sudo cat /Library/Logs/Kanata/kanata.out.log`
7. **Quick fix:** Kill Karabiner conflicts and restart: `ps aux | grep -i karabiner | grep -v grep | grep -v VirtualHIDDevice | awk '{print $2}' | xargs sudo kill -9; sudo pkill -x kanata`

### Current status (2026-03-17)
- **Personal Mac**: `--kanata` working, survives reboot. kanata_on/kanata_off in `/usr/local/bin/`.
- **Shared Mac**: `--shared-mac` just deployed — needs testing. If `kanata_on` is "command not found", the install script may not have deployed scripts to `/usr/local/bin/`. Check: `ls /usr/local/bin/kanata_on`. If missing, re-run `./install.sh --shared-mac`. The install deploys: scripts to `/usr/local/bin/`, sudoers to `/etc/sudoers.d/kanata`, LaunchAgent for login auto-start, LogoutHook for session close.

## Working practices
- **Don't layer untested fixes**: For system-level changes (LaunchDaemons, launchctl, TCC), verify each change works (including reboot) before committing.
- **stow creates symlinks**: `git pull` auto-applies config changes for stow-managed files (starship, wezterm, zsh). No install needed.
- **BSD sed**: macOS sed can't handle newlines in replacement patterns. Use single-line values.
