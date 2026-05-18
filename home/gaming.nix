# Gaming configuration for Home Manager
# Only imported when enableGaming = true in flake.nix
{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Steam, GameMode, Steam runtime helpers, and GPU recording are enabled
    # system-wide on gaming hosts.
    protontricks
    protonup-qt     # Install/manage Proton-GE versions
    mangohud
    vulkan-tools
    winetricks
    vintagestory
  ];
}
