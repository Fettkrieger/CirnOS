# Niri compositor configuration
{ pkgs, ... }:

{
  # Niri packages and tools
  home.packages = with pkgs; [
    # === Core Niri Tools ===
    swayidle                  # Idle management (screen locking, power saving)
    # === Clipboard (Noctalia launcher) ===
    wtype                     # Types selected clipboard entries into the active window
    cliphist                  # Clipboard history backend used by Noctalia
    # === Screenshots ===
    grim                      # Screenshot tool
    slurp                     # Area selector
    swappy                    # Screenshot editor      

    # === XWayland ===
    xwayland-satellite        # XWayland support for Niri

    # === Authentication ===
    lxqt.lxqt-policykit       # Polkit authentication agent
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
      };

      # === Startup Applications ===
      spawn-at-startup = [
        { command = [ "xwayland-satellite" ]; }
        { command = [ "${pkgs.lxqt.lxqt-policykit}/bin/lxqt-policykit-agent" ]; }
        { command = [ "swayidle" "-w"
            "timeout" "300" "noctalia-shell ipc call lockScreen lock"
            "timeout" "600" "niri msg action power-off-monitors"
            "before-sleep" "noctalia-shell ipc call lockScreen lock"
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
          variable-refresh-rate = true;
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
            y = 810;   # Centered vertically (2560-1440)/2
          };
          variable-refresh-rate = true;
          focus-at-startup = true;  # Start with cursor/focus on this monitor
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
            y = 810;   # Aligned with center monitor
          };
          variable-refresh-rate = true;
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
          enable = false;
          max-scroll-amount = "0%";
        };
      };

      # === Gestures ===
      # Prevent opening overview by moving cursor to top-left screen corner.
      gestures.hot-corners.enable = false;

      # === Layout Configuration ===
      layout = {
        gaps = 3;  # Gap between windows and screen edges
        
        
        
        center-focused-column = "never";
        
        # Preset column widths (cycle with Super+R)
        preset-column-widths = [
          { proportion = 1.0 / 3.0; }
          { proportion = 1.0 / 2.0; }
          { proportion = 2.0 / 3.0; }
        ];
        
        # Default window width
        default-column-width = { proportion = 1.0 / 2.0; };
        
        # Focus ring (live-updated at runtime from Noctalia colors.json)
        focus-ring = {
          enable = true;
          width = 3;
          active.color = "#fff59b";
          inactive.color = "#21215F";
        };
        
        # Window border
        border = {
          enable = false;
        };


  
        
        
        
      };
      

      # === Cursor ===
      cursor = {
        theme = "Adwaita";
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
          matches = [
            { app-id = "^lxqt-policykit-agent$"; }
            { app-id = "^org\\.lxqt\\.lxqt-policykit-agent$"; }
          ];
          open-floating = true;
        }
      ];

      # === Keybindings ===
      binds = {
        # === Window Management ===
        "Super+Q".action.close-window = [];
        "Super+F".action.maximize-column = [];
        "Super+T".action.toggle-window-floating = [];  # Toggle floating mode
        
        
        
        # === Focus Window or Workspace (Super+Up/Down) ===
        "Super+Up".action.focus-window-or-workspace-up = [];
        "Super+Down".action.focus-window-or-workspace-down = [];
        
        # === Move Windows (Super+Shift+Arrows) ===
        "Super+Shift+Left".action.move-column-left = [];
        "Super+Shift+Right".action.move-column-right = [];
        "Super+Shift+Up".action.move-window-to-workspace-up = [];
        "Super+Shift+Down".action.move-window-to-workspace-down = [];
        
        # === Overview ===
        "Super+X".action.toggle-overview = [];
        
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
        "Super+Ctrl+Left".action.focus-monitor-left = [];
        "Super+Ctrl+Right".action.focus-monitor-right = [];
        
        # === Move to Monitor ===
        "Super+Shift+Ctrl+Left".action.move-column-to-monitor-left = [];
        "Super+Shift+Ctrl+Right".action.move-column-to-monitor-right = [];
        
        # === Scroll/Navigation ===
        "Super+Home".action.focus-column-first = [];
        "Super+End".action.focus-column-last = [];
        "Super+C".action.center-column = [];
        
        # === Launchers ===
        "Super+Return".action.spawn = ["ghostty"];
        "Super+D".action.spawn = ["noctalia-shell" "ipc" "call" "launcher" "toggle"];
        "Super+B".action.spawn = ["noctalia-shell" "ipc" "call" "controlCenter" "toggle"];
        "Super+N".action.spawn = ["noctalia-shell" "ipc" "call" "notifications" "toggleHistory"];
        
        # === Screenshots ===
        "Super+Shift+S".action.spawn = ["sh" "-c" "grim -g \"$(slurp)\" - | wl-copy --type image/png"];
        "Super+Ctrl+S".action.spawn = ["sh" "-c" "grim -g \"$(slurp)\" - | swappy -f -"];
        "Print".action.screenshot-screen = [];
        "Super+Print".action.screenshot-window = [];
        
        # === System ===
        "Super+Escape".action.spawn = ["noctalia-shell" "ipc" "call" "lockScreen" "lock"];
        "Super+Shift+E".action.quit = [];
        "Super+Shift+R".action.spawn = ["sh" "-c" "niri msg action reload-config"];
        
        # === Media Keys ===
        "XF86AudioRaiseVolume".action.spawn = ["noctalia-shell" "ipc" "call" "volume" "increase"];
        "XF86AudioLowerVolume".action.spawn = ["noctalia-shell" "ipc" "call" "volume" "decrease"];
        "XF86AudioMute".action.spawn = ["noctalia-shell" "ipc" "call" "volume" "muteOutput"];
        "XF86AudioPlay".action.spawn = ["noctalia-shell" "ipc" "call" "media" "playPause"];
        "XF86AudioNext".action.spawn = ["noctalia-shell" "ipc" "call" "media" "next"];
        "XF86AudioPrev".action.spawn = ["noctalia-shell" "ipc" "call" "media" "previous"];
        
        # === Brightness ===
        "XF86MonBrightnessUp".action.spawn = ["noctalia-shell" "ipc" "call" "brightness" "increase"];
        "XF86MonBrightnessDown".action.spawn = ["noctalia-shell" "ipc" "call" "brightness" "decrease"];
        
        # === Noctalia Clipboard ===
        "Super+V".action.spawn = ["noctalia-shell" "ipc" "call" "launcher" "clipboard"];
        
      };
    };
  };

}
