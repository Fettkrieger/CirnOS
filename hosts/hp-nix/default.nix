# HP Envy x360 Convertible 13-bd0xxx Configuration
# Intel 11th Gen (Tiger Lake) with Iris Xe Graphics
{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
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

  # Laptop-specific power management
  services.thermald.enable = true;
  
  # Disable power-profiles-daemon to use TLP instead
  services.power-profiles-daemon.enable = false;
  
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
    };
  };

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
  services.blueman.enable = true;
}
