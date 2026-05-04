# HP Envy x360 Power Management
# - power-profiles-daemon for interactive profile switching (Noctalia + CLI)
# - thermald for Intel thermal management
{ config, pkgs, lib, ... }:

{
  # Required for battery telemetry in desktop shells/widgets (Noctalia, etc.)
  services.upower.enable = true;

  # power-profiles-daemon: 3 profiles (performance, balanced, power-saver)
  # Noctalia widget can cycle profiles, CLI via powerprofilesctl
  services.power-profiles-daemon.enable = true;

  # Intel thermal daemon - works alongside ppd on Tiger Lake
  services.thermald.enable = true;
}
