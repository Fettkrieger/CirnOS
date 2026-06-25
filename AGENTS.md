# CirnOS — Agent Reference

Multi-host NixOS flake + Home Manager for user `krieger`. Wayland-only desktop
built on Niri + Noctalia. Two hosts: a Lenovo ThinkPad (`lenuwu-nix`) and an
HP Envy x360 (`hp-nix`). This file is the navigation map for agents working
in the repo.

## Quick facts

- Flake inputs: `nixpkgs` (nixos-unstable), `home-manager`, `niri` (sodiboo/niri-flake),
  `noctalia` (noctalia-dev/noctalia-shell).
- Kernel (both hosts): official Nixpkgs latest kernel via `pkgs.linuxPackages_latest`.
  Roll back a host to the default stock kernel with `pkgs.linuxPackages` if needed.
- `nixosConfigurations`: `lenuwu-nix`, `hp-nix`. Both built via the `mkHost` helper in `flake.nix`.
- Display manager: `greetd` on tty1. It auto-starts `krieger` into `niri-session`
  once, then falls back to `agreety --cmd niri-session` if the session exits.
  Noctalia is the first visible password prompt via its in-session lockscreen.
- Compositor: Niri (system module from niri-flake; user config from `home/niri.nix`).
- Shell: Noctalia (bar / notifications / control-center / launcher) — HM module from the noctalia flake.
- Theme: Noctalia v5 Catppuccin + Adwaita-dark GTK/Qt; static Catppuccin Mocha Blue cursor.
- Audio: PipeWire (no PulseAudio); rtkit on. Audio control via Noctalia.
- Network: NetworkManager (+ openvpn plugin).
- Locale: `en_US.UTF-8` with `de_CH.UTF-8` formats. TZ Europe/Zurich. Console `sg`, XKB `ch` (overridden to `de` on `lenuwu-nix`).
- `system.stateVersion = "24.11"`, `home.stateVersion = "24.11"`.
- Git identity: Krieger / `leandro.tiziani@protonmail.com`, openpgp signing.
- Auto-upgrade: enabled in `common.nix`, force-disabled on the laptop.

## Repo layout

```
flake.nix                 entry point + mkHost
flake.lock                pinned inputs
modules/
  common.nix              shared system config (boot, locale, greetd/Niri login, portals, PipeWire, fwupd, auto-upgrade, ssh, ...)
  programs.nix            system packages + fonts; wraps footage with GDK_BACKEND=x11
  firewall.nix            host-aware firewall (laptop = roaming → SSH and dev ports closed)
  logiops.nix             Logitech MX Master 4 for Business: patched logiops daemon + heavily-commented /etc/logid.cfg + Solaar (via hardware.logitech.wireless)
hosts/
  lenuwu-nix/
    default.nix           ThinkPad E16 Gen 2 AMD specifics
    power.nix             TLP + event-based brightness/profile policy + hibernate setup
    hardware-configuration.nix   generated, do not edit
  hp-nix/
    default.nix           HP Envy x360 13-bd0xxx (Intel Tiger Lake) specifics
    power.nix             power-profiles-daemon + thermald
    hardware-configuration.nix   generated, do not edit
home/
  default.nix             HM entry point; conditional imports
  shellAliases.nix        rebuild / update / cleanup / git / tlp aliases
  default-apps.nix        XDG MIME defaults (code, firefox, gthumb, mpv, nautilus)
  themes.nix              GTK + Qt + cursor pack (all Catppuccin Mocha variants)
  ghostty.nix             Ghostty terminal (transparent + blur, theme=noctalia)
  syncthing.nix           Syncthing (web-UI overrides preserved)
  niri.nix                Niri settings (outputs, keybinds, swayidle)
  gaming.nix              user-level gaming packages (only imported if enableGaming)
  workspaces-hp.nix       named workspaces A/B/C — imported on hp-nix and lenuwu-nix
  defaultwindows.nix      multi-monitor startup layout (NOT currently imported)
  noctalia/
    noctalia.nix          imports the v5 HM module and declares the core TOML-backed shell config
docs/lenuwu-nix-migration.md   disk-transplant checklist
possible improvements.txt      2026-02-15 review notes (open items)
```

## Hosts

### `lenuwu-nix` — Lenovo ThinkPad E16 Gen 2 AMD (21M5002DGE)

- AMD CPU + Radeon iGPU. `enableGaming = true`.
- `boot.kernelPackages = pkgs.linuxPackages_latest`. If RTL8852CE Wi-Fi regresses
  on the latest stock kernel track, rollback to `pkgs.linuxPackages`.
- Wi-Fi/BT race workaround: `rtw89_8852ce` is blacklisted; a oneshot
  `rtw89-8852ce-delayed.service` waits for `bluetooth.service` then
  `modprobe`s it after a 10 s sleep.
- Touchpad via libinput (natural scroll, tap, clickfinger).
- Bluetooth on, `powerOnBoot = false`, blueman without applet.
- Steam, gamescope (capSysNice), gamemode, gpu-screen-recorder, brightnessctl,
  pciutils/usbutils/iw/lm_sensors/smartmontools/nvme-cli/powertop.
- Keyboard: `layout = "de"`, console `de` (forced).
- SSH force-disabled. `system.autoUpgrade` force-disabled.
- Power management (`power.nix`):
  - TLP enabled with `tlp-pd`. `TLP_AUTO_SWITCH = 0` — the custom policy below
    owns event-based profile switching. `power-saver` is selected on battery
    at <=40%; otherwise the policy targets `balanced`.
  - `lenuwu-power-policy` shell script starts once at boot, reacts to
    `power_supply` events, and watches `/run/tlp/last_pwr` for profile changes.
    It sets brightness only on boot, AC changes, battery-level changes, or a
    switch to `power-saver`; manual brightness changes are not periodically
    overwritten. AC events set 100%, battery >40% sets 80%, battery <=40% or
    battery-side `power-saver` sets 40%. TLP holds block automatic profile
    switching but not brightness changes.
  - logind: lid/dock/idle (30 min) → hibernate. systemd-initrd hibernation
    via EFI `HibernateLocation`; 36 GiB swap file at
    `/var/lib/hibernate-swapfile`. ZRAM 25% zstd. Weekly fstrim.
    `boot.loader.systemd-boot.configurationLimit = 10`.

### `hp-nix` — HP Envy x360 Convertible 13-bd0xxx (Intel 11th-gen Tiger Lake / Iris Xe)

- `enableGaming = false` (toggleable in `flake.nix`).
- `boot.kernelPackages = pkgs.linuxPackages_latest`;
  `boot.initrd.kernelModules = [ "i915" ]` for early KMS.
- Intel iGPU with `intel-media-driver` (VAAPI) + `vpl-gpu-rt` (Quick Sync).
- Touchpad via libinput; Bluetooth on; blueman with applet.
- libvirtd + virt-manager + spiceUSBRedirection (Windows VM for HP BIOS USB tooling). `krieger ∈ libvirtd`.
- System packages: `brightnessctl`, `vintagestory`.
- Power management (`power.nix`): power-profiles-daemon + thermald, no TLP.

## System-level config (`modules/common.nix`)

- Kernel packages are selected per host in `hosts/*/default.nix`; both hosts
  currently use the official Nixpkgs latest kernel track, `pkgs.linuxPackages_latest`.
- Hostname injected from the flake via `specialArgs.hostname`.
- systemd-boot, EFI vars writable.
- NetworkManager (+ networkmanager-openvpn).
- fwupd enabled (LVFS BIOS updates).
- greetd starts `niri-session` directly as `krieger` via `initial_session`;
  `default_session` is `agreety --cmd niri-session` for fallback login on tty1.
- Niri enabled (`programs.niri.enable`); the niri-flake polkit user service is disabled because Noctalia provides a polkit agent (multiple agents conflict).
- xdg.portal: GTK + GNOME extra portals. Niri-specific portal ordering forces GTK for FileChooser, GNOME for ScreenCast/Screenshot/RemoteDesktop, gnome-keyring for Secret.
- Flatpak enabled. Discord is installed from Flathub by an idempotent activation
  script that warns and skips when Flathub/DNS is unavailable.
- power-profiles-daemon defaulted on (laptop hosts override with `lib.mkForce`).
- gnome-keyring + greetd/Noctalia PAM integration (`noctalia-lock`) best-effort;
  gvfs is enabled so Nautilus can mount network shares (sftp/smb/ftp/mtp under
  "Other Locations") and back the trash bin (`trash:///`).
- Logitech MX Master 4 for Business (USB receiver `046d:c548`) is owned by `modules/logiops.nix`: a locally patched `pkgs.logiops` daemon (`logid.service`) reads a hand-written, heavily-commented `/etc/logid.cfg` rendered from a Nix heredoc; `hardware.logitech.wireless.{enable,enableGraphical}` pulls in Solaar + `logitech-udev-rules`. Starter mapping: DPI 1000, smart-shift on, haptics on at strength 60 with battery saving; Haptic Sense Panel/thumbrest tap → `Super+X` (Niri overview), thumbrest drags → Niri focus column/window, smaller gesture button → `Super+D` (Noctalia launcher), wheel-mode button → `Super+F` (Niri maximize column), thumb wheel → `KEY_VOLUMEUP/DOWN` (forwarded to Noctalia by Niri's media-key bindings); thumb buttons (Back/Forward) and the vertical scroll wheel are intentionally undiverted so the kernel `hid-logitech-hidpp` driver handles them natively. Linux has Solaar/logiops access to HAPTIC and force-sensing settings, but Logitech Options+ Actions Ring overlays and per-app haptic plugins are not available natively on this Niri setup. The old `services.keyd` block on the receiver was removed.
- CUPS printing on. PipeWire (alsa + 32-bit + pulse). pulseaudio off, rtkit on.
- User `krieger` (normal, wheel/networkmanager/video/audio/input/kvm/libvirtd).
- Firefox enabled. Unfree allowed.
- `permittedInsecurePackages = [ "qtwebengine-5.15.19" ]` — original justification was teamspeak3, but the package list now uses `teamspeak6-client`; possibly stale.
- Flakes enabled. `nix.nixPath = [ "nixpkgs=/etc/channels/nixpkgs" ]`. Weekly GC, 30-day retention. `auto-optimise-store`.
- OpenSSH on (overridden off on the laptop). PasswordAuthentication still true.
- Auto-upgrade: weekly, no reboot, points at `/home/krieger/CirnOS#$hostname` (laptop overrides this off).

## System packages (`modules/programs.nix`)

Fonts: nerd-fonts (jetbrains-mono, fira-code), noto-fonts + emoji, corefonts (Steam/Proton).

`programs.chromium.enable = true`. Keychron WebHID udev rule for vendor `3434`.

Notable wrappers:
- `footage-x11` — `wrapProgram footage --set GDK_BACKEND x11` (Wayland + NVIDIA Vulkan crash workaround).

Apps installed system-wide: git, wget, curl, python3, chromium, qbittorrent, popsicle, kicad, dconf-editor, spotify, vscode, fastfetch, tree, ripgrep, fd, jq, yt-dlp, libreoffice-fresh, claude-code, ffmpeg, the GNOME file-manager stack (`nautilus`, `file-roller`; trash + remote shares come from `gvfs` enabled in `common.nix`), the Noctalia color-template prerequisites (`adw-gtk3`, `qt6Packages.qt6ct`, `libsForQt5.qt5ct`), the icon-theme stack (`papirus-icon-theme` as the active GTK icon theme, with `adwaita-icon-theme` and `hicolor-icon-theme` as siblings/fallback), unzip/zip/p7zip, ffmpegthumbnailer, gthumb, inkscape, networkmanagerapplet, pavucontrol, wdisplays, wl-clipboard, teamspeak6-client, obsidian, gparted-full, nodejs_24, signal-desktop, whatsapp-electron, full GStreamer plugin set, the footage X11 wrapper, evtest (used by the Noctalia Slow Bongo plugin), wev (used to verify logiops keypresses).

## Firewall (`modules/firewall.nix`)

- Always-open: TCP/UDP `22000` (Syncthing sync), UDP `21027` (Syncthing discovery).
- Open everywhere except the laptop: TCP `22` (SSH), TCP `3000` (Next.js dev).
- Ping allowed; reverse-path/refused-conn logging off.
- The laptop is detected by `hostname == "lenuwu-nix"`.

## Home Manager (`home/`)

- `home/default.nix` imports unconditionally: `shellAliases`, `default-apps`, `themes`, `ghostty`, `syncthing`, `niri`, `noctalia/noctalia.nix`. Conditionally imports `gaming.nix` if `enableGaming` and `workspaces-hp.nix` if hostname is `hp-nix` or `lenuwu-nix`.
- Programs enabled at HM level: home-manager itself, git (with openpgp signing), direnv (silent), btop, bat, eza (icons + git), fzf (bash integration), mpv, bash.
- `dconf` forces `prefer-dark` color scheme, `adw-gtk3-dark` GTK theme (so it matches `home/themes.nix` and Noctalia's GTK template overlay), and the catppuccin-mocha-blue cursor (size 24); hot corners disabled.

### Aliases (`home/shellAliases.nix`)

- `rebuild` → `sudo nixos-rebuild switch --flake path:~/CirnOS#$(hostname)`
- `update` → `cd ~/CirnOS && sudo nix flake update && sudo nixos-rebuild switch --flake path:.#$(hostname)`
- `cleanup` → `sudo nix-collect-garbage -d`
- `gaaCirnOS / gcCirnOS / gpCirnOS / gsCirnOS` — repo-local git shortcuts.
- `gs/ga/gc/gp/gl/gd` — generic git shortcuts.
- `pp / pp-list / pp-perf / pp-bal / pp-save` — TLP profile control via `tlpctl`.
- `steam-perf` / `game-perf` — `tlpctl launch --profile performance --reason Gaming ...`.
- `sysinfo = fastfetch`, `ls = eza`, `cat = bat`.

### Niri (`home/niri.nix`)

- Wayland env vars set globally; NVIDIA-specific vars (`LIBVA_DRIVER_NAME=nvidia`, `GBM_BACKEND=nvidia-drm`, `__GLX_VENDOR_LIBRARY_NAME=nvidia`, `WLR_NO_HARDWARE_CURSORS=1`) are added when `hostname != "lenuwu-nix"` — note this currently applies on the *Intel* `hp-nix` too (see `possible improvements.txt`).
- Spawn at startup: `noctalia`, `xwayland-satellite`, `ghostty` daemon window.
- swayidle: lock at 5 min (`noctalia msg session lock`), power off monitors at 10 min, on lenuwu also hibernate at 30 min, lock on `before-sleep`.
- Outputs:
  - lenuwu → laptop `eDP-1` 1920×1200@60.
  - everywhere else → dock layout: `DP-5` (rotated 90° / vertical), `DP-4` (center, focus-at-startup), `DP-6` (right). All 2560×1440 with VRR.
- Input: keyboard layout `de` on lenuwu else `ch`; flat mouse accel; touchpad tap + natural scroll; focus-follows-mouse off; hot-corners off.
- Layout: gaps 3, preset column widths 1/3, 1/2, 2/3 (default 1/2). Focus ring enabled (3 px), borders off.
- Cursor: `catppuccin-mocha-blue-cursors` size 24.
- `prefer-no-csd = true`. Screenshots → `~/Pictures/Screenshots/%Y-%m-%d_%H-%M-%S.png`.
- Window rules: PiP floats; xdg-desktop-portal-gtk dialogs float.
- Keybinds (Super = Mod):
  - `Q` close, `F` maximize column, `T` toggle floating
  - `Up/Down` focus window-or-workspace; `Shift+Left/Right` move column; `Shift+Up/Down` move window between workspaces
  - `X` toggle overview
  - `Left/Right` focus column; `[`/`]` consume/expel into column
  - `R` cycle preset width; `-`/`=` shrink/grow column 10%
  - `1..9` focus workspace; `Shift+1..9` move column to workspace
  - `Ctrl+Left/Right` focus monitor; `Shift+Ctrl+Left/Right` move column to monitor
  - `Home/End` first/last column; `C` center column
  - `Return` ghostty; `D` Noctalia launcher; `B` controlCenter; `N` notifications; `V` clipboard
  - `Shift+S` region screenshot to clipboard; `Ctrl+S` region into swappy; `Print` full screen; `Super+Print` window
  - `Esc` lock; `Shift+E` quit niri; `Shift+R` reload-config
  - Media keys + brightness keys → Noctalia IPC.

### Noctalia (`home/noctalia/`)

- Noctalia v5 is imported from the `noctalia` flake input via `inputs.noctalia.homeModules.default`.
- `programs.noctalia` writes `~/.config/noctalia/config.toml` from the Nix attrset in `home/noctalia/noctalia.nix`.
- Runtime UI overrides are owned by Noctalia under `~/.local/state/noctalia/`; they are not symlinked back into the repo.
- `home/niri.nix` starts `noctalia` directly so the existing greetd/Niri lock-on-startup flow remains in one place.
- Core v5 settings kept declarative: telemetry/setup wizard off, Noctalia polkit agent on, dark Catppuccin builtin palette, GTK/Qt/Ghostty/Btop templates, wallpaper directory, and dock pins.
- v5 IPC examples used by Niri: `noctalia msg session lock`, `noctalia msg panel-toggle launcher`, `noctalia msg panel-toggle control-center`, `noctalia msg panel-toggle clipboard`, `noctalia msg volume-up`, `noctalia msg media toggle`, `noctalia msg brightness-up`.

### Default applications (`home/default-apps.nix`)

- Text/code/JSON/XML/YAML → `code.desktop`.
- HTTP/HTTPS/about/unknown → `firefox.desktop`.
- Images (jpeg/png/gif/bmp/webp/svg) → `org.gnome.gThumb.desktop`.
- Video (mp4/mkv/webm/mpeg/avi/quicktime/flv) and audio (mpeg/mp4/wav/flac/ogg) → `mpv.desktop`.
- Archives (zip/tar/7z/rar/gz/bz2/xz) → `org.gnome.FileRoller.desktop` (GNOME File Roller).
- Directories → `org.gnome.Nautilus.desktop` (GNOME Nautilus).

### Themes (`home/themes.nix`)

- GTK: `adw-gtk3-dark` (`pkgs.adw-gtk3`) for both gtk3 and gtk4. The `adw-gtk3` base is mandatory — Noctalia's GTK color template (Settings → Color Scheme → Templates → System → GTK) writes `~/.config/gtk-{3,4}.0/noctalia.css` and appends `@import url("noctalia.css");` to gtk.css; the import only layers correctly on top of `adw-gtk3`/`adw-gtk3-dark`.
- Qt: `qt.platformTheme.name = "qtct"` so `QT_QPA_PLATFORMTHEME=qt6ct` and Qt apps consult `~/.config/qt6ct/colors/noctalia.conf` written by Noctalia's Qt template. After enabling the template, run `qt6ct` once and pick `noctalia` from the Color Scheme dropdown.
- Icons: `Papirus-Dark` (`pkgs.papirus-icon-theme`) is the active GTK icon theme (mirrored in dconf `org.gnome.desktop.interface icon-theme`). It pulls in `breeze-icons` and `hicolor` via `Inherits=breeze-dark,hicolor`, giving Noctalia's dock/launcher coverage of ~5000 third-party app icons (Discord, Spotify, org.gnome.Nautilus, ...) without per-app symlink hacks. `adwaita-icon-theme` and `hicolor-icon-theme` are kept installed as fallbacks for apps that hardcode Adwaita symbolic names or ship icons only under `hicolor/`.
- KColorScheme template is intentionally not enabled in `home/noctalia/noctalia.nix` because the desktop has no KDE / Qt6 apps that consume `~/.local/share/color-schemes/noctalia.colors`. Re-enable it only if you bring back KDE apps like Dolphin/Ark/Konsole.
- Cursor: `catppuccin-mocha-blue-cursors` size 24, with all Catppuccin Mocha cursor variants still installed for easy manual switching.
- gtk3/gtk4 `extraConfig`: `gtk-application-prefer-dark-theme = true`.
- gtk-4.0 gotcha: `xdg.configFile."gtk-4.0/gtk.css".force = true;` is set in `home/themes.nix`. Noctalia's GTK template's `gtk-refresh.py` post-hook appends `@import url("noctalia.css");` to `gtk.css` after activation, turning HM's symlink into a regular file. Without `force = true` HM tries to back the file up to `gtk.css.backup` on the next rebuild, fails the second time around because `.backup` already exists, and breaks `home-manager-krieger.service`. Noctalia re-appends its import on every theme refresh so HM-generated content has no value to preserve.

### Ghostty (`home/ghostty.nix`)

`background-opacity = 0.8`, `background-blur = true`, `theme = "noctalia"` (Noctalia generates the matching theme file).

### Syncthing (`home/syncthing.nix`)

User service. `overrideDevices` and `overrideFolders` left false so devices/folders added via the web UI persist. Telemetry prompt declined (`urAccepted = -1`).

### Gaming (`home/gaming.nix`, only when `enableGaming`)

User packages: protontricks, protonup-qt, mangohud, vulkan-tools, winetricks, heroic, vintagestory. (Steam, gamescope, gamemode, gpu-screen-recorder are enabled at the system level on the gaming host.)

### Workspaces (`home/workspaces-hp.nix`)

Imported on `hp-nix` and `lenuwu-nix`. Defines named workspaces `A`, `B`, `C` with no startup windows.

### `home/defaultwindows.nix` (NOT currently imported)

Multi-monitor desktop startup choreography for a 3-monitor dock (DP-5 / DP-4 / DP-6) — declares named workspaces `A1..C3` (one per monitor lane), spawns Discord on A2, Firefox on A3 maximized, two `nautilus` file-manager windows on A1 stacked + maximized, plus `at-startup` window-rules to pin them. Add it to `home/default.nix`'s imports if you re-enable the desktop layout.

## Conventions and gotchas

- **Niri config is Home Manager-managed.** The old runtime focus-ring mutation service was removed during the Noctalia v5 migration.
- **Noctalia is not the display manager.** greetd auto-logs `krieger` into
  `niri-session`; `home/niri.nix` starts Noctalia and immediately asks it to
  lock via `noctalia msg session lock`. If that IPC never becomes
  available, the startup guard exits Niri so greetd can fall back to `agreety`.
  This is an in-session lockscreen, not a pre-session login greeter.
- **Noctalia runtime settings are not tracked automatically.** Promote stable UI changes from Noctalia's state files into `home/noctalia/noctalia.nix` manually.
- **Don't add a second polkit agent.** The niri-flake polkit user service is explicitly disabled in `common.nix`. Noctalia v5 owns this via `shell.polkit_agent = true`.
- **Battery thresholds are unmanaged.** The Noctalia battery-threshold plugin and local sysfs write permissions were removed; stock charging behavior is expected.
- **File manager is Nautilus.** `pkgs.nautilus` and `pkgs.file-roller` are installed in `modules/programs.nix`. Trash (`trash:///`, "Empty Trash", "Restore") and remote protocols (sftp/smb/ftp/mtp under "Other Locations") are provided by `gvfs` (enabled at the system level in `modules/common.nix`). Modern Nautilus has built-in archive extraction (`gnome-autoar`) for the right-click "Extract Here" action; `file-roller` registers `org.gnome.FileRoller.desktop` for opening archives, which is what `home/default-apps.nix` routes the archive MIME types to. The Noctalia dock pins reference `org.gnome.Nautilus` in `home/noctalia/noctalia.nix`.
- **Noctalia color templates need NixOS prep.** The v5 declarative config enables GTK, Qt, Ghostty, and Btop templates. GTK base theme must be `adw-gtk3-dark` (`pkgs.adw-gtk3` installed, `gtk.theme.name = "adw-gtk3-dark"` in `home/themes.nix`, dconf `gtk-theme = "adw-gtk3-dark"`). Qt platform theme must be `qtct` (`pkgs.qt6ct` + `pkgs.libsForQt5.qt5ct` installed, `qt.platformTheme.name = "qtct"`). Don't revert those theme choices without also changing Noctalia's template list.
- **`footage` is wrapped** to force GDK_BACKEND=x11 (Wayland + NVIDIA Vulkan crash). Wrapper lives inline in `programs.nix`.
- **MX Master 4 for Business = patched logiops + Solaar.** `modules/logiops.nix` owns the receiver `046d:c548` end-to-end (Haptic Sense Panel, gesture button, thumb wheel, smart-shift, DPI, haptic level, per-button). The old `services.keyd` Logitech-mouse block is gone — don't reintroduce it; logiops "diverts" the relevant buttons before evdev, so keyd would never see them anyway. Edit `/etc/logid.cfg` by editing the Nix heredoc in `modules/logiops.nix`, then `rebuild` and `sudo systemctl restart logid`. Discover CIDs with `sudo systemctl stop logid && sudo logid -v`.
- **Gaming on `lenuwu-nix`**: Steam etc. are configured at the system level here, not in `home/gaming.nix`. `enableGaming` only toggles the user-level extras.
- **Roaming-laptop firewall**: `lenuwu-nix` does NOT expose SSH or port 3000.
- **Auto-upgrade**: from a user-writable repo path (`~/krieger/CirnOS`). The laptop's auto-upgrade is force-disabled (`possible improvements.txt` flags this as a hardening target).
- **`PasswordAuthentication = true`** for SSHd is currently set in `common.nix`; flagged in `possible improvements.txt` for hardening once SSH keys are in place.
- **Insecure package allow-list**: `qtwebengine-5.15.19` is permitted with a comment about teamspeak3, but only `teamspeak6-client` is installed. May be removable.
- **NVIDIA env vars** in `home/niri.nix` are applied to every host except `lenuwu-nix`. `hp-nix` is Intel — these are harmless there but are stale (the guard predates `hp-nix`).
- **Always edit `hardware-configuration.nix` only via `nixos-generate-config`.** See `docs/lenuwu-nix-migration.md` for the full disk-transplant procedure on the ThinkPad.
- **Stock kernel track.** Both hosts use `pkgs.linuxPackages_latest`. Rollback
  ThinkPad Wi-Fi or other kernel regressions by setting the affected host to
  `pkgs.linuxPackages`, then rebuild and reboot. Boot failure: pick the previous
  systemd-boot generation (`configurationLimit = 10` on lenuwu).

## Common workflows

- Edit, then `rebuild` (alias) — runs `nixos-rebuild switch --flake path:~/CirnOS#$(hostname)`.
- Update inputs with `update` (alias).
- Garbage-collect with `cleanup` (alias); the system also auto-GCs weekly with 30-day retention and runs `auto-optimise-store`.
- Power profile from CLI: `pp` (get), `pp-perf` / `pp-bal` / `pp-save`. Game with `steam-perf` or `game-perf <cmd>`.
- After Noctalia UI tweaks: just `git add home/noctalia/*.json` and commit.
- After changing kernel tracks: `rebuild` + `reboot`; on lenuwu verify Wi-Fi after
  ~10 s and confirm `uname -r` does not contain `cachyos` or `lto`.
