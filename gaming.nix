{ config, pkgs, ... }:

{
  # Enable Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  # Gaming packages
  home.packages = with pkgs; [
    # Steam and related
    steam
    proton-ge-custom  # Proton GE for wider game compatibility
    protontricks      # Tool to manage Proton prefixes
    
    # Performance and monitoring
    gamemode
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

  # Enable GameMode for better gaming performance
  services.gamemode.enable = true;

  # NVIDIA GPU settings (for RTX 5070 Ti)
  # This should be set in configuration.nix at the system level, but we reference it here
  # Ensure you have: services.xserver.videoDrivers = [ "nvidia" ];
  # And: hardware.nvidia.open = false; (for NVIDIA proprietary drivers)

  # Wine configuration
  home.file.".config/wine/user.reg" = {
    text = ''
      [Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\MenuOrder\\Start Menu]
    '';
  };
}
