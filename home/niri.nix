# Niri compositor configuration
{ config, pkgs, lib, inputs, ... }:

{
  # Niri packages and tools
  home.packages = with pkgs; [
    # === Core Niri Tools ===
    fuzzel                    # App launcher
    mako                      # Notifications
    swaylock-effects          # Screen locker with effects
    swayidle                  # Idle management
    
    # === Screenshots ===
    grim                      # Screenshot tool
    slurp                     # Area selector
    swappy                    # Screenshot editor
    
    # === Wallpaper ===
    swww                      # Animated wallpaper daemon
    
    # === Clipboard ===
    cliphist                  # Clipboard history
    
    # === Utilities ===
    brightnessctl             # Brightness control
    playerctl                 # Media player control
    pamixer                   # PulseAudio mixer CLI
    networkmanagerapplet      # Network tray icon
    
    # === XWayland ===
    xwayland-satellite        # XWayland support for Niri
    
    # === Authentication ===
    polkit_gnome              # Polkit authentication agent
  ];

  # Niri compositor configuration using niri-flake settings
  programs.niri = {
    settings = {
      # === Environment Variables (NVIDIA) ===
      environment = {
        "NIXOS_OZONE_WL" = "1";
        "ELECTRON_OZONE_PLATFORM_HINT" = "wayland";
        "MOZ_ENABLE_WAYLAND" = "1";
        "QT_QPA_PLATFORM" = "wayland";
        "SDL_VIDEODRIVER" = "wayland";
        "GDK_BACKEND" = "wayland";
        "LIBVA_DRIVER_NAME" = "nvidia";
        "GBM_BACKEND" = "nvidia-drm";
        "__GLX_VENDOR_LIBRARY_NAME" = "nvidia";
        "WLR_NO_HARDWARE_CURSORS" = "1";
        "DISPLAY" = ":0";  # For xwayland-satellite
      };

      # === Startup Applications ===
      spawn-at-startup = [
        { command = [ "xwayland-satellite" ]; }
        { command = [ "swww-daemon" ]; }
        { command = [ "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1" ]; }
        { command = [ "mako" ]; }
        { command = [ "nm-applet" "--indicator" ]; }
        { command = [ "wl-paste" "--watch" "cliphist" "store" ]; }
        { command = [ "waybar" ]; }
        { command = [ "swayidle" "-w"
            "timeout" "300" "swaylock -f"
            "timeout" "600" "niri msg action power-off-monitors"
            "before-sleep" "swaylock -f"
          ]; }
      ];

      # === Monitor Configuration ===
      # Left: DP-5 (vertical), Center: DP-4 (primary), Right: DP-6
      outputs = {
        "DP-5" = {
          mode = {
            width = 2560;
            height = 1440;
            refresh = 154.94;
          };
          scale = 1.0;
          transform = "90";  # Rotated left (vertical)
          position = {
            x = 0;
            y = 0;
          };
        };
        "DP-4" = {
          mode = {
            width = 2560;
            height = 1440;
            refresh = 179.85;
          };
          scale = 1.0;
          position = {
            x = 1440;  # After vertical monitor (1440 wide when rotated)
            y = 560;   # Centered vertically (2560-1440)/2
          };
        };
        "DP-6" = {
          mode = {
            width = 2560;
            height = 1440;
            refresh = 154.94;
          };
          scale = 1.0;
          position = {
            x = 4000;  # After DP-4 (1440 + 2560)
            y = 560;   # Aligned with center monitor
          };
        };
      };

      # === Input Configuration ===
      input = {
        keyboard = {
          xkb = {
            layout = "ch";
          };
        };
        mouse = {
          accel-profile = "flat";
          accel-speed = 0.0;
        };
        touchpad = {
          tap = true;
          natural-scroll = true;
        };
        # Focus follows mouse
        focus-follows-mouse = {
          enable = true;
          max-scroll-amount = "0%";
        };
      };

      # === Layout Configuration ===
      layout = {
        gaps = 8;
        
        center-focused-column = "never";
        
        # Preset column widths (cycle with Super+R)
        preset-column-widths = [
          { proportion = 1.0 / 3.0; }
          { proportion = 1.0 / 2.0; }
          { proportion = 2.0 / 3.0; }
        ];
        
        # Default window width
        default-column-width = { proportion = 1.0 / 2.0; };
        
        # Focus ring (border around focused window)
        focus-ring = {
          enable = true;
          width = 2;
          active.color = "#cba6f7";   # Catppuccin Mauve
          inactive.color = "#45475a"; # Catppuccin Surface1
        };
        
        # Window border
        border = {
          enable = false;
        };
        
        # Struts (reserved space for bars)
        struts = {
          top = 32;  # Space for waybar
        };
      };

      # === Cursor ===
      cursor = {
        theme = "catppuccin-mocha-mauve-cursors";
        size = 24;
      };

      # === Prefer GTK/GNOME dialogs ===
      prefer-no-csd = true;

      # === Screenshot Path ===
      screenshot-path = "~/Pictures/Screenshots/%Y-%m-%d_%H-%M-%S.png";

      # === Animations ===
      animations = {
        # Enable smooth animations
        slowdown = 1.0;
      };

      # === Window Rules ===
      window-rules = [
        # Steam windows float
        {
          matches = [{ app-id = "^steam$"; }];
          open-floating = true;
        }
        # Picture-in-picture
        {
          matches = [{ title = "Picture-in-Picture"; }];
          open-floating = true;
        }
        # File dialogs
        {
          matches = [{ app-id = "^xdg-desktop-portal-gtk$"; }];
          open-floating = true;
        }
        # Polkit
        {
          matches = [{ app-id = "^polkit-gnome-authentication-agent-1$"; }];
          open-floating = true;
        }
      ];

      # === Keybindings ===
      binds = with config.lib.niri.actions; {
        # === Window Management ===
        "Super+Q".action = close-window;
        "Super+F".action = maximize-column;
        
        # === Focus (Super+Ctrl+Arrows) ===
        "Super+Ctrl+Left".action = focus-column-left;
        "Super+Ctrl+Right".action = focus-column-right;
        "Super+Ctrl+Up".action = focus-window-up;
        "Super+Ctrl+Down".action = focus-window-down;
        
        # === Move Windows (Super+Shift+Arrows) ===
        "Super+Shift+Left".action = move-column-left;
        "Super+Shift+Right".action = move-column-right;
        "Super+Shift+Up".action = move-window-up;
        "Super+Shift+Down".action = move-window-down;
        
        # === Scroll View (Super+Arrows) ===
        "Super+Left".action = focus-column-left;
        "Super+Right".action = focus-column-right;
        
        # === Column Management ===
        "Super+BracketLeft".action = consume-window-into-column;
        "Super+BracketRight".action = expel-window-from-column;
        
        # === Resize ===
        "Super+R".action = switch-preset-column-width;
        "Super+Minus".action = set-column-width "-10%";
        "Super+Equal".action = set-column-width "+10%";
        
        # === Workspaces (1-9) ===
        "Super+1".action = focus-workspace 1;
        "Super+2".action = focus-workspace 2;
        "Super+3".action = focus-workspace 3;
        "Super+4".action = focus-workspace 4;
        "Super+5".action = focus-workspace 5;
        "Super+6".action = focus-workspace 6;
        "Super+7".action = focus-workspace 7;
        "Super+8".action = focus-workspace 8;
        "Super+9".action = focus-workspace 9;
        
        # === Move to Workspace ===
        "Super+Shift+1".action = move-column-to-workspace 1;
        "Super+Shift+2".action = move-column-to-workspace 2;
        "Super+Shift+3".action = move-column-to-workspace 3;
        "Super+Shift+4".action = move-column-to-workspace 4;
        "Super+Shift+5".action = move-column-to-workspace 5;
        "Super+Shift+6".action = move-column-to-workspace 6;
        "Super+Shift+7".action = move-column-to-workspace 7;
        "Super+Shift+8".action = move-column-to-workspace 8;
        "Super+Shift+9".action = move-column-to-workspace 9;
        
        # === Monitor Focus ===
        "Super+Comma".action = focus-monitor-left;
        "Super+Period".action = focus-monitor-right;
        
        # === Move to Monitor ===
        "Super+Shift+Comma".action = move-column-to-monitor-left;
        "Super+Shift+Period".action = move-column-to-monitor-right;
        
        # === Scroll/Navigation ===
        "Super+Home".action = focus-column-first;
        "Super+End".action = focus-column-last;
        "Super+C".action = center-column;
        
        # === Launchers ===
        "Super+Return".action = spawn "ghostty";
        "Super+D".action = spawn "fuzzel";
        
        # === Screenshots ===
        "Super+Shift+S".action = screenshot;
        "Print".action = screenshot-screen;
        "Super+Print".action = screenshot-window;
        
        # === System ===
        "Super+Escape".action = spawn "swaylock";
        "Super+Shift+E".action = quit;
        "Super+Shift+R".action = spawn "sh" "-c" "niri msg action reload-config";
        
        # === Media Keys ===
        "XF86AudioRaiseVolume".action = spawn "pamixer" "-i" "5";
        "XF86AudioLowerVolume".action = spawn "pamixer" "-d" "5";
        "XF86AudioMute".action = spawn "pamixer" "-t";
        "XF86AudioPlay".action = spawn "playerctl" "play-pause";
        "XF86AudioNext".action = spawn "playerctl" "next";
        "XF86AudioPrev".action = spawn "playerctl" "previous";
        
        # === Brightness ===
        "XF86MonBrightnessUp".action = spawn "brightnessctl" "set" "+5%";
        "XF86MonBrightnessDown".action = spawn "brightnessctl" "set" "5%-";
        
        # === Clipboard History ===
        "Super+V".action = spawn "sh" "-c" "cliphist list | fuzzel -d | cliphist decode | wl-copy";
      };
    };
  };

  # Mako notification daemon configuration
  services.mako = {
    enable = true;
    defaultTimeout = 5000;
    borderRadius = 8;
    borderSize = 2;
    padding = "12";
    # Catppuccin Mocha colors
    backgroundColor = "#1e1e2e";
    textColor = "#cdd6f4";
    borderColor = "#cba6f7";
    progressColor = "#cba6f7";
  };

  # Swaylock configuration
  programs.swaylock = {
    enable = true;
    package = pkgs.swaylock-effects;
    settings = {
      # Catppuccin Mocha
      color = "1e1e2e";
      inside-color = "1e1e2e";
      line-color = "1e1e2e";
      ring-color = "cba6f7";
      key-hl-color = "a6e3a1";
      bs-hl-color = "f38ba8";
      text-color = "cdd6f4";
      
      inside-clear-color = "1e1e2e";
      line-clear-color = "1e1e2e";
      ring-clear-color = "a6e3a1";
      text-clear-color = "cdd6f4";
      
      inside-ver-color = "1e1e2e";
      line-ver-color = "1e1e2e";
      ring-ver-color = "89b4fa";
      text-ver-color = "cdd6f4";
      
      inside-wrong-color = "1e1e2e";
      line-wrong-color = "1e1e2e";
      ring-wrong-color = "f38ba8";
      text-wrong-color = "cdd6f4";
      
      # Effects
      clock = true;
      indicator = true;
      indicator-radius = 100;
      indicator-thickness = 7;
      effect-blur = "7x5";
      effect-vignette = "0.5:0.5";
      grace = 2;
      fade-in = 0.2;
      
      font = "JetBrainsMono Nerd Font";
      font-size = 24;
    };
  };

  # Fuzzel launcher configuration
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        font = "JetBrainsMono Nerd Font:size=12";
        dpi-aware = "no";
        width = 50;
        horizontal-pad = 20;
        vertical-pad = 10;
        inner-pad = 5;
        line-height = 20;
        layer = "overlay";
      };
      colors = {
        # Catppuccin Mocha
        background = "1e1e2edd";
        text = "cdd6f4ff";
        match = "cba6f7ff";
        selection = "585b70ff";
        selection-text = "cdd6f4ff";
        selection-match = "cba6f7ff";
        border = "cba6f7ff";
      };
      border = {
        width = 2;
        radius = 8;
      };
    };
  };
}
