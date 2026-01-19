{ config, pkgs, ... }:

{
  # Gaming packages for Home Manager
  home.packages = with pkgs; [
    # Steam and related
    steam
    proton-ge-custom  # Proton GE for wider game compatibility
    protontricks      # Tool to manage Proton prefixes
    
    # Performance and monitoring
    gamemode          # Performance management for games
    mangohud          # Performance overlay
    goverlay          # GUI for MangoHUD
    
    # Vulkan and graphics
    vulkan-tools
    vulkan-loader
    libvulkan
    
    # Additional gaming libraries
    dxvk              # DirectX to Vulkan translation
    dxvk-compat32     # 32-bit compatibility
    winetricks        # Wine configuration tool
    wine              # For compatibility
    wine32            # 32-bit wine
    
    # Performance tools
    cpupower-gui
    corectrl          # AMD GPU control (useful to have)
    gpu-screen-recorder # Screen recording for gaming
  ];

  # Wine configuration (optional, mainly for compatibility)
  home.file.".config/wine/user.reg" = {
    text = ''
      [Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\MenuOrder\\Start Menu]
    '';
  };
}
