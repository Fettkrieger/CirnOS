# ThinkPad E16 Gen 2 AMD power and laptop reliability defaults.
{ lib, pkgs, ... }:

let
  lenuwuPowerPolicy = pkgs.writeShellScript "lenuwu-power-policy" ''
    set -eu

    export PATH=${lib.makeBinPath [
      pkgs.coreutils
      pkgs.tlp
      pkgs.tlp-pd
    ]}

    ac_online=0
    battery_capacity=

    for supply in /sys/class/power_supply/*; do
      [ -e "$supply/type" ] || continue

      type=$(cat "$supply/type")

      if [ "$type" = "Battery" ]; then
        if [ -r "$supply/capacity" ]; then
          capacity=$(cat "$supply/capacity")
          case "$capacity" in
            ""|*[!0-9]*) ;;
            *)
              if [ -z "$battery_capacity" ] || [ "$capacity" -lt "$battery_capacity" ]; then
                battery_capacity=$capacity
              fi
              ;;
          esac
        fi
      elif [ -r "$supply/online" ] && [ "$(cat "$supply/online")" = "1" ]; then
        ac_online=1
      fi
    done

    if [ -z "$battery_capacity" ]; then
      battery_capacity=100
    fi

    state_dir=/run/lenuwu-power-policy
    ac_state_file="$state_dir/ac-online"

    holds=$(tlpctl list-holds 2>/dev/null || true)
    if [ -n "$holds" ]; then
      exit 0
    fi

    if [ "$ac_online" = "1" ]; then
      profile=balanced
      brightness_cap=
    elif [ "$battery_capacity" -le 30 ]; then
      profile=power-saver
      if [ "$battery_capacity" -le 15 ]; then
        brightness_cap=30
      else
        brightness_cap=50
      fi
    elif [ "$battery_capacity" -le 60 ]; then
      profile=balanced
      brightness_cap=80
    else
      profile=balanced
      brightness_cap=80
    fi

    mkdir -p "$state_dir"

    last_ac_online=
    if [ -r "$ac_state_file" ]; then
      last_ac_online=$(cat "$ac_state_file")
      case "$last_ac_online" in
        0|1) ;;
        *) last_ac_online= ;;
      esac
    fi

    # Manual profile changes should stick. Auto-switch only after the AC state
    # actually changes; the first run just seeds the state for future checks.
    if [ -z "$last_ac_online" ]; then
      printf '%s\n' "$ac_online" > "$ac_state_file"
    elif [ "$last_ac_online" != "$ac_online" ]; then
      current_profile=$(tlpctl get 2>/dev/null || true)
      if [ "$current_profile" != "$profile" ]; then
        tlpctl set "$profile" >/dev/null || tlp "$profile" >/dev/null
      fi
      printf '%s\n' "$ac_online" > "$ac_state_file"
    fi

    if [ -n "$brightness_cap" ]; then
      for backlight in /sys/class/backlight/*; do
        [ -r "$backlight/max_brightness" ] || continue
        [ -r "$backlight/brightness" ] || continue
        [ -w "$backlight/brightness" ] || continue

        max=$(cat "$backlight/max_brightness")
        current=$(cat "$backlight/brightness")
        case "$max:$current" in
          *[!0-9:]*|:|*:|"") continue ;;
        esac

        target=$((max * brightness_cap / 100))
        if [ "$target" -lt 1 ]; then
          target=1
        fi

        if [ "$current" -gt "$target" ]; then
          echo "$target" > "$backlight/brightness"
        fi
      done
    fi
  '';
in

{
  # systemd 260 records the selected swap file and resume offset in the EFI
  # HibernateLocation variable before hibernating; systemd initrd reads it back
  # during the next boot, so no static resume_offset is needed here.
  boot.initrd.systemd.enable = true;

  swapDevices = [
    {
      device = "/var/lib/hibernate-swapfile";
      size = 36 * 1024;
      priority = 1;
    }
  ];

  services.power-profiles-daemon.enable = lib.mkForce false;

  services.logind.settings.Login = {
    HandleLidSwitch = "hibernate";
    HandleLidSwitchExternalPower = "hibernate";
    HandleLidSwitchDocked = "hibernate";
    IdleAction = "hibernate";
    IdleActionSec = "30min";
  };

  systemd.sleep.settings.Sleep = {
    AllowHibernation = true;
    HibernateMode = "platform shutdown";
    HibernateState = "disk";
  };

  services.tlp = {
    enable = true;
    pd.enable = true;

    settings = {
      # The custom policy service below owns AC-transition profile changes.
      TLP_AUTO_SWITCH = 0;
      TLP_DEFAULT_MODE = "BAL";

      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 80;
      RESTORE_THRESHOLDS_ON_BAT = 1;

      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "balanced";
      PLATFORM_PROFILE_ON_SAV = "low-power";

      CPU_DRIVER_OPMODE_ON_AC = "active";
      CPU_DRIVER_OPMODE_ON_BAT = "active";
      CPU_DRIVER_OPMODE_ON_SAV = "active";
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_SCALING_GOVERNOR_ON_SAV = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
      CPU_ENERGY_PERF_POLICY_ON_SAV = "power";
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 1;
      CPU_BOOST_ON_SAV = 0;

      RADEON_DPM_PERF_LEVEL_ON_AC = "high";
      RADEON_DPM_PERF_LEVEL_ON_BAT = "auto";
      AMDGPU_ABM_LEVEL_ON_AC = 0;
      AMDGPU_ABM_LEVEL_ON_BAT = 1;
      AMDGPU_ABM_LEVEL_ON_SAV = 3;

      SOUND_POWER_SAVE_ON_AC = 0;
      SOUND_POWER_SAVE_ON_BAT = 1;
      PCIE_ASPM_ON_AC = "performance";
      PCIE_ASPM_ON_BAT = "powersave";
      RUNTIME_PM_ON_AC = "on";
      RUNTIME_PM_ON_BAT = "auto";

      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";

      RUNTIME_PM_DRIVER_DENYLIST = "amdgpu rtw89_8852ce rtw89_pci btusb xhci_hcd";
    };
  };

  systemd.services.lenuwu-power-policy = {
    description = "Apply lenuwu AC-transition power profile and brightness policy";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = lenuwuPowerPolicy;
    };
  };

  systemd.timers.lenuwu-power-policy = {
    description = "Re-apply lenuwu brightness policy and detect AC changes";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "30s";
      OnUnitActiveSec = "30s";
      AccuracySec = "5s";
      Unit = "lenuwu-power-policy.service";
    };
  };

  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", RUN+="${pkgs.systemd}/bin/systemctl start --no-block lenuwu-power-policy.service"
  '';

  zramSwap = {
    enable = true;
    memoryPercent = 25;
    algorithm = "zstd";
    priority = 100;
  };

  services.fstrim.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
}
