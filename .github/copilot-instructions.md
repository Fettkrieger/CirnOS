# CirnOS - Copilot Instructions

## Project Overview

Multi-host NixOS flake configuration with Home Manager integration and Catppuccin theming. Manages two hosts: `nzxt-nix` (gaming desktop with NVIDIA) and `hp-laptop`.

## Architecture

```
flake.nix              # Entry point: mkHost() creates host configs
├── modules/           # System-level NixOS modules (shared)
│   ├── common.nix     # Base config: GNOME, PipeWire, SSH, locale
│   ├── firewall.nix   # Network rules
│   └── programs.nix   # System packages
├── hosts/<hostname>/  # Per-machine hardware & overrides
│   ├── default.nix    # Host entry (imports hardware + gpu)
│   └── gpu.nix        # Graphics drivers (NVIDIA on nzxt-nix)
└── home/              # Home Manager user config (user: krieger)
    ├── default.nix    # Main: packages, dconf, catppuccin
    ├── gaming.nix     # Conditionally imported via enableGaming
    └── themes.nix     # GTK/Qt/Kvantum theming
```

## Key Patterns

### Conditional Module Imports
Gaming modules load based on `enableGaming` flag from flake:
```nix
# home/default.nix
imports = [...] ++ (if enableGaming then [ ./gaming.nix ] else []);
```

### Host Configuration via mkHost
All hosts use the `mkHost` function in [flake.nix](flake.nix) with `hostname`, `hostConfig`, and `enableGaming` parameters. Special args flow through to Home Manager.

### Catppuccin Theming
Theme settings are consolidated in [home/default.nix](home/default.nix#L104-L119) and [home/themes.nix](home/themes.nix). Use `flavor` (mocha/macchiato/frappe/latte) and `accent` (red, blue, etc.) options.

### Shell Aliases with Dynamic Hostname
Aliases in [home/shellAliases.nix](home/shellAliases.nix) use `$(hostname)` for automatic host detection:
```nix
rebuild = "sudo nixos-rebuild switch --flake .../CirnOS#$(hostname)";
```

## Common Tasks

| Task | Command |
|------|---------|
| Rebuild current host | `rebuild` (alias) |
| Update flake + rebuild | `update` (alias) |
| Test without switching | `sudo nixos-rebuild test --flake .#<host>` |
| Debug build errors | `sudo nixos-rebuild switch --flake .#<host> --show-trace` |
| Check flake validity | `nix flake check` |

## When Editing

- **Adding system packages**: Edit [modules/programs.nix](modules/programs.nix)
- **Adding user packages**: Edit `home.packages` in [home/default.nix](home/default.nix#L20-L44)
- **Adding gaming packages**: Edit [home/gaming.nix](home/gaming.nix) (desktop only)
- **Adding a new host**: Create `hosts/<name>/default.nix` + `hardware-configuration.nix`, add `mkHost` entry in flake.nix
-im usung niri windowmanager
- **Keybindings**: Edit [home/keybindings.nix](home/keybindings.nix)

## Nix Conventions

- Use `pkgs.linuxPackages_latest` for kernel on desktop (hardware support)
- NVIDIA: Use `nvidiaPackages.beta` for newest GPU support (RTX 5070 Ti)
- Steam is system-level (`programs.steam`) for better integration; gaming tools are user-level
- Home Manager uses `useGlobalPkgs = true` - no separate nixpkgs instance

always rebuild and debug when you do something never say i should do something myself