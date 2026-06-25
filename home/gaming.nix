# Gaming configuration for Home Manager
# Only imported when enableGaming = true in flake.nix
{ config, lib, pkgs, ... }:

let
  localFactorioSpaceAge = import ../pkgs/factorio-space-age-local.nix {
    inherit pkgs;
  };
in
{
  home.packages = (with pkgs; [
    # Steam, GameMode, Steam runtime helpers, and GPU recording are enabled
    # system-wide on gaming hosts.
    protontricks
    protonup-qt     # Install/manage Proton-GE versions
    mangohud
    vulkan-tools
    winetricks
    vintagestory
  ]) ++ lib.optionals localFactorioSpaceAge.enable [
    # To switch versions, place factorio-space-age_linux_VERSION.tar.xz in
    # ~/Sync/Factorio Install, then run:
    #   cd ~/CirnOS && scripts/use-factorio-space-age VERSION && rebuild
    localFactorioSpaceAge.package
  ];
}
