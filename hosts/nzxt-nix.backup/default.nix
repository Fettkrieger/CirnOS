# NZXT Desktop Configuration (NVIDIA RTX 5070 Ti + AMD Ryzen 7800X3D)
{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./gpu.nix
  ];

  # Pin to 6.18: nvidia-open 590.48.01 currently fails to build on 6.19.
  boot.kernelPackages = pkgs.linuxPackages_6_18;

  # MediaTek MT7921 Bluetooth support (NZXT N7 motherboard WiFi/BT combo chip)
  boot.kernelModules = [ "btusb" "btmtk" ];
  boot.extraModprobeConfig = ''
    # MT7921 Bluetooth can fail USB enumeration on some boards when autosuspend is on.
    options btusb enable_autosuspend=n
  '';
  hardware.enableAllFirmware = true;

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = false;
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

  # Work around SDDM Wayland greeter crashes on NVIDIA (Weston assertion crash).
  # Keep SDDM itself on X11; it can still start Wayland sessions like Niri.
  services.displayManager.sddm.wayland.enable = lib.mkForce false;

  # Show SDDM only on the center display.
  # This affects only the login screen X server; Niri still applies its own
  # multi-monitor layout after login.
  services.xserver.displayManager.setupCommands = ''
    XRANDR=${pkgs.xrandr}/bin/xrandr
    XRQ="$($XRANDR --query || true)"
    printf '%s\n' "$XRQ" > /tmp/sddm-xrandr-query.log

    mapfile -t connected < <(printf '%s\n' "$XRQ" | awk '/ connected/{print $1}')
    target=""

    # Center monitor is the only one exposing a 180 Hz mode.
    for output in "''${connected[@]}"; do
      if printf '%s\n' "$XRQ" | awk -v out="$output" '
        $1 == out && $2 == "connected" { in_block = 1; next }
        in_block && /^[^[:space:]]/ { exit }
        in_block && /(^|[[:space:]])(179\.9|180\.0|180\.00|179\.95)/ { found = 1 }
        END { exit(found ? 0 : 1) }
      '; then
        target="$output"
        break
      fi
    done

    if [ -z "$target" ]; then
      if printf '%s\n' "$XRQ" | grep -q '^DP-4 connected'; then
        target="DP-4"
      else
        target="''${connected[0]}"
      fi
    fi

    printf 'target=%s\nconnected=%s\n' "$target" "''${connected[*]}" > /tmp/sddm-monitor-target.log

    for output in "''${connected[@]}"; do
      if [ "$output" = "$target" ]; then
        $XRANDR --output "$output" --primary --auto --pos 0x0 || true
      else
        $XRANDR --output "$output" --off || true
      fi
    done
  '';
}
