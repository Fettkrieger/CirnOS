{ pkgs, ... }:

{
  # System-wide packages (available to all users)
  systemPackages = with pkgs; [
    # === Essential Tools ===
    vim             # Text editor
    wget          # Download utility
    curl        # Data transfer tool
    git          # Version control system

    # === System Monitoring ===
    htop
    nvtopPackages.full # GPU monitoring (like htop for NVIDIA)
    
    # === Window Management ===
    wmctrl
    
    # === GNOME Utilities ===
    gnome-tweaks         
    dconf-editor  
    
  ];

  # User packages (krieger user)
  userPackages = with pkgs; [
    # === Development ===
    vscode

    # === Terminal Emulator ===
    ghostty

    # === CLI Tools & Utilities ===
    fastfetch          # System info
    tree               # Directory tree
    ripgrep            # Fast search (rg)
    fd                 # Find alternative
    eza                # Modern ls replacement
    bat                # Syntax highlighted cat
    yt-dlp             # YouTube downloader
    fragments       # Torrent client

    # === File Management ===
    ranger             # Terminal file manager
    nautilus           # GNOME file manager
    unzip                 
    zip                # Archive tools      
    p7zip              # Archive tools    

    # === System Monitoring ===
    btop               # Better process viewer

    # === Media & Graphics ===
    mpv                # Video player
    ffmpegthumbnailer  # Video thumbnails
    gthumb             # Image viewer

    # === Communication ===
    discord
  ];
}