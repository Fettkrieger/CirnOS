# HP Envy x360 Convertible 13-bd0xxx Configuration
# Intel 11th Gen (Tiger Lake) with Iris Xe Graphics
{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./power.nix
  ];

  # Use latest kernel for laptop hardware support
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Early KMS for Intel graphics (prevents black screen on boot)
  boot.initrd.kernelModules = [ "i915" ];

  # Intel/AMD integrated graphics (adjust based on your laptop)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver  # VAAPI for hardware video acceleration
      vpl-gpu-rt          # QSV for Intel Quick Sync Video
    ];
  };

  # Intel CPU microcode (change to hardware.cpu.amd.updateMicrocode if AMD)
  hardware.cpu.intel.updateMicrocode = lib.mkDefault true;

  # Enable touchpad support
  services.libinput = {
    enable = true;
    touchpad = {
      naturalScrolling = true;
      tapping = true;
      clickMethod = "clickfinger";
    };
  };

  # Backlight control
  programs.light.enable = true;

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = false;
  services.blueman.enable = true;

  # Temporary tooling for a Windows VM (used to build HP BIOS USB media)
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;
  users.users.krieger.extraGroups = [ "libvirtd" ];
  
  environment.systemPackages = with pkgs; [
    vintagestory
  ];
}
