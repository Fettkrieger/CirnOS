{ config, pkgs, ... }:

{
  # Gaming packages for Home Manager
  home.packages = with pkgs; [
    # Steam and related
    steam
    protontricks      # Tool to manage Proton prefixes
    
    # Performance and monitoring
    gamemode          # Performance management for games
    mangohud          # Performance overlay
    
    # Vulkan and graphics
    vulkan-tools
    vulkan-loader
    libvulkan
    
    # Additional gaming libraries
    winetricks        # Wine configuration tool
    
    # Performance tools
    gpu-screen-recorder # Screen recording for gaming
  ];

  # Wine configuration (optional, mainly for compatibility)
  home.file.".config/wine/user.reg" = {
    text = ''
      [Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\MenuOrder\\Start Menu]
    '';
  };
}
