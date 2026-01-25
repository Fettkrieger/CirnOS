# NZXT Desktop Configuration (NVIDIA RTX 5070 Ti + AMD Ryzen 7800X3D)
{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./gpu.nix
  ];

  # Use latest kernel for best hardware support
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # Enable Steam (system-wide for better integration)
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    gamescopeSession.enable = true;
  };
}
