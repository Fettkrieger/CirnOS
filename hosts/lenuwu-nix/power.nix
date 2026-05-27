# ThinkPad E16 Gen 2 AMD power and laptop reliability defaults.
{ lib, pkgs, ... }:

let
  lenuwuWifiPowerPolicy = pkgs.writeShellScript "lenuwu-wifi-power-policy" ''
    set -eu

    export PATH=${lib.makeBinPath [
      pkgs.coreutils
      pkgs.iw
      pkgs.tlp-pd
    ]}

    # TLP writes its profile state before all profile side effects have fully
    # settled, so give tlp/tlp-pd a brief moment before applying our override.
    sleep 0.2

    profile=$(tlpctl get 2>/dev/null || true)
    case "$profile" in
      power-saver)
        wifi_power_save=on
        runtime_pm=auto
        ;;
      performance|balanced)
        wifi_power_save=off
        runtime_pm=on
        ;;
      *)
        wifi_power_save=off
        runtime_pm=on
        ;;
    esac

    for iface_path in /sys/class/net/*; do
      [ -d "$iface_path" ] || continue
      [ -d "$iface_path/wireless" ] || continue

      iface=''${iface_path##*/}
      iw dev "$iface" set power_save "$wifi_power_save" >/dev/null 2>&1 || true

      if [ -w "$iface_path/device/power/control" ]; then
        (printf '%s\n' "$runtime_pm" > "$iface_path/device/power/control") || true
      fi
    done
  '';

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
    battery_state_file="$state_dir/battery-capacity"
    profile_state_file="$state_dir/tlp-profile"

    mkdir -p "$state_dir"

    read_state() {
      file=$1
      if [ -r "$file" ]; then
        cat "$file"
      fi
    }

    set_brightness_percent() {
      percent=$1

      for backlight in /sys/class/backlight/*; do
        [ -r "$backlight/max_brightness" ] || continue
        [ -w "$backlight/brightness" ] || continue

        max=$(cat "$backlight/max_brightness")
        case "$max:$percent" in
          *[!0-9:]*|:|*:|"") continue ;;
        esac

        target=$((max * percent / 100))
        if [ "$target" -lt 1 ]; then
          target=1
        elif [ "$target" -gt "$max" ]; then
          target=$max
        fi

        printf '%s\n' "$target" > "$backlight/brightness"
      done
    }

    current_profile=$(tlpctl get 2>/dev/null || true)
    case "$current_profile" in
      performance|balanced|power-saver) ;;
      *) current_profile=unknown ;;
    esac

    last_ac_online=$(read_state "$ac_state_file" || true)
    case "$last_ac_online" in
      0|1) ;;
      *) last_ac_online= ;;
    esac

    last_battery_capacity=$(read_state "$battery_state_file" || true)
    case "$last_battery_capacity" in
      ""|*[!0-9]*) last_battery_capacity= ;;
    esac

    last_profile=$(read_state "$profile_state_file" || true)
    case "$last_profile" in
      performance|balanced|power-saver|unknown) ;;
      *) last_profile= ;;
    esac

    first_run=0
    if [ -z "$last_ac_online" ] || [ -z "$last_battery_capacity" ] || [ -z "$last_profile" ]; then
      first_run=1
    fi

    ac_changed=0
    if [ -n "$last_ac_online" ] && [ "$last_ac_online" != "$ac_online" ]; then
      ac_changed=1
    fi

    battery_changed=0
    if [ -n "$last_battery_capacity" ] && [ "$last_battery_capacity" != "$battery_capacity" ]; then
      battery_changed=1
    fi

    profile_changed=0
    if [ -n "$last_profile" ] && [ "$last_profile" != "$current_profile" ]; then
      profile_changed=1
    fi

    brightness_percent=
    auto_profile_event=0
    if [ "$first_run" = "1" ] || [ "$ac_changed" = "1" ] || [ "$battery_changed" = "1" ]; then
      auto_profile_event=1
    fi

    holds=$(tlpctl list-holds 2>/dev/null || true)

    if [ "$ac_online" = "1" ]; then
      profile=balanced
      if [ "$auto_profile_event" = "1" ]; then
        brightness_percent=100
      fi
    elif [ "$battery_capacity" -le 40 ]; then
      profile=power-saver
      if [ "$auto_profile_event" = "1" ]; then
        brightness_percent=40
      fi
    else
      profile=balanced
      if [ "$auto_profile_event" = "1" ]; then
        brightness_percent=80
      fi
    fi

    if [ "$auto_profile_event" = "1" ] && [ -z "$holds" ]; then
      if [ "$current_profile" != "$profile" ]; then
        tlpctl set "$profile" >/dev/null || tlp "$profile" >/dev/null
        current_profile=$(tlpctl get 2>/dev/null || printf '%s\n' "$profile")
      fi
    fi

    if [ "$profile_changed" = "1" ] && [ "$ac_online" = "0" ] && [ "$current_profile" = "power-saver" ]; then
      brightness_percent=40
    fi

    if [ -n "$brightness_percent" ]; then
      set_brightness_percent "$brightness_percent"
    fi

    printf '%s\n' "$ac_online" > "$ac_state_file"
    printf '%s\n' "$battery_capacity" > "$battery_state_file"
    printf '%s\n' "$current_profile" > "$profile_state_file"

    ${lenuwuWifiPowerPolicy}
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
      # TLP maps balanced and power-saver to WIFI_PWR_ON_BAT; a local service
      # below re-enables Wi-Fi power saving only when the active profile is SAV.
      WIFI_PWR_ON_BAT = "off";

      RUNTIME_PM_DRIVER_DENYLIST = "amdgpu rtw89_8852ce rtw89_pci btusb xhci_hcd";
    };
  };

  systemd.services.lenuwu-power-policy = {
    description = "Apply lenuwu event-based power profile and brightness policy";
    wantedBy = [ "multi-user.target" ];
    after = [ "tlp.service" "tlp-pd.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = lenuwuPowerPolicy;
    };
  };

  systemd.services.lenuwu-wifi-power-policy = {
    description = "Apply lenuwu Wi-Fi power policy for the active TLP profile";
    after = [ "tlp.service" "tlp-pd.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = lenuwuWifiPowerPolicy;
    };
  };

  systemd.paths.lenuwu-power-policy-profile = {
    description = "Apply lenuwu brightness policy after TLP profile changes";
    wantedBy = [ "multi-user.target" ];
    pathConfig = {
      PathChanged = "/run/tlp/last_pwr";
      Unit = "lenuwu-power-policy.service";
    };
  };

  systemd.paths.lenuwu-wifi-power-policy = {
    description = "Re-apply lenuwu Wi-Fi power policy after TLP profile changes";
    wantedBy = [ "multi-user.target" ];
    pathConfig = {
      PathChanged = "/run/tlp/last_pwr";
      Unit = "lenuwu-wifi-power-policy.service";
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
