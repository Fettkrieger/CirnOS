# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CirnOS is a multi-host NixOS flake configuration managing two machines with Home Manager integration and Catppuccin Mocha theming. Uses Niri (scrolling tiling Wayland compositor) as the window manager.

**Hosts:**
- `nzxt-nix`: Gaming desktop (NVIDIA RTX 5070 Ti, AMD Ryzen 7800X3D, 3x 1440p monitors)
- `hp-nix`: HP laptop (Intel 11th Gen, Iris Xe graphics)

## Commands

```bash
# Rebuild current host (uses hostname detection)
rebuild

# Update flake inputs and rebuild
update

# Test build without switching
sudo nixos-rebuild test --flake .#nzxt-nix

# Debug build errors
sudo nixos-rebuild switch --flake .#nzxt-nix --show-trace

# Check flake validity
nix flake check

# Force ComfyUI dependency reinstall
comfyui-update
```

**Important:** After modifying `.nix` files, new files must be `git add`ed before `nixos-rebuild` will see them (flakes only see tracked files).

## Architecture

```
flake.nix                    # Entry point with mkHost() helper
├── modules/                 # System-level NixOS modules (all hosts)
│   ├── common.nix           # Boot, networking, PipeWire, SSH, GDM, locale
│   ├── programs.nix         # System packages and fonts
│   └── firewall.nix         # UFW-style firewall rules
├── hosts/<hostname>/        # Per-machine configuration
│   ├── default.nix          # Host entry (kernel, hardware, Steam)
│   ├── gpu.nix              # Graphics drivers (NVIDIA on nzxt-nix)
│   └── hardware-configuration.nix
├── home/                    # Home Manager user config (user: krieger)
│   ├── default.nix          # Main HM config, imports, user packages
│   ├── niri.nix             # Compositor config (monitors, keybinds, window rules)
│   ├── niri-wallpaper.nix   # Per-workspace wallpaper daemon
│   ├── waybar-niri.nix      # Status bar (modules, custom scripts, CSS)
│   ├── themes.nix           # GTK/Qt/cursor/icon theming
│   ├── gaming.nix           # Gaming tools (conditional on enableGaming)
│   ├── comfyui.nix          # ComfyUI wrapper script
│   ├── ghostty.nix          # Terminal configuration
│   ├── shellAliases.nix     # Bash aliases
│   └── default-apps.nix     # XDG MIME associations
└── wallpapers/              # Per-workspace wallpapers (1, 2, 3, FALLBACK)
```

## Key Patterns

### mkHost Function
All hosts are created via `mkHost` in flake.nix with `hostname`, `hostConfig`, and `enableGaming` parameters. Special args (`inputs`, `hostname`, `enableGaming`) flow through to all modules including Home Manager.

### Conditional Gaming Imports
```nix
# home/default.nix
imports = [...] ++ (if enableGaming then [ ./gaming.nix ./comfyui.nix ] else []);
```

### Dynamic Hostname in Aliases
```nix
rebuild = "sudo nixos-rebuild switch --flake .../CirnOS#$(hostname)";
```

### Catppuccin Theming
Theme is Catppuccin Mocha with blue accent. Configured via the `catppuccin` flake input and integrated in `home/themes.nix`. Waybar colors are manually defined in CSS to match.

### Custom Waybar Scripts
CPU and GPU monitoring use custom shell scripts defined in `waybar-niri.nix` (cpuScript, gpuScript, networkScript) that read from `/proc/stat`, `/sys/class/hwmon`, and `nvidia-smi`.

## Where to Edit

| Change | File |
|--------|------|
| System packages | `modules/programs.nix` |
| User packages | `home/default.nix` → `home.packages` |
| Gaming packages | `home/gaming.nix` |
| Keybindings | `home/niri.nix` → `binds` section |
| Window rules | `home/niri.nix` → `window-rules` section |
| Waybar modules | `home/waybar-niri.nix` → `modules-right/left/center` |
| Shell aliases | `home/shellAliases.nix` |
| Monitor layout | `home/niri.nix` → `outputs` section |
| Startup apps | `home/niri.nix` → `spawn-at-startup` |
| Workspace wallpapers | `wallpapers/` directory (files named 1, 2, 3, FALLBACK) |

## Nix Conventions

- Uses `nixos-unstable` channel for latest packages
- NVIDIA uses `nvidiaPackages.beta` for RTX 50-series support
- Steam is system-level (`programs.steam`), gaming tools are user-level
- Home Manager uses `useGlobalPkgs = true` (shared nixpkgs instance)
- Waybar runs as systemd user service (`systemd.enable = true`)

## Niri Specifics

- Niri has **per-output workspaces** (each monitor has independent workspace numbering)
- IPC via `niri msg --json <command>` (workspaces, event-stream, action)
- Wallpaper daemon listens to `WorkspaceActivated` events from `event-stream`
- XWayland support via `xwayland-satellite` (starts at compositor launch)
