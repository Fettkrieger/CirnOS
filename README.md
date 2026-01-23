# CirnOS 🧊

A multi-host NixOS configuration with Home Manager, featuring Catppuccin theming and gaming support.

## 🖥️ Supported Hosts

| Host | Description | Hardware | Gaming |
|------|-------------|----------|--------|
| `nzxt-nix` | Desktop PC | AMD Ryzen 7800X3D, NVIDIA RTX 5070 Ti | ✅ |
| `hp-laptop` | HP Convertible Laptop | TBD | ❌ |

## 📁 Directory Structure

```
CirnOS/
├── flake.nix              # Multi-host flake configuration
├── README.md              # This file
├── hosts/                 # Host-specific configurations
│   ├── nzxt-nix/         # Desktop configuration
│   │   ├── default.nix
│   │   ├── hardware-configuration.nix
│   │   └── gpu.nix       # NVIDIA config
│   └── hp-laptop/        # Laptop configuration
│       ├── default.nix
│       └── hardware-configuration.nix
├── modules/              # Shared NixOS modules
│   ├── common.nix        # Base system config
│   ├── firewall.nix      # Network firewall
│   └── programs.nix      # System packages
└── home/                 # Home Manager configuration
    ├── default.nix       # Main home config
    ├── keybindings.nix   # GNOME shortcuts
    ├── shellAliases.nix  # Bash aliases
    ├── default-apps.nix  # XDG MIME defaults
    ├── themes.nix        # GTK/Qt theming
    └── gaming.nix        # Gaming packages
```

## 🚀 Quick Start

### First-time Installation

1. Boot from NixOS installer USB
2. Partition and mount drives
3. Clone this repo:
   ```bash
   git clone https://github.com/YOUR_USERNAME/CirnOS.git /mnt/home/krieger/CirnOS
   ```
4. Generate hardware config:
   ```bash
   nixos-generate-config --root /mnt --show-hardware-config > /mnt/home/krieger/CirnOS/hosts/<hostname>/hardware-configuration.nix
   ```
5. Install:
   ```bash
   nixos-install --flake /mnt/home/krieger/CirnOS#<hostname>
   ```

### Daily Usage

```bash
# Rebuild system (auto-detects hostname)
rebuild

# Update flake inputs and rebuild
update

# Clean old generations
cleanup
```

### Manual Commands

```bash
# Rebuild specific host
sudo nixos-rebuild switch --flake /home/krieger/CirnOS#nzxt-nix

# Test configuration without switching
sudo nixos-rebuild test --flake /home/krieger/CirnOS#nzxt-nix

# Build without switching (for review)
sudo nixos-rebuild build --flake /home/krieger/CirnOS#nzxt-nix

# Update only flake inputs
cd /home/krieger/CirnOS && nix flake update

# List generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Rollback to previous generation
sudo nixos-rebuild switch --rollback
```

## 🆕 Adding a New Host

1. Create host directory:
   ```bash
   mkdir -p hosts/new-hostname
   ```

2. Generate hardware config on the new machine:
   ```bash
   nixos-generate-config --show-hardware-config > hosts/new-hostname/hardware-configuration.nix
   ```

3. Create `hosts/new-hostname/default.nix`:
   ```nix
   { config, pkgs, ... }:
   {
     imports = [ ./hardware-configuration.nix ];
     boot.kernelPackages = pkgs.linuxPackages_latest;
     # Add host-specific config here
   }
   ```

4. Add to `flake.nix`:
   ```nix
   new-hostname = mkHost {
     hostname = "new-hostname";
     hostConfig = ./hosts/new-hostname;
     enableGaming = false;
   };
   ```

5. Build:
   ```bash
   sudo nixos-rebuild switch --flake .#new-hostname
   ```

## 🎨 Theming

This configuration uses **Catppuccin Mocha** with blue accents across:
- GTK3/GTK4 applications
- Qt5/Qt6 applications  
- Cursors
- Terminal (if supported)

To change the theme, edit `home/default.nix`:
```nix
catppuccin = {
  enable = true;
  flavor = "mocha";  # latte, frappe, macchiato, mocha
  accent = "blue";   # rosewater, flamingo, pink, mauve, red, maroon, peach, yellow, green, teal, sky, sapphire, blue, lavender
};
```

## 🎮 Gaming (Desktop Only)

Gaming is enabled on `nzxt-nix` with:
- Steam + Proton
- GameMode
- MangoHUD
- Lutris
- Heroic (Epic/GOG)

## 🔒 Security

- Firewall enabled with minimal open ports
- SSH enabled (disable password auth after setting up keys)
- Automatic weekly updates (no auto-reboot)
- 30-day garbage collection retention

## 📝 Useful Aliases

| Alias | Description |
|-------|-------------|
| `rebuild` | Rebuild NixOS |
| `update` | Update flake + rebuild |
| `cleanup` | Garbage collect old generations |
| `sysinfo` | Show system info (fastfetch) |
| `ls` | eza (modern ls) |
| `cat` | bat (syntax highlighted) |
| `gs` | git status |
| `ga` | git add |
| `gc` | git commit |
| `gp` | git push |

## 🔧 Troubleshooting

### Build fails
```bash
# Check for errors
nix flake check

# Build with verbose output
sudo nixos-rebuild switch --flake .#hostname --show-trace
```

### Rollback
```bash
# Boot into previous generation from GRUB/systemd-boot menu
# Or from running system:
sudo nixos-rebuild switch --rollback
```

### SSH Issues
```bash
# Check SSH status
systemctl status sshd

# Test connection
ssh krieger@<ip-address>
```

## 📄 License

MIT - Feel free to use and modify!
