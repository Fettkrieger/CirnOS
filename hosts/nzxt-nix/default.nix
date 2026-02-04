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

  # RØDE NT-USB Mini as default audio device
  services.pipewire.wireplumber.extraConfig = {
    "10-default-audio" = {
      "monitor.alsa.rules" = [
        {
          matches = [{ "node.name" = "alsa_output.usb-R__DE_Microphones_R__DE_NT-USB_Mini_84630635-00.analog-stereo"; }];
          actions = {
            update-props = {
              "priority.session" = 9000;
              "priority.driver" = 9000;
            };
          };
        }
        {
          matches = [{ "node.name" = "alsa_input.usb-R__DE_Microphones_R__DE_NT-USB_Mini_84630635-00.mono-fallback"; }];
          actions = {
            update-props = {
              "priority.session" = 9000;
              "priority.driver" = 9000;
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
