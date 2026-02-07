# NZXT Desktop Configuration (NVIDIA RTX 5070 Ti + AMD Ryzen 7800X3D)
{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./gpu.nix
  ];

  # Use latest kernel for best hardware support
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # MediaTek MT7921 Bluetooth support (NZXT N7 motherboard WiFi/BT combo chip)
  boot.kernelModules = [ "btusb" "btmtk" ];
  boot.extraModprobeConfig = ''
    # MT7921 Bluetooth can fail USB enumeration on some boards when autosuspend is on.
    options btusb enable_autosuspend=n
  '';
  hardware.enableAllFirmware = true;

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # Prefer RØDE NT-USB Mini as the default microphone source
  services.pipewire.wireplumber.extraConfig = {
    "10-default-audio-input" = {
      "monitor.alsa.rules" = [
        {
          # Match the mic source even if ALSA USB serial/id changes.
          matches = [{ "node.name" = "~alsa_input\\.usb-R__DE_Microphones_R__DE_NT-USB_Mini_.*\\.mono-fallback"; }];
          actions = {
            update-props = {
              "priority.session" = 20000;
              "priority.driver" = 20000;
            };
          };
        }
        {
          # Prevent output monitor sources from becoming the default microphone.
          matches = [
            {
              "media.class" = "Audio/Source";
              "node.name" = "~alsa_output\\..*\\.monitor";
            }
          ];
          actions = {
            update-props = {
              "priority.session" = 1;
              "priority.driver" = 1;
            };
          };
        }
      ];
    };
  };

  # Enable Steam (system-wide for better integration)
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    gamescopeSession.enable = true;
  };
}
