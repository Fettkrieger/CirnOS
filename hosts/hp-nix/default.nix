# HP Envy x360 Convertible 13-bd0xxx Configuration
# Intel 11th Gen (Tiger Lake) with Iris Xe Graphics
{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./power.nix
  ];

  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-lto;

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

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = false;
  services.blueman.enable = true;

  # Temporary tooling for a Windows VM (used to build HP BIOS USB media).
  # libvirtd is enabled in modules/common.nix for GNOME Boxes on all hosts.
  programs.virt-manager.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;

  
  environment.systemPackages = with pkgs; [
    # Noctalia brightness controls use brightnessctl.
    brightnessctl
    vintagestory
  ];
}
