# Gaming configuration for Home Manager
# Only imported when enableGaming = true in flake.nix
{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Note: Steam is installed system-wide in hosts/*/default.nix
    protontricks
    protonup-qt     # Install/manage Proton-GE versions
    steam-run       # Run games with Steam runtime libraries
    gamemode
    mangohud
    vulkan-tools
    winetricks
    gpu-screen-recorder
    lutris
    heroic  # Epic Games / GOG launcher
    vintagestory
  ];
}
