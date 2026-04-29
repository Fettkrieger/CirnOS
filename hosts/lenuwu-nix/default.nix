# Lenovo ThinkPad E16 Gen 2 AMD configuration
{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Keep the laptop on a recent kernel for current AMD platform support.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  hardware.enableAllFirmware = true;

  # Integrated Radeon graphics.
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.cpu.amd.updateMicrocode = lib.mkDefault true;

  # Laptop input defaults.
  services.libinput = {
    enable = true;
    touchpad = {
      naturalScrolling = true;
      tapping = true;
      clickMethod = "clickfinger";
    };
  };

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = false;
  services.blueman.enable = true;

  services.upower.enable = true;

  environment.systemPackages = with pkgs; [
    brightnessctl
  ];
}
