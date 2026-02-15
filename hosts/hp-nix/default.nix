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
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # Some HP firmware sessions leave Bluetooth soft-blocked at boot.
  # Force-unblock and power on the adapter after rfkill state restore.
  systemd.services.bluetooth-unblock = {
    description = "Unblock and power on Bluetooth adapter";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-rfkill.service" "bluetooth.service" ];
    wants = [ "bluetooth.service" ];
    serviceConfig = {
      Type = "oneshot";
    };
    script = ''
      ${pkgs.util-linux}/bin/rfkill unblock bluetooth || true
      ${pkgs.bluez}/bin/bluetoothctl --timeout 5 power on || true
    '';
  };
}
