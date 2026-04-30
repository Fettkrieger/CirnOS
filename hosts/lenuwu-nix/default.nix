# Lenovo ThinkPad E16 Gen 2 AMD configuration
{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./power.nix
  ];

  # Use the default kernel instead of latest; rtw89/RTL8852CE currently fails
  # firmware init on Linux 7.0.x, leaving Wi-Fi hardware unavailable.
  boot.kernelPackages = pkgs.linuxPackages;

  hardware.enableAllFirmware = true;

  # Work around an rtw89/RTL8852CE probe race where Wi-Fi and Bluetooth can
  # read efuse concurrently during boot, leaving Wi-Fi hardware unavailable.
  boot.blacklistedKernelModules = [ "rtw89_8852ce" ];
  systemd.services.rtw89-8852ce-delayed = {
    description = "Load RTL8852CE Wi-Fi after Bluetooth";
    wantedBy = [ "multi-user.target" ];
    wants = [ "bluetooth.service" ];
    after = [ "bluetooth.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "load-rtw89-8852ce-delayed" ''
        set -eu
        ${pkgs.kmod}/bin/modprobe btusb || true
        sleep 10
        ${pkgs.kmod}/bin/modprobe rtw89_8852ce
      '';
    };
  };

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

  services.xserver.xkb.layout = lib.mkForce "de";
  console.keyMap = lib.mkForce "de";

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = false;
  services.blueman.enable = true;
  services.blueman.withApplet = false;

  services.upower.enable = true;

  services.openssh.enable = lib.mkForce false;

  programs.steam.enable = true;
  hardware.steam-hardware.enable = true;
  programs.gamemode.enable = true;
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };
  programs.gpu-screen-recorder.enable = true;

  environment.systemPackages = with pkgs; [
    brightnessctl
  ];
}
