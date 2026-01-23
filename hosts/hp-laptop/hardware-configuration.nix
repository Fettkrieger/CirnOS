# HP Laptop Hardware Configuration
# PLACEHOLDER: Replace this file with the output of `nixos-generate-config --show-hardware-config`
# Run this command on the HP laptop after booting from NixOS installer
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # TODO: These will be auto-generated when you run nixos-generate-config on the laptop
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];  # or "kvm-amd"
  boot.extraModulePackages = [ ];

  # Filesystem mounts - REPLACE with your actual partitions after running nixos-generate-config
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/PLACEHOLDER-REPLACE-ME";
    fsType = "ext4";  # or "btrfs"
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/PLACEHOLDER-REPLACE-ME-BOOT";
    fsType = "vfat";
  };
  swapDevices = [ ];

  # Platform
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
