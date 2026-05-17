# CirnOS — Agent Reference

Multi-host NixOS flake + Home Manager for user `krieger`. Wayland-only desktop
built on Niri + Noctalia. Two hosts: a Lenovo ThinkPad (`lenuwu-nix`) and an
HP Envy x360 (`hp-nix`). This file is the navigation map for agents working
in the repo.

## Quick facts

- Flake inputs: `nixpkgs` (nixos-unstable), `home-manager`, `niri` (sodiboo/niri-flake),
  `noctalia` (noctalia-dev/noctalia-shell), `nix-cachyos-kernel` (xddxdd/release).
- Kernel (both hosts): `pkgs.cachyosKernels.linuxPackages-cachyos-latest-lto` via
  `modules/cachyos-kernel.nix` (not in official nixpkgs yet).
- `nixosConfigurations`: `lenuwu-nix`, `hp-nix`. Both built via the `mkHost` helper in `flake.nix`.
- Display manager: SDDM (Wayland) with `catppuccin-mocha-blue` theme over a black SVG.
- Compositor: Niri (system module from niri-flake; user config from `home/niri.nix`).
- Shell: Noctalia (bar / notifications / control-center / launcher) — HM module from the noctalia flake.
- Theme: Catppuccin Mocha Blue + Adwaita-dark GTK/Qt; cursor live-synced from Noctalia colors.
- Audio: PipeWire (no PulseAudio); rtkit on. Audio control via Noctalia.
- Network: NetworkManager (+ openvpn plugin) and Tailscale (`useRoutingFeatures = "client"`).
- Locale: `en_US.UTF-8` with `de_CH.UTF-8` formats. TZ Europe/Zurich. Console `sg`, XKB `ch` (overridden to `de` on `lenuwu-nix`).
- `system.stateVersion = "24.11"`, `home.stateVersion = "24.11"`.
- Git identity: Krieger / `leandro.tiziani@protonmail.com`, openpgp signing.
- Auto-upgrade: enabled in `common.nix`, force-disabled on the laptop.

## Repo layout

```
flake.nix                 entry point + mkHost
flake.lock                pinned inputs
modules/
  cachyos-kernel.nix      CachyOS kernel flake overlay + lantian binary cache
  common.nix              shared system config (boot, locale, SDDM, Niri, portals, PipeWire, Tailscale, fwupd, battery_ctl udev, auto-upgrade, ssh, ...)
  programs.nix            system packages + fonts; wraps code-cursor with --password-store=gnome-libsecret; wraps footage with GDK_BACKEND=x11
  firewall.nix            host-aware firewall (laptop = roaming → SSH and dev ports closed)
  logiops.nix             Logitech MX Master 3S: logiops daemon + heavily-commented /etc/logid.cfg + Solaar (via hardware.logitech.wireless)
hosts/
  lenuwu-nix/
    default.nix           ThinkPad E16 Gen 2 AMD specifics
    power.nix             TLP + custom AC-transition policy + hibernate setup
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
    noctalia.nix          imports HM module, sets up settings/plugin symlinks, patches clipboard + battery-threshold plugin
    niri-focus-ring-live.nix    live syncs niri focus-ring colors and cursor variant from Noctalia colors.json
    nix-wallpaper-live.nix      live syncs nix.svg wallpaper colors from Noctalia colors.json and reloads Noctalia wallpaper
    noctalia-settings.json      versioned UI settings (track UI edits in git)
    noctalia-plugins.json       enabled plugins
    tailscale-settings.json     Tailscale plugin settings
    battery-threshold/BatteryThresholdService.qml  local fork that also writes charge_control_start_threshold
docs/lenuwu-nix-migration.md   disk-transplant checklist
possible improvements.txt      2026-02-15 review notes (open items)
```

## Hosts

### `lenuwu-nix` — Lenovo ThinkPad E16 Gen 2 AMD (21M5002DGE)

- AMD CPU + Radeon iGPU. `enableGaming = true`.
- `boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-lto`
  (CachyOS latest, typically 7.x). Stock `linuxPackages` was used previously
  because rtw89/RTL8852CE firmware init failed on Linux 7.0.x — Wi-Fi may still
  break; rollback to `pkgs.linuxPackages` if needed.
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
    owns AC transitions. AC = performance/perf governor; battery = balanced/
    powersave; SAV = low-power.
  - `lenuwu-power-policy` shell script + 30 s timer + udev hook on
    `power_supply` events. It only switches profiles when the AC state
    actually flips (so manual `tlpctl set` sticks), and caps backlight by
    battery %. Respects `tlpctl list-holds`.
  - logind: lid/dock/idle (30 min) → hibernate. systemd-initrd hibernation
    via EFI `HibernateLocation`; 36 GiB swap file at
    `/var/lib/hibernate-swapfile`. ZRAM 25% zstd. Weekly fstrim.
    `boot.loader.systemd-boot.configurationLimit = 10`.

### `hp-nix` — HP Envy x360 Convertible 13-bd0xxx (Intel 11th-gen Tiger Lake / Iris Xe)

- `enableGaming = false` (toggleable in `flake.nix`).
- `boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-lto`;
  `boot.initrd.kernelModules = [ "i915" ]` for early KMS.
- Intel iGPU with `intel-media-driver` (VAAPI) + `vpl-gpu-rt` (Quick Sync).
- Touchpad via libinput; Bluetooth on; blueman with applet.
- libvirtd + virt-manager + spiceUSBRedirection (Windows VM for HP BIOS USB tooling). `krieger ∈ libvirtd`.
- System packages: `brightnessctl`, `vintagestory`.
- Power management (`power.nix`): power-profiles-daemon + thermald, no TLP.

## System-level config (`modules/common.nix`)

- CachyOS kernel: `modules/cachyos-kernel.nix` applies `nix-cachyos-kernel` overlay
  (`overlays.default`) and the lantian Attic substituter. Per-host
  `boot.kernelPackages` is set in `hosts/*/default.nix`.
- Hostname injected from the flake via `specialArgs.hostname`.
- systemd-boot, EFI vars writable.
- NetworkManager (+ networkmanager-openvpn). Tailscale opens its firewall hole automatically.
- fwupd enabled (LVFS BIOS updates).
- SDDM Wayland with `catppuccin-mocha-blue` theme; theme is a custom override (mocha/blue/Noto Sans/black SVG background).
- Niri enabled (`programs.niri.enable`); the niri-flake polkit user service is disabled because Noctalia provides a polkit agent (multiple agents conflict).
- xdg.portal: GTK + GNOME extra portals. Niri-specific portal ordering forces GTK for FileChooser, GNOME for ScreenCast/Screenshot/RemoteDesktop, gnome-keyring for Secret.
- power-profiles-daemon defaulted on (laptop hosts override with `lib.mkForce`).
- gnome-keyring + SDDM PAM integration; gvfs is enabled so Nautilus can mount network shares (sftp/smb/ftp/mtp under "Other Locations") and back the trash bin (`trash:///`).
- Battery threshold: `users.groups.battery_ctl` + udev rules `chgrp battery_ctl` and `chmod g+w` the kernel `charge_control_{start,end}_threshold` files. The Noctalia plugin writes them as `krieger`.
- Logitech MX Master 3S (USB receiver `046d:c548`) is owned by `modules/logiops.nix`: `pkgs.logiops` daemon (`logid.service`) reads a hand-written, heavily-commented `/etc/logid.cfg` rendered from a Nix heredoc; `hardware.logitech.wireless.{enable,enableGraphical}` pulls in Solaar + `logitech-udev-rules`. Starter mapping: DPI 1000, smart-shift on; gesture-button tap → `Super+X` (Niri overview), gesture drags → Niri focus column/window, wheel-mode button → `Super+F` (Niri maximize column), thumb wheel → `KEY_VOLUMEUP/DOWN` (forwarded to Noctalia by Niri's media-key bindings); thumb buttons (Back/Forward) and the vertical scroll wheel are intentionally undiverted so the kernel `hid-logitech-hidpp` driver handles them natively. The old `services.keyd` block on the receiver was removed.
- CUPS printing on. PipeWire (alsa + 32-bit + pulse). pulseaudio off, rtkit on.
- User `krieger` (normal, wheel/networkmanager/video/audio/input/kvm/battery_ctl).
- Firefox enabled. Unfree allowed. Android SDK license auto-accepted.
- `permittedInsecurePackages = [ "qtwebengine-5.15.19" ]` — original justification was teamspeak3, but the package list now uses `teamspeak6-client`; possibly stale.
- Flakes enabled. `nix.nixPath = [ "nixpkgs=/etc/channels/nixpkgs" ]`. Weekly GC, 30-day retention. `auto-optimise-store`.
- OpenSSH on (overridden off on the laptop). PasswordAuthentication still true.
- Auto-upgrade: weekly, no reboot, points at `/home/krieger/CirnOS#$hostname` (laptop overrides this off).

## System packages (`modules/programs.nix`)

Fonts: nerd-fonts (jetbrains-mono, fira-code), noto-fonts + emoji, corefonts (Steam/Proton).

`programs.chromium.enable = true`. Keychron WebHID udev rule for vendor `3434`.

Notable wrappers:
- `cursorWithLibsecret` — wraps `pkgs.code-cursor` with `--password-store=gnome-libsecret`, installed at `lib.hiPrio` so it wins over the un-wrapped binary.
- `footage-x11` — `wrapProgram footage --set GDK_BACKEND x11` (Wayland + NVIDIA Vulkan crash workaround).

Apps installed system-wide: git, wget, curl, jdk17, android-studio-full, android-tools, python3, chromium, qbittorrent, popsicle, kicad, dconf-editor, discord, spotify, vscode, the wrapped cursor, fastfetch, tree, ripgrep, fd, jq, yt-dlp, libreoffice-fresh, claude-code, ffmpeg, the GNOME file-manager stack (`nautilus`, `file-roller`; trash + remote shares come from `gvfs` enabled in `common.nix`), the Noctalia color-template prerequisites (`adw-gtk3`, `qt6Packages.qt6ct`, `libsForQt5.qt5ct`), the icon-theme stack (`papirus-icon-theme` as the active GTK icon theme, with `adwaita-icon-theme` and `hicolor-icon-theme` as siblings/fallback), unzip/zip/p7zip, ffmpegthumbnailer, gthumb, inkscape, networkmanagerapplet, pavucontrol, tailscale, wdisplays, wl-clipboard, teamspeak6-client, obsidian, gparted-full, nodejs_20, signal-desktop, whatsapp-electron, full GStreamer plugin set, the footage X11 wrapper, evtest (used by the Noctalia Slow Bongo plugin), wev (used to verify logiops keypresses).

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
- Spawn at startup: `noctalia-shell`, `xwayland-satellite`, `swayidle`.
- swayidle: lock at 5 min (`noctalia-shell ipc call lockScreen lock`), power off monitors at 10 min, on lenuwu also hibernate at 30 min, lock on `before-sleep`.
- Outputs:
  - lenuwu → laptop `eDP-1` 1920×1200@60.
  - everywhere else → dock layout: `DP-5` (rotated 90° / vertical), `DP-4` (center, focus-at-startup), `DP-6` (right). All 2560×1440 with VRR.
- Input: keyboard layout `de` on lenuwu else `ch`; flat mouse accel; touchpad tap + natural scroll; focus-follows-mouse off; hot-corners off.
- Layout: gaps 3, preset column widths 1/3, 1/2, 2/3 (default 1/2). Focus ring enabled (3 px, runtime-overridden by Noctalia colors), borders off.
- Cursor: `catppuccin-mocha-blue-cursors` size 24 (also runtime-overridden).
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

- HM module is imported from the `noctalia` flake input; the package is overridden via `postPatch` to fix a clipboard auto-paste focus race for image entries (adds a 0.12 s sleep before the paste keys).
- Activation snippets (`noctaliaSettingsBootstrap`, `noctaliaTailscaleSettingsBootstrap`, `noctaliaBatteryThresholdPluginPatch`):
  - Bootstraps `~/.config/noctalia/settings.json`, `~/.config/noctalia/plugins.json`, and `~/.config/noctalia/plugins/tailscale/settings.json` if they don't already exist (preserves any pre-existing legacy file).
  - Then **symlinks** them to the repo-tracked files in `home/noctalia/`. Net effect: edits made via Noctalia's UI land in the git repo and can be committed naturally.
  - On every switch, copies the local fork of `BatteryThresholdService.qml` over the upstream plugin file. The fork additionally writes `charge_control_start_threshold` (max - 5), so ThinkPads don't get stuck in pending-charge.
- `niri-focus-ring-live.nix`:
  - Forces `xdg.configFile."niri-config".enable = lib.mkForce false` so the niri config file is writable at runtime (it's emitted from `programs.niri.finalConfig` once during activation, then mutated by the live sync).
  - On activation, runs `syncFocusRing`: an awk pass that reads `~/.config/noctalia/colors.json` (`mPrimary`/`mSecondary`/`mOutline`) and rewrites `focus-ring.active-color`, `focus-ring.inactive-color`, and `cursor.xcursor-theme` (picks the closest catppuccin-mocha-* variant by RGB squared distance to `mSecondary`).
  - User systemd service `noctalia-niri-focus-ring-live` watches `~/.config/noctalia/colors.json` with `inotifywait`, re-runs `syncFocusRing`, updates `org.gnome.desktop.interface cursor-theme` via gsettings, and asks niri to `load-config-file` on its socket.
- `nix-wallpaper-live.nix`:
  - Watches `~/.config/noctalia/colors.json` with `inotifywait` and rewrites `/home/krieger/Pictures/Wallpapers/nix.svg`.
  - Maps the SVG background rect (`rect3019`) to `mSurface` (the Noctalia bar/panel background), the darker Nix logo paths (`path4260*`) to `mPrimary`, and the lighter logo paths (`path3336*`) to `mSecondary`.
  - The Noctalia package patch adds `noctalia-shell ipc call wallpaper reload [screen|all]`; the watcher calls it after recoloring because Noctalia otherwise ignores same-path wallpaper content changes.
- Enabled Noctalia plugins (`noctalia-plugins.json`): battery-threshold, catwalk, network-manager-vpn, noctalia-calculator, polkit-agent, privacy-indicator, screen-recorder, screen-toolkit, slowbongo, tailscale, usb-drive-manager, weather-indicator. Disabled: notes-scratchpad, pomodoro.
- `noctalia-settings.json` is large (~770 lines) and version-controlled. Top-level sections: appLauncher, audio, bar, brightness, calendar, colorSchemes, controlCenter, desktopWidgets, dock, general, hooks, idle, location, network, nightLight, noctaliaPerformance, notifications, osd, plugins, sessionMenu, systemMonitor, templates, ui, wallpaper. `settingsVersion = 59`.

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
- Icons: `Papirus-Dark` (`pkgs.papirus-icon-theme`) is the active GTK icon theme (mirrored in dconf `org.gnome.desktop.interface icon-theme`). It pulls in `breeze-icons` and `hicolor` via `Inherits=breeze-dark,hicolor`, giving Noctalia's Quickshell-based dock/launcher coverage of ~5000 third-party app icons (Discord, Spotify, org.gnome.Nautilus, ...) without per-app symlink hacks. `adwaita-icon-theme` and `hicolor-icon-theme` are kept installed as fallbacks for apps that hardcode Adwaita symbolic names or ship icons only under `hicolor/`.
- KColorScheme template (Noctalia Settings → Color Scheme → Templates → System → KColorScheme) is **disabled** in `noctalia-settings.json` (`templates.activeTemplates[id="kcolorscheme"].enabled = false`) because the desktop has no KDE / Qt6 apps that consume `~/.local/share/color-schemes/noctalia.colors` — re-enable it (and add the matching reload watcher) only if you reintroduce KDE apps like Dolphin/Ark/Konsole. `~/.config/kdeglobals` and `~/.local/share/color-schemes/noctalia.colors` may exist on disk from when the template was active; they are now inert and safe to delete.
- Cursor: `catppuccin-mocha-blue-cursors` size 24, but the package is a `symlinkJoin` of every catppuccin-mocha cursor variant so the live focus-ring service can switch between them at runtime without rebuilding.
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

- **Niri config is intentionally writable.** `niri-focus-ring-live.nix` sets `xdg.configFile."niri-config".enable = lib.mkForce false;` and bootstraps the file from `programs.niri.finalConfig` on activation. Don't try to "fix" this with `xdg.configFile` — it's load-bearing.
- **Noctalia settings live in git.** Editing the JSON files in `home/noctalia/` is equivalent to editing the live config (and vice versa); commit the JSON to track UI changes.
- **Don't add a second polkit agent.** The niri-flake polkit user service is explicitly disabled in `common.nix`. Noctalia's `polkit-agent` plugin owns this.
- **Battery thresholds** require both `start` and `end` files; the patched QML service (`battery-threshold/BatteryThresholdService.qml`) is force-installed over the upstream plugin on every switch.
- **`code-cursor` is wrapped** with `--password-store=gnome-libsecret` and given `lib.hiPrio` to outrank a vanilla cursor; preserve both when modifying.
- **File manager is Nautilus.** `pkgs.nautilus` and `pkgs.file-roller` are installed in `modules/programs.nix`. Trash (`trash:///`, "Empty Trash", "Restore") and remote protocols (sftp/smb/ftp/mtp under "Other Locations") are provided by `gvfs` (enabled at the system level in `modules/common.nix`). Modern Nautilus has built-in archive extraction (`gnome-autoar`) for the right-click "Extract Here" action; `file-roller` registers `org.gnome.FileRoller.desktop` for opening archives, which is what `home/default-apps.nix` routes the archive MIME types to. The Noctalia app-launcher / dock pinned-apps reference `org.gnome.Nautilus` in `home/noctalia/noctalia-settings.json`.
- **Noctalia color templates need NixOS prep.** Toggling Settings → Color Scheme → Templates → System → {GTK, Qt} only writes color files; for them to take effect: GTK base theme must be `adw-gtk3-dark` (`pkgs.adw-gtk3` installed, `gtk.theme.name = "adw-gtk3-dark"` in `home/themes.nix`, dconf `gtk-theme = "adw-gtk3-dark"`); Qt platform theme must be `qtct` (`pkgs.qt6ct` + `pkgs.libsForQt5.qt5ct` installed, `qt.platformTheme.name = "qtct"`, then `qt6ct` opened once to pick `noctalia` from Color Scheme). Don't revert the GTK/Qt theme choices without disabling the matching templates first or the override will silently no-op. The KColorScheme template is disabled by default — re-enable it only if you bring back KDE / Qt6 apps that read `kdeglobals` / `~/.local/share/color-schemes/noctalia.colors`, and remember to also add a reload mechanism (e.g. broadcasting `org.kde.KGlobalSettings.notifyChange(0,0)` on D-Bus) so already-running KDE apps repaint, which Plasma normally handles but Niri does not.
- **`footage` is wrapped** to force GDK_BACKEND=x11 (Wayland + NVIDIA Vulkan crash). Wrapper lives inline in `programs.nix`.
- **MX Master 3S = logiops + Solaar.** `modules/logiops.nix` owns the receiver `046d:c548` end-to-end (gesture button, thumb wheel, smart-shift, DPI, per-button). The old `services.keyd` Logitech-mouse block is gone — don't reintroduce it; logiops "diverts" the relevant buttons before evdev, so keyd would never see them anyway. Edit `/etc/logid.cfg` by editing the Nix heredoc in `modules/logiops.nix`, then `rebuild` and `sudo systemctl restart logid`. Discover CIDs with `sudo systemctl stop logid && sudo logid -v`.
- **Gaming on `lenuwu-nix`**: Steam etc. are configured at the system level here, not in `home/gaming.nix`. `enableGaming` only toggles the user-level extras.
- **Roaming-laptop firewall**: `lenuwu-nix` does NOT expose SSH or port 3000.
- **Auto-upgrade**: from a user-writable repo path (`~/krieger/CirnOS`). The laptop's auto-upgrade is force-disabled (`possible improvements.txt` flags this as a hardening target).
- **`PasswordAuthentication = true`** for SSHd is currently set in `common.nix`; flagged in `possible improvements.txt` for hardening once SSH keys are in place.
- **Insecure package allow-list**: `qtwebengine-5.15.19` is permitted with a comment about teamspeak3, but only `teamspeak6-client` is installed. May be removable.
- **NVIDIA env vars** in `home/niri.nix` are applied to every host except `lenuwu-nix`. `hp-nix` is Intel — these are harmless there but are stale (the guard predates `hp-nix`).
- **Always edit `hardware-configuration.nix` only via `nixos-generate-config`.** See `docs/lenuwu-nix-migration.md` for the full disk-transplant procedure on the ThinkPad.
- **CachyOS kernel (`nix-cachyos-kernel`).** Do not add `inputs.nixpkgs.follows` on
  the flake input. First deploy after adding the cache: run `rebuild` once (overlay +
  substituter only if you staged that first), then `rebuild` again after
  `boot.kernelPackages` points at `cachyosKernels`, then `reboot`. Expect
  `uname -r` to contain `cachyos` and `lto`. LTO can break future DKMS/OOT modules;
  CirnOS has none today. Rollback ThinkPad Wi-Fi: `boot.kernelPackages = pkgs.linuxPackages`
  in `hosts/lenuwu-nix/default.nix`, rebuild, reboot. Boot failure: pick the previous
  systemd-boot generation (`configurationLimit = 10` on lenuwu). Optional CPU tuning:
  `linuxPackages-cachyos-latest-lto-x86_64-v3` if `/proc/cpuinfo` flags include `lm`
  (Zen + Tiger Lake both qualify).

## Common workflows

- Edit, then `rebuild` (alias) — runs `nixos-rebuild switch --flake path:~/CirnOS#$(hostname)`.
- Update inputs with `update` (alias).
- Garbage-collect with `cleanup` (alias); the system also auto-GCs weekly with 30-day retention and runs `auto-optimise-store`.
- Power profile from CLI: `pp` (get), `pp-perf` / `pp-bal` / `pp-save`. Game with `steam-perf` or `game-perf <cmd>`.
- After Noctalia UI tweaks: just `git add home/noctalia/*.json` and commit.
- After pulling CachyOS kernel changes: `rebuild` (applies cache if new), `rebuild`
  + `reboot` if `boot.kernelPackages` changed; on lenuwu verify Wi-Fi after ~10 s.
