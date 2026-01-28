# Waybar configuration for Niri
{ config, pkgs, lib, ... }:

let
  # Script for CPU usage % + temp (using k10temp for AMD)
  cpuScript = pkgs.writeShellScript "waybar-cpu" ''
    # Calculate CPU usage from /proc/stat
    read -r cpu user nice system idle iowait irq softirq _ < /proc/stat
    total1=$((user + nice + system + idle + iowait + irq + softirq))
    idle1=$idle
    sleep 0.2
    read -r cpu user nice system idle iowait irq softirq _ < /proc/stat
    total2=$((user + nice + system + idle + iowait + irq + softirq))
    idle2=$idle
    usage=$((100 * (total2 - total1 - (idle2 - idle1)) / (total2 - total1)))
    
    # Find all temp*_input values from preferred sensors, show highest (for multi-core CPUs)
    max_temp=""
    found=0
    for hwmon in /sys/class/hwmon/hwmon*; do
      name=$(cat "$hwmon/name" 2>/dev/null || true)
      if [ "$name" = "k10temp" ] || [ "$name" = "coretemp" ] || [ "$name" = "acpitz" ]; then
        for f in "$hwmon"/temp*_input; do
          [ -r "$f" ] || continue
          t=$(cat "$f" 2>/dev/null)
          if [ -n "$t" ]; then
            if [ -z "$max_temp" ] || [ "$t" -gt "$max_temp" ]; then
              max_temp="$t"
              found=1
            fi
          fi
        done
      fi
    done
    # Fallback: any hwmon temp*_input
    if [ "$found" -eq 0 ]; then
      for hwmon in /sys/class/hwmon/hwmon*; do
        for f in "$hwmon"/temp*_input; do
          [ -r "$f" ] || continue
          t=$(cat "$f" 2>/dev/null)
          if [ -n "$t" ]; then
            if [ -z "$max_temp" ] || [ "$t" -gt "$max_temp" ]; then
              max_temp="$t"
            fi
          fi
        done
      done
    fi

    if [ -z "$max_temp" ]; then
      temp_c="N/A"
    else
      temp_c=$((max_temp / 1000))
    fi

    echo "$usage% $temp_c°C"
  '';

  # Script for GPU load + VRAM (in GB) + temp
  gpuScript = pkgs.writeShellScript "waybar-gpu" ''
    nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader,nounits 2>/dev/null | \
      awk -F', ' '{printf "%d%% %.1fGB/%.1fGB %d°C", $1, $2/1024, $3/1024, $4}' || echo "N/A"
  '';
in
{
  programs.waybar = {
    enable = true;
    systemd.enable = true;  # Enables StatusNotifierWatcher for tray support
    
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 32;
        spacing = 0;
        margin-top = 0;
        margin-left = 0;
        margin-right = 0;
        exclusive = true;
        
        modules-left = [
          "niri/workspaces"
          "niri/window"
        ];
        
        modules-center = [
          "privacy"
          "clock"
          "idle_inhibitor"
        ];
        
        modules-right = [
          "gamemode"
          
          "custom/cpu"
          "memory"
          "custom/gpu"
          "disk"
          "backlight"
          "wireplumber"
          
          "battery"
          "keyboard-state"
          "power-profiles-daemon"
          "tray"
        ];

        # === Niri Workspaces ===
        "niri/workspaces" = {
          format = "{icon}";
          format-icons = {
            "1" = "󰎤";
            "2" = "󰎧";
            "3" = "󰎪";
            "4" = "󰎭";
            "5" = "󰎱";
            "6" = "󰎳";
            "7" = "󰎶";
            "8" = "󰎹";
            "9" = "󰎼";
            "focused" = "";
            "default" = "";
          };
        };

        # === Active Window ===
        "niri/window" = {
          format = "{}";
          max-length = 50;
          separate-outputs = true;
        };

        # === Clock ===
        clock = {
          format = "  {:%H:%M}";
          format-alt = "  {:%A, %B %d, %Y}";
          tooltip-format = "<tt><small>{calendar}</small></tt>";
          calendar = {
            mode = "month";
            mode-mon-col = 3;
            weeks-pos = "right";
            on-scroll = 1;
            format = {
              months = "<span color='#89b4fa'><b>{}</b></span>";
              days = "<span color='#cdd6f4'><b>{}</b></span>";
              weeks = "<span color='#94e2d5'><b>W{}</b></span>";
              weekdays = "<span color='#f9e2af'><b>{}</b></span>";
              today = "<span color='#a6e3a1'><b><u>{}</u></b></span>";
            };
          };
          actions = {
            on-click-right = "mode";
            on-scroll-up = "shift_up";
            on-scroll-down = "shift_down";
          };
        };

        # === System Tray ===
        tray = {
          icon-size = 16;
          spacing = 8;
        };

        # === Idle Inhibitor (Caffeine replacement) ===
        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = "󰅶";
            deactivated = "󰾪";
          };
          tooltip-format-activated = "Idle inhibitor: ON (screen won't sleep)";
          tooltip-format-deactivated = "Idle inhibitor: OFF";
        };

        # === GameMode ===
        gamemode = {
          format = " ";
          format-alt = " {glyph} {count}";
          glyph = "󰊴";
          hide-not-running = true;
          use-icon = true;
          icon-name = "input-gaming-symbolic";
          icon-spacing = 4;
          icon-size = 16;
          tooltip = true;
          tooltip-format = "Games running: {count}";
        };

        # === PulseAudio ===
        pulseaudio = {
          format = "{icon} {volume}%";
          format-bluetooth = "󰂯 {volume}%";
          format-bluetooth-muted = "󰂲 ";
          format-muted = "󰝟 ";
          format-icons = {
            headphone = "󰋋";
            hands-free = "󰋎";
            headset = "󰋎";
            phone = "";
            portable = "";
            car = "";
            default = [ "󰕿" "󰖀" "󰕾" ];
          };
          on-click = "pamixer -t";
          on-click-right = "pavucontrol";
          tooltip-format = "{desc}: {volume}%";
        };

        

        # === CPU (Load + Temp grouped) ===
        "custom/cpu" = {
          exec = "${cpuScript}";
          format = "󰻠 {}";
          interval = 2;
          tooltip = false;
        };

        # === Memory ===
        memory = {
          format = "󰍛 {percentage}%";
          tooltip-format = "RAM: {used:0.1f}GB / {total:0.1f}GB\nSwap: {swapUsed:0.1f}GB / {swapTotal:0.1f}GB";
          interval = 2;
        };

        # === GPU (Load + VRAM + Temp grouped) ===
        "custom/gpu" = {
          exec = "${gpuScript}";
          format = "󰢮 {}";
          interval = 2;
          tooltip = false;
        };

        # === Disk ===
        disk = {
          format = "󰋊 {free}";
          path = "/";
          interval = 30;
          unit = "GB";
          tooltip-format = "Free: {free} / {total}\nUsed: {used} ({percentage_used}%)";
        };

        # === Wireplumber (PipeWire volume) ===
        wireplumber = {
          format = "{icon} {volume}%";
          format-muted = "󰝟 ";
          format-icons = [ "󰕿" "󰖀" "󰕾" ];
          on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          on-click-right = "pavucontrol";
          on-scroll-up = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%+";
          on-scroll-down = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-";
          tooltip-format = "{node_name}: {volume}%";
        };

        # === Backlight ===
        backlight = {
          format = "{icon} {percent}%";
          format-icons = [ "󰃞" "󰃟" "󰃠" ];
          on-scroll-up = "brightnessctl set 5%+";
          on-scroll-down = "brightnessctl set 5%-";
          tooltip-format = "Brightness: {percent}%";
        };

        # === Battery (shows only if present) ===
        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{icon} {capacity}%";
          format-charging = "󰂄 {capacity}%";
          format-plugged = "󰚥 {capacity}%";
          format-full = "󰁹 Full";
          format-icons = [ "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
          tooltip-format = "{timeTo}\n{power}W";
        };

        # === Bluetooth ===
        bluetooth = {
          format = "󰂯";
          format-disabled = "󰂲";
          format-connected = "󰂱 {num_connections}";
          format-connected-battery = "󰂱 {device_battery_percentage}%";
          tooltip-format = "{controller_alias}\n{status}";
          tooltip-format-connected = "{controller_alias}\n{num_connections} connected\n\n{device_enumerate}";
          tooltip-format-enumerate-connected = "{device_alias}";
          tooltip-format-enumerate-connected-battery = "{device_alias}: {device_battery_percentage}%";
          on-click = "blueman-manager";
        };

        # === Privacy (camera/mic in use) ===
        privacy = {
          icon-spacing = 4;
          icon-size = 14;
          transition-duration = 250;
          modules = [
            {
              type = "screenshare";
              tooltip = true;
              tooltip-icon-size = 24;
            }
            {
              type = "audio-in";
              tooltip = true;
              tooltip-icon-size = 24;
            }
            {
              type = "audio-out";
              tooltip = true;
              tooltip-icon-size = 24;
            }
          ];
        };

        # === Keyboard State ===
        keyboard-state = {
          capslock = true;
          numlock = true;
          format = "{icon}";
          format-icons = {
            locked = "󰪛";
            unlocked = "";
          };
        };

        # === Power Profiles Daemon ===
        power-profiles-daemon = {
          format = "{icon}";
          tooltip-format = "Power profile: {profile}\nDriver: {driver}";
          tooltip = true;
          format-icons = {
            default = "󰗑";
            performance = "󰓅";
            balanced = "󰾅";
            power-saver = "󰾆";
          };
        };
      };
    };

    style = ''
      /* === Catppuccin Mocha Colors === */
      @define-color base #1e1e2e;
      @define-color mantle #181825;
      @define-color crust #11111b;
      @define-color surface0 #313244;
      @define-color surface1 #45475a;
      @define-color surface2 #585b70;
      @define-color overlay0 #6c7086;
      @define-color overlay1 #7f849c;
      @define-color overlay2 #9399b2;
      @define-color text #cdd6f4;
      @define-color subtext0 #a6adc8;
      @define-color subtext1 #bac2de;
      @define-color lavender #b4befe;
      @define-color blue #89b4fa;
      @define-color sapphire #74c7ec;
      @define-color sky #89dceb;
      @define-color teal #94e2d5;
      @define-color green #a6e3a1;
      @define-color yellow #f9e2af;
      @define-color peach #fab387;
      @define-color maroon #eba0ac;
      @define-color red #f38ba8;
      @define-color mauve #cba6f7;
      @define-color pink #f5c2e7;
      @define-color flamingo #f2cdcd;
      @define-color rosewater #f5e0dc;

      /* === Global Styles === */
      * {
        font-family: "JetBrainsMono Nerd Font", "Font Awesome 6 Free", sans-serif;
        font-size: 13px;
        min-height: 0;
        border: none;
        border-radius: 0;
      }

      window#waybar {
        background: alpha(@base, 0.9);
        color: @text;
        border-radius: 0 0 8px 8px;
      }

      window#waybar.hidden {
        opacity: 0.1;
      }

      /* === Module Styling === */
      #workspaces,
      #window,
      #clock,
      #tray,
      #idle_inhibitor,
      #gamemode,
      #pulseaudio,
      #wireplumber,
      #network,
      #custom-cpu,
      #custom-gpu,
      #memory,
      #disk,
      #backlight,
      #battery,
      #bluetooth,
      #privacy,
      #keyboard-state,
      #power-profiles-daemon {
        padding: 0 12px;
        margin: 4px 2px;
        background: @surface0;
        border-radius: 8px;
      }

      /* === Workspaces === */
      #workspaces {
        padding: 0 4px;
      }

      #workspaces button {
        padding: 0 8px;
        color: @overlay1;
        background: transparent;
        border-radius: 8px;
        transition: all 0.2s ease;
      }

      #workspaces button:hover {
        color: @mauve;
        background: @surface1;
      }

      #workspaces button.focused,
      #workspaces button.active {
        color: @base;
        background: @mauve;
      }

      #workspaces button.urgent {
        color: @base;
        background: @red;
      }

      /* === Window Title === */
      #window {
        color: @lavender;
        font-weight: bold;
      }

      /* === Clock === */
      #clock {
        color: @lavender;
        font-weight: bold;
      }

      /* === Tray === */
      #tray {
        background: @surface0;
      }

      #tray > .passive {
        -gtk-icon-effect: dim;
      }

      #tray > .needs-attention {
        -gtk-icon-effect: highlight;
        background: @red;
      }

      /* === Idle Inhibitor (Caffeine) === */
      #idle_inhibitor {
        color: @pink;
      }

      #idle_inhibitor.activated {
        color: @red;
      }

      /* === GameMode === */
      #gamemode {
        color: @peach;
      }

      #gamemode.running {
        color: @green;
      }

      /* === PulseAudio === */
      #pulseaudio {
        color: @mauve;
      }

      #pulseaudio.muted {
        color: @overlay0;
      }

      /* === Network === */
      #network {
        color: @teal;
      }

      #network.disconnected {
        color: @red;
      }

      /* === CPU === */
      #custom-cpu {
        color: @pink;
      }

      /* === Memory === */
      #memory {
        color: @mauve;
      }

      /* === Temperature === */
      #temperature {
        color: @green;
      }

      #temperature.critical {
        color: @red;
        animation: blink 0.5s linear infinite alternate;
      }

      /* === GPU === */
      #custom-gpu {
        color: @red;
      }

      /* === Disk === */
      #disk {
        color: @maroon;
      }

      /* === Wireplumber === */
      #wireplumber {
        color: @peach;
      }

      #wireplumber.muted {
        color: @overlay0;
      }

      /* === Backlight === */
      #backlight {
        color: @yellow;
      }

      /* === Battery === */
      #battery {
        color: @green;
      }

      #battery.charging {
        color: @green;
      }

      #battery.warning:not(.charging) {
        color: @yellow;
      }

      #battery.critical:not(.charging) {
        color: @red;
        animation: blink 0.5s linear infinite alternate;
      }

      /* === Bluetooth === */
      #bluetooth {
        color: @pink;
      }

      #bluetooth.disabled {
        color: @overlay0;
      }

      #bluetooth.connected {
        color: @mauve;
      }

      /* === Privacy === */
      #privacy {
        color: @red;
      }

      #privacy-item {
        padding: 0 4px;
      }

      /* === Keyboard State === */
      #keyboard-state {
        color: @yellow;
      }

      #keyboard-state label.locked {
        color: @peach;
      }

      /* === Power Profiles === */
      #power-profiles-daemon {
        color: @green;
      }

      /* === Animation === */
      @keyframes blink {
        to {
          background: @red;
          color: @base;
        }
      }

      /* === Tooltip === */
      tooltip {
        background: @base;
        border: 1px solid @mauve;
        border-radius: 8px;
      }

      tooltip label {
        color: @text;
        padding: 8px;
      }
    '';
  };
}
