# Niri configuration - home-manager module
{ config, pkgs, lib, ... }:

{
  # Niri configuration
  programs.niri = {
    settings = {
      # Input configuration
      input = {
        keyboard = {
          xkb = {
            layout = "ch";
          };
          repeat-delay = 300;
          repeat-rate = 50;
        };
        
        mouse = {
          accel-profile = "flat";
          accel-speed = 0.0;
        };
        
        touchpad = {
          tap = true;
          natural-scroll = true;
          dwt = true;  # Disable while typing
        };
        
        # Focus follows mouse
        focus-follows-mouse = {
          enable = true;
          max-scroll-amount = "0%";
        };
      };

      # Output/monitor configuration (adjust for your setup)
      outputs = {
        # Default output - niri will auto-detect
      };

      # Layout configuration
      layout = {
        gaps = 8;
        
        center-focused-column = "never";
        
        preset-column-widths = [
          { proportion = 1.0 / 3.0; }
          { proportion = 1.0 / 2.0; }
          { proportion = 2.0 / 3.0; }
        ];
        
        default-column-width = { proportion = 1.0 / 2.0; };
        
        focus-ring = {
          enable = true;
          width = 2;
          active.color = "#cba6f7";   # Catppuccin Mauve
          inactive.color = "#45475a"; # Catppuccin Surface1
        };
        
        border = {
          enable = false;
        };
        
        struts = {
          left = 0;
          right = 0;
          top = 0;
          bottom = 0;
        };
      };

      # Spawn processes at startup
      spawn-at-startup = [
        { command = [ "waybar" ]; }
        { command = [ "swaybg" "-i" "${config.home.homeDirectory}/Pictures/wallpaper.jpg" "-m" "fill" ]; }
        { command = [ "mako" ]; }
        { command = [ "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1" ]; }
        { command = [ "nm-applet" "--indicator" ]; }
        { command = [ "wl-paste" "--watch" "cliphist" "store" ]; }
      ];

      # Prefer GTK dialogs
      prefer-no-csd = true;

      # Screenshot path
      screenshot-path = "~/Pictures/Screenshots/screenshot-%Y-%m-%d-%H-%M-%S.png";

      # Hotkey overlay
      hotkey-overlay.skip-at-startup = true;

      # Environment variables
      environment = {
        DISPLAY = ":0";
        QT_QPA_PLATFORM = "wayland";
        GDK_BACKEND = "wayland";
      };

      # Window rules
      window-rules = [
        # Example: Float certain windows
        {
          matches = [
            { app-id = "^pavucontrol$"; }
            { app-id = "^nm-connection-editor$"; }
            { app-id = "^blueman-manager$"; }
          ];
          open-floating = true;
        }
        # Make Firefox PiP float
        {
          matches = [
            { title = "^Picture-in-Picture$"; }
          ];
          open-floating = true;
        }
      ];

      # Keybindings - using action attribute syntax
      binds = {
        # Application launchers
        "Mod+Return".action.spawn = "ghostty";
        "Mod+D".action.spawn = "fuzzel";
        "Mod+E".action.spawn = "nautilus";
        "Mod+B".action.spawn = "firefox";
        
        # Window management
        "Mod+Q".action.close-window = [];
        "Mod+Shift+Q".action.quit.skip-confirmation = true;
        
        # Focus movement (vim-style)
        "Mod+H".action.focus-column-left = [];
        "Mod+J".action.focus-window-down = [];
        "Mod+K".action.focus-window-up = [];
        "Mod+L".action.focus-column-right = [];
        
        # Arrow key alternatives
        "Mod+Left".action.focus-column-left = [];
        "Mod+Down".action.focus-window-down = [];
        "Mod+Up".action.focus-window-up = [];
        "Mod+Right".action.focus-column-right = [];
        
        # Move windows
        "Mod+Shift+H".action.move-column-left = [];
        "Mod+Shift+J".action.move-window-down = [];
        "Mod+Shift+K".action.move-window-up = [];
        "Mod+Shift+L".action.move-column-right = [];
        
        "Mod+Shift+Left".action.move-column-left = [];
        "Mod+Shift+Down".action.move-window-down = [];
        "Mod+Shift+Up".action.move-window-up = [];
        "Mod+Shift+Right".action.move-column-right = [];
        
        # Monitor focus
        "Mod+Shift+Bracketleft".action.focus-monitor-left = [];
        "Mod+Shift+Bracketright".action.focus-monitor-right = [];
        
        # Move window to monitor
        "Mod+Ctrl+Bracketleft".action.move-column-to-monitor-left = [];
        "Mod+Ctrl+Bracketright".action.move-column-to-monitor-right = [];
        
        # Workspace navigation
        "Mod+1".action.focus-workspace = 1;
        "Mod+2".action.focus-workspace = 2;
        "Mod+3".action.focus-workspace = 3;
        "Mod+4".action.focus-workspace = 4;
        "Mod+5".action.focus-workspace = 5;
        "Mod+6".action.focus-workspace = 6;
        "Mod+7".action.focus-workspace = 7;
        "Mod+8".action.focus-workspace = 8;
        "Mod+9".action.focus-workspace = 9;
        
        # Move window to workspace
        "Mod+Shift+1".action.move-column-to-workspace = 1;
        "Mod+Shift+2".action.move-column-to-workspace = 2;
        "Mod+Shift+3".action.move-column-to-workspace = 3;
        "Mod+Shift+4".action.move-column-to-workspace = 4;
        "Mod+Shift+5".action.move-column-to-workspace = 5;
        "Mod+Shift+6".action.move-column-to-workspace = 6;
        "Mod+Shift+7".action.move-column-to-workspace = 7;
        "Mod+Shift+8".action.move-column-to-workspace = 8;
        "Mod+Shift+9".action.move-column-to-workspace = 9;
        
        # Column width adjustments
        "Mod+R".action.switch-preset-column-width = [];
        "Mod+F".action.maximize-column = [];
        "Mod+Shift+F".action.fullscreen-window = [];
        
        # Floating
        "Mod+V".action.toggle-window-floating = [];
        "Mod+Shift+V".action.switch-focus-between-floating-and-tiling = [];
        
        # Column consume/expel
        "Mod+Comma".action.consume-window-into-column = [];
        "Mod+Period".action.expel-window-from-column = [];
        
        # Resize mode
        "Mod+Minus".action.set-column-width = "-10%";
        "Mod+Equal".action.set-column-width = "+10%";
        "Mod+Shift+Minus".action.set-window-height = "-10%";
        "Mod+Shift+Equal".action.set-window-height = "+10%";
        
        # Screenshots
        "Print".action.screenshot = [];
        "Mod+Print".action.screenshot-screen = [];
        "Mod+Shift+Print".action.screenshot-window = [];
        
        # Lock screen
        "Mod+Escape".action.spawn = ["swaylock" "-f" "-c" "1e1e2e"];
        
        # Media keys
        "XF86AudioRaiseVolume".action.spawn = ["pamixer" "-i" "5"];
        "XF86AudioLowerVolume".action.spawn = ["pamixer" "-d" "5"];
        "XF86AudioMute".action.spawn = ["pamixer" "-t"];
        "XF86AudioMicMute".action.spawn = ["pamixer" "--default-source" "-t"];
        "XF86MonBrightnessUp".action.spawn = ["brightnessctl" "set" "+5%"];
        "XF86MonBrightnessDown".action.spawn = ["brightnessctl" "set" "5%-"];
        "XF86AudioPlay".action.spawn = ["playerctl" "play-pause"];
        "XF86AudioNext".action.spawn = ["playerctl" "next"];
        "XF86AudioPrev".action.spawn = ["playerctl" "previous"];
        
        # Power menu (using fuzzel)
        "Mod+Shift+E".action.spawn = ["bash" "-c" ''
          case $(printf "Lock\nLogout\nSuspend\nReboot\nShutdown" | fuzzel -d -w 20 -l 5) in
            Lock) swaylock -f -c 1e1e2e ;;
            Logout) niri msg action quit ;;
            Suspend) systemctl suspend ;;
            Reboot) systemctl reboot ;;
            Shutdown) systemctl poweroff ;;
          esac
        ''];
      };

      # Animations - using the kind attribute for each animation type
      animations = {
        slowdown = 1.0;
        
        workspace-switch.kind.spring = {
          damping-ratio = 1.0;
          stiffness = 1000;
          epsilon = 0.0001;
        };
        
        window-open.kind.easing = {
          duration-ms = 150;
          curve = "ease-out-expo";
        };
        
        window-close.kind.easing = {
          duration-ms = 150;
          curve = "ease-out-quad";
        };
        
        horizontal-view-movement.kind.spring = {
          damping-ratio = 1.0;
          stiffness = 800;
          epsilon = 0.0001;
        };
        
        window-movement.kind.spring = {
          damping-ratio = 1.0;
          stiffness = 800;
          epsilon = 0.0001;
        };
        
        window-resize.kind.spring = {
          damping-ratio = 1.0;
          stiffness = 800;
          epsilon = 0.0001;
        };
        
        config-notification-open-close.kind.spring = {
          damping-ratio = 0.6;
          stiffness = 1000;
          epsilon = 0.001;
        };
      };
    };
  };

  # Waybar configuration for niri
  programs.waybar = {
    enable = true;
    systemd.enable = false;  # We start it in niri spawn-at-startup
    
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 32;
        spacing = 4;
        
        modules-left = [ "niri/workspaces" "niri/window" ];
        modules-center = [ "clock" ];
        modules-right = [ 
          "tray" 
          "pulseaudio" 
          "network" 
          "battery" 
          "custom/power"
        ];
        
        "niri/workspaces" = {
          format = "{icon}";
          format-icons = {
            active = "";
            default = "";
          };
        };
        
        "niri/window" = {
          format = "{}";
          max-length = 50;
        };
        
        clock = {
          format = "  {:%H:%M}";
          format-alt = "  {:%A, %B %d, %Y}";
          tooltip-format = "<tt>{calendar}</tt>";
        };
        
        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{icon}  {capacity}%";
          format-charging = "  {capacity}%";
          format-plugged = "  {capacity}%";
          format-icons = [ "" "" "" "" "" ];
        };
        
        network = {
          format-wifi = "  {signalStrength}%";
          format-ethernet = "  {ipaddr}";
          format-disconnected = "󰤭  Disconnected";
          tooltip-format = "{ifname}: {ipaddr}/{cidr}";
          on-click = "nm-connection-editor";
        };
        
        pulseaudio = {
          format = "{icon}  {volume}%";
          format-muted = "  Muted";
          format-icons = {
            default = [ "" "" "" ];
          };
          on-click = "pavucontrol";
        };
        
        tray = {
          spacing = 10;
        };
        
        "custom/power" = {
          format = "⏻";
          tooltip = false;
          on-click = ''bash -c 'case $(printf "Lock\nLogout\nSuspend\nReboot\nShutdown" | fuzzel -d -w 20 -l 5) in Lock) swaylock -f -c 1e1e2e ;; Logout) niri msg action quit ;; Suspend) systemctl suspend ;; Reboot) systemctl reboot ;; Shutdown) systemctl poweroff ;; esac' '';
        };
      };
    };
    
    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font", monospace;
        font-size: 13px;
        min-height: 0;
      }

      window#waybar {
        background: rgba(30, 30, 46, 0.9);
        color: #cdd6f4;
        border-bottom: 2px solid #313244;
      }

      #workspaces button {
        padding: 0 8px;
        color: #6c7086;
        background: transparent;
        border-radius: 0;
      }

      #workspaces button.active {
        color: #cba6f7;
        background: rgba(203, 166, 247, 0.2);
      }

      #workspaces button:hover {
        background: rgba(203, 166, 247, 0.1);
      }

      #window {
        padding: 0 10px;
        color: #a6adc8;
      }

      #clock {
        padding: 0 12px;
        color: #cba6f7;
        font-weight: bold;
      }

      #battery,
      #network,
      #pulseaudio,
      #tray,
      #custom-power {
        padding: 0 10px;
      }

      #battery {
        color: #a6e3a1;
      }

      #battery.warning {
        color: #f9e2af;
      }

      #battery.critical {
        color: #f38ba8;
      }

      #battery.charging {
        color: #94e2d5;
      }

      #network {
        color: #89b4fa;
      }

      #network.disconnected {
        color: #f38ba8;
      }

      #pulseaudio {
        color: #fab387;
      }

      #pulseaudio.muted {
        color: #6c7086;
      }

      #tray {
        padding: 0 5px;
      }

      #custom-power {
        color: #f38ba8;
        padding-right: 15px;
      }

      tooltip {
        background: #1e1e2e;
        border: 1px solid #313244;
        border-radius: 8px;
      }

      tooltip label {
        color: #cdd6f4;
      }
    '';
  };

  # Fuzzel launcher configuration
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        font = "JetBrainsMono Nerd Font:size=12";
        dpi-aware = "yes";
        terminal = "ghostty";
        layer = "overlay";
        width = 40;
        lines = 10;
        horizontal-pad = 20;
        vertical-pad = 10;
        inner-pad = 5;
      };
      colors = {
        # Catppuccin Mocha
        background = "1e1e2edd";
        text = "cdd6f4ff";
        match = "cba6f7ff";
        selection = "313244ff";
        selection-text = "cdd6f4ff";
        selection-match = "cba6f7ff";
        border = "cba6f7ff";
      };
      border = {
        width = 2;
        radius = 10;
      };
    };
  };

  # Mako notification daemon
  services.mako = {
    enable = true;
    settings = {
      font = "JetBrainsMono Nerd Font 11";
      background-color = "#1e1e2e";
      text-color = "#cdd6f4";
      border-color = "#cba6f7";
      border-size = 2;
      border-radius = 8;
      padding = "15";
      margin = "10";
      width = 350;
      default-timeout = 5000;
      layer = "overlay";
      anchor = "top-right";
    };
  };

  # Swaylock configuration - let catppuccin handle the colors
  programs.swaylock = {
    enable = true;
  };

  # Swayidle for automatic screen locking
  services.swayidle = {
    enable = true;
    events = {
      before-sleep = "${pkgs.swaylock}/bin/swaylock -f";
      lock = "${pkgs.swaylock}/bin/swaylock -f";
    };
    timeouts = [
      { timeout = 300; command = "${pkgs.swaylock}/bin/swaylock -f"; }
      { timeout = 600; command = "niri msg action power-off-monitors"; }
    ];
  };

  # Create Screenshots directory
  home.file."Pictures/Screenshots/.keep".text = "";
}
