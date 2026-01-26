# Niri compositor configuration
{ config, pkgs, lib, inputs, ... }:

{
  # Niri packages and tools
  home.packages = with pkgs; [
    # === Core Niri Tools ===
    rofi                      # App launcher (wayland support built-in)
    mako                      # Notifications
    swaylock-effects          # Screen locker with effects
    swayidle                  # Idle management (screen locking, power saving)
                      # Wallpaper setter for Wayland                            
    
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
    playerctl                 # Media player control<
    pamixer                   # PulseAudio mixer CLI
    networkmanagerapplet      # Network tray icon
    
    # === XWayland ===
    xwayland-satellite        # XWayland support for Niri
    
    # === Authentication ===
    polkit_gnome              # Polkit authentication agent
  ];

  # Use swaybg via a startup command to set the wallpaper on Wayland

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
        # Set wallpaper (change the path to your image)
        { command = [ "sh" "-c" "sleep 1 && swww img ~/Pictures/wallpapers/nix.svg --transition-type fade --transition-duration 1" ]; }
        { command = [ "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1" ]; }
        { command = [ "mako" ]; }
        { command = [ "nm-applet" "--indicator" ]; }
        { command = [ "wl-paste" "--watch" "cliphist" "store" ]; }
        # waybar is started via systemd user service (programs.waybar.systemd.enable)
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
            refresh = 155.000;
          };
          scale = 1.0;
          transform = {
            rotation = 90;  # Rotated left (vertical)
          };
          position = {
            x = 0;
            y = 0;
          };
        };
        "DP-4" = {
          mode = {
            width = 2560;
            height = 1440;
            refresh = 179.952;
          };
          scale = 1.0;
          position = {
            x = 1440;  # After vertical monitor (1440 wide when rotated)
            y = 790;   # Centered vertically (2560-1440)/2
          };
        };
        "DP-6" = {
          mode = {
            width = 2560;
            height = 1440;
            refresh = 155.000;
          };
          scale = 1.0;
          position = {
            x = 4000;  # After DP-4 (1440 + 2560)
            y = 790;   # Aligned with center monitor
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
        gaps = 2;
        
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
          active.color = "#89b4fa";   # Catppuccin Blue
          inactive.color = "#45475a"; # Catppuccin Surface1
        };
        
        # Window border
        border = {
          enable = false;
        };
        
        # Struts (reserved space for bars)
        struts = {
          top = 0;  # Space for waybar
        };
      };

      # === Cursor ===
      cursor = {
        theme = "catppuccin-mocha-blue-cursors";
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
      binds = {
        # === Window Management ===
        "Super+Q".action.close-window = [];
        "Super+F".action.maximize-column = [];
        
        # === Focus (Super+Ctrl+Arrows) ===
        "Super+Ctrl+Left".action.focus-column-left = [];
        "Super+Ctrl+Right".action.focus-column-right = [];
        "Super+Ctrl+Up".action.focus-window-up = [];
        "Super+Ctrl+Down".action.focus-window-down = [];
        
        # === Focus Window or Workspace (Super+Up/Down) ===
        "Super+Up".action.focus-window-or-workspace-up = [];
        "Super+Down".action.focus-window-or-workspace-down = [];
        
        # === Move Windows (Super+Shift+Arrows) ===
        "Super+Shift+Left".action.move-column-left = [];
        "Super+Shift+Right".action.move-column-right = [];
        "Super+Shift+Up".action.move-window-to-workspace-up = [];
        "Super+Shift+Down".action.move-window-to-workspace-down = [];
        
        # === Overview ===
        "Super+F18".action.toggle-overview = [];
        
        # === Scroll View (Super+Arrows) ===
        "Super+Left".action.focus-column-left = [];
        "Super+Right".action.focus-column-right = [];
        
        # === Column Management ===
        "Super+BracketLeft".action.consume-window-into-column = [];
        "Super+BracketRight".action.expel-window-from-column = [];
        
        # === Resize ===
        "Super+R".action.switch-preset-column-width = [];
        "Super+Minus".action.set-column-width = "-10%";
        "Super+Equal".action.set-column-width = "+10%";
        
        # === Workspaces (1-9) ===
        "Super+1".action.focus-workspace = 1;
        "Super+2".action.focus-workspace = 2;
        "Super+3".action.focus-workspace = 3;
        "Super+4".action.focus-workspace = 4;
        "Super+5".action.focus-workspace = 5;
        "Super+6".action.focus-workspace = 6;
        "Super+7".action.focus-workspace = 7;
        "Super+8".action.focus-workspace = 8;
        "Super+9".action.focus-workspace = 9;
        
        # === Move to Workspace ===
        "Super+Shift+1".action.move-column-to-workspace = 1;
        "Super+Shift+2".action.move-column-to-workspace = 2;
        "Super+Shift+3".action.move-column-to-workspace = 3;
        "Super+Shift+4".action.move-column-to-workspace = 4;
        "Super+Shift+5".action.move-column-to-workspace = 5;
        "Super+Shift+6".action.move-column-to-workspace = 6;
        "Super+Shift+7".action.move-column-to-workspace = 7;
        "Super+Shift+8".action.move-column-to-workspace = 8;
        "Super+Shift+9".action.move-column-to-workspace = 9;
        
        # === Monitor Focus ===
        "Super+Comma".action.focus-monitor-left = [];
        "Super+Period".action.focus-monitor-right = [];
        
        # === Move to Monitor ===
        "Super+Shift+Comma".action.move-column-to-monitor-left = [];
        "Super+Shift+Period".action.move-column-to-monitor-right = [];
        
        # === Scroll/Navigation ===
        "Super+Home".action.focus-column-first = [];
        "Super+End".action.focus-column-last = [];
        "Super+C".action.center-column = [];
        
        # === Launchers ===
        "Super+Return".action.spawn = ["ghostty"];
        "Super+D".action.spawn = ["rofi" "-show" "drun"];
        
        # === Screenshots ===
        "Super+Shift+S".action.screenshot = [];
        "Print".action.screenshot-screen = [];
        "Super+Print".action.screenshot-window = [];
        
        # === System ===
        "Super+Escape".action.spawn = ["swaylock"];
        "Super+Shift+E".action.quit = [];
        "Super+Shift+R".action.spawn = ["sh" "-c" "niri msg action reload-config"];
        
        # === Media Keys ===
        "XF86AudioRaiseVolume".action.spawn = ["pamixer" "-i" "5"];
        "XF86AudioLowerVolume".action.spawn = ["pamixer" "-d" "5"];
        "XF86AudioMute".action.spawn = ["pamixer" "-t"];
        "XF86AudioPlay".action.spawn = ["playerctl" "play-pause"];
        "XF86AudioNext".action.spawn = ["playerctl" "next"];
        "XF86AudioPrev".action.spawn = ["playerctl" "previous"];
        
        # === Brightness ===
        "XF86MonBrightnessUp".action.spawn = ["brightnessctl" "set" "+5%"];
        "XF86MonBrightnessDown".action.spawn = ["brightnessctl" "set" "5%-"];
        
        # === Clipboard History ===
        "Super+V".action.spawn = ["sh" "-c" "cliphist list | rofi -dmenu | cliphist decode | wl-copy"];
      };
    };
  };

  # Mako notification daemon configuration
  services.mako = {
    enable = true;
    settings = {
      default-timeout = 5000;
      border-radius = 8;
      border-size = 2;
      padding = "12";
      # Catppuccin Mocha colors (blue accent)
      background-color = "#1e1e2e";
      text-color = "#cdd6f4";
      border-color = "#89b4fa";
      progress-color = "#89b4fa";
    };
  };

  # Swaylock - enable and use swaylock-effects, let Catppuccin handle colors
  programs.swaylock = {
    enable = true;
    package = pkgs.swaylock-effects;
    settings = {
      # Effects only - Catppuccin handles colors
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

  # Rofi launcher configuration
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    font = "JetBrainsMono Nerd Font 12";
    terminal = "ghostty";
    extraConfig = {
      modi = "drun,run,window";
      show-icons = true;
      icon-theme = "Papirus-Dark";
      display-drun = "Apps";
      display-run = "Run";
      display-window = "Windows";
      drun-display-format = "{name}";
    };
    theme = let
      inherit (config.lib.formats.rasi) mkLiteral;
    in {
      "*" = {
        bg = mkLiteral "#1e1e2e";
        fg = mkLiteral "#cdd6f4";
        accent = mkLiteral "#89b4fa";
        surface = mkLiteral "#585b70";
        background-color = mkLiteral "@bg";
        text-color = mkLiteral "@fg";
      };
      window = {
        width = mkLiteral "600px";
        border = mkLiteral "2px";
        border-color = mkLiteral "@accent";
        border-radius = mkLiteral "8px";
        padding = mkLiteral "20px";
      };
      inputbar = {
        children = mkLiteral "[prompt,entry]";
        spacing = mkLiteral "10px";
        padding = mkLiteral "10px";
        background-color = mkLiteral "@surface";
        border-radius = mkLiteral "8px";
      };
      prompt = {
        text-color = mkLiteral "@accent";
      };
      entry = {
        placeholder = "Search...";
        placeholder-color = mkLiteral "@surface";
      };
      listview = {
        lines = 8;
        columns = 1;
        fixed-height = false;
        spacing = mkLiteral "5px";
        padding = mkLiteral "10px 0 0 0";
      };
      element = {
        padding = mkLiteral "10px";
        border-radius = mkLiteral "8px";
        spacing = mkLiteral "10px";
      };
      "element selected" = {
        background-color = mkLiteral "@surface";
      };
      element-icon = {
        size = mkLiteral "24px";
      };
      element-text = {
        highlight = mkLiteral "bold #89b4fa";
      };
    };
  };

  # Ghostty configuration
  programs.ghostty = {
    enable = true;
    settings = {
      background-opacity = 0.8;  # Background transparency (0.0 = fully transparent, 1.0 = opaque)
      # Optional: blur behind the terminal (if compositor supports it)
      # background-blur-radius = 20;
    };
  };
}
