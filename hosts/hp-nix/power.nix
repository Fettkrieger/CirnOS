# HP Envy x360 Power Management
# - power-profiles-daemon for interactive profile switching (Noctalia + CLI)
# - Battery charge threshold at 80% for long-term battery health
# - thermald for Intel thermal management
{ config, pkgs, lib, ... }:

{
  # power-profiles-daemon: 3 profiles (performance, balanced, power-saver)
  # Noctalia widget can cycle profiles, CLI via powerprofilesctl
  services.power-profiles-daemon.enable = true;

  # Intel thermal daemon - works alongside ppd on Tiger Lake
  services.thermald.enable = true;

  # Battery charge threshold: stop charging at 80% to preserve battery health.
  # HP laptops expose this via sysfs. The threshold resets on boot and
  # sometimes on AC plug/unplug, so we re-apply via systemd + udev.
  systemd.services.battery-charge-threshold = {
    description = "Set battery charge threshold to 80%";
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bash}/bin/bash -c 'if [ -f /sys/class/power_supply/BAT0/charge_control_end_threshold ]; then echo 80 > /sys/class/power_supply/BAT0/charge_control_end_threshold; elif [ -f /sys/class/power_supply/BAT1/charge_control_end_threshold ]; then echo 80 > /sys/class/power_supply/BAT1/charge_control_end_threshold; fi'";
    };
  };

  # Re-apply charge threshold when AC adapter state changes
  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", RUN+="${pkgs.systemd}/bin/systemctl restart battery-charge-threshold.service"
  '';
}
