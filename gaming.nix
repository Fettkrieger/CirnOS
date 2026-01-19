{ config, pkgs, ... }:

{
  # Gaming packages for Home Manager
  home.packages = with pkgs; [
    steam
    protontricks
    gamemode
    mangohud
    vulkan-tools
    winetricks
    gpu-screen-recorder
  ];

  # Wine configuration (optional, mainly for compatibility)
  home.file.".config/wine/user.reg" = {
    text = ''
      [Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\MenuOrder\\Start Menu]
    '';
  };
}
