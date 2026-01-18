{ pkgs, ... }:

# This file contains ALL packages for both system and user
# It's imported by both configuration.nix and home.nix
{
  # Define package lists
  systemPackages = with pkgs; [
    # Essential system tools
    vim # Text editor
    wget # Download utility
    curl # Transfer data utility
    git # Version control
    htop # Process viewer
    
    # GNOME utilities
    gnome-tweaks # Additional GNOME settings
    dconf-editor # Low-level GNOME settings editor
    
    # NVIDIA tools
    nvtopPackages.full # GPU monitoring tool (like htop for GPU)
    
    # Add more system-wide packages here
  ];

  userPackages = with pkgs; [
    # Development tools
    vscode
    
    # Utilities
    neofetch
    tree
    unzip
    zip
    p7zip
    
    # System monitoring
    btop
    
    # Media
    vlc
    mpv
    
    # Communication
    discord
    
    # Terminal tools
    ripgrep # Fast search tool (rg command)
    fd # Fast find alternative
    eza # Modern ls replacement
    bat # Cat with syntax highlighting
    
    # File management
    ranger # Terminal file manager
    
    # Add more user packages below as you need them
    # Example categories:
    
    # Gaming
    # steam
    # lutris
    
    # Graphics
    # gimp
    # inkscape
    # blender
    
    # Office
    # libreoffice
    # obsidian
    
    # Browsers
    # chromium
    # brave
    
    # Network tools
    # nmap
    # wireshark
  ];
}
