# Waybar configuration for Niri
{ config, pkgs, lib, ... }:

{
  programs.waybar = {
    enable = true;
    
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 0;
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
          "clock"
        ];
        
        modules-right = [
          "idle_inhibitor"
          "tray"
          "gamemode"
          "pulseaudio"
          "network"
          "cpu"
          "memory"
          "temperature"
          "custom/gpu-temp"
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
              months = "<span color='#cba6f7'><b>{}</b></span>";
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

        # === Network ===
        network = {
          format-wifi = "󰤨 {signalStrength}%";
          format-ethernet = "󰈀 {bandwidthDownBytes}";
          format-linked = "󰈀 (No IP)";
          format-disconnected = "󰤭 ";
          format-alt = "{ifname}: {ipaddr}/{cidr}";
          tooltip-format = "{ifname} via {gwaddr}\n{ipaddr}/{cidr}\n\n⬇️ {bandwidthDownBytes} ⬆️ {bandwidthUpBytes}";
          interval = 2;
        };

        # === CPU ===
        cpu = {
          format = "󰻠 {usage}%";
          tooltip = true;
          interval = 2;
        };

        # === Memory ===
        memory = {
          format = "󰍛 {percentage}%";
          tooltip-format = "RAM: {used:0.1f}GB / {total:0.1f}GB\nSwap: {swapUsed:0.1f}GB / {swapTotal:0.1f}GB";
          interval = 2;
        };

        # === Temperature (CPU) ===
        temperature = {
          hwmon-path-abs = "/sys/devices/pci0000:00/0000:00:18.3/hwmon";
          input-filename = "temp1_input";
          critical-threshold = 90;
          format = " {temperatureC}°C";
          format-critical = " {temperatureC}°C";
          interval = 2;
        };

        # === GPU Temperature (Custom) ===
        "custom/gpu-temp" = {
          exec = "nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null || echo 'N/A'";
          format = "󰢮 {}°C";
          interval = 5;
          tooltip = false;
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
        opacity: 0.2;
      }

      /* === Module Styling === */
      #workspaces,
      #window,
      #clock,
      #tray,
      #idle_inhibitor,
      #gamemode,
      #pulseaudio,
      #network,
      #cpu,
      #memory,
      #temperature,
      #custom-gpu-temp {
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
        color: @text;
        font-weight: bold;
      }

      /* === Clock === */
      #clock {
        color: @mauve;
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
        color: @overlay1;
      }

      #idle_inhibitor.activated {
        color: @green;
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
        color: @sapphire;
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
      #cpu {
        color: @blue;
      }

      /* === Memory === */
      #memory {
        color: @lavender;
      }

      /* === Temperature === */
      #temperature {
        color: @green;
      }

      #temperature.critical {
        color: @red;
        animation: blink 0.5s linear infinite alternate;
      }

      /* === GPU Temperature === */
      #custom-gpu-temp {
        color: @peach;
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
