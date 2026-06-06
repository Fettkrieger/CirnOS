# Niri compositor configuration
{ lib, pkgs, hostname, ... }:

let
  isLenuwu = hostname == "lenuwu-nix";

  waylandEnvironment = {
    "NIXOS_OZONE_WL" = "1";
    "ELECTRON_OZONE_PLATFORM_HINT" = "wayland";
    "MOZ_ENABLE_WAYLAND" = "1";
    "NOCTALIA_PAM_SERVICE" = "noctalia-lock";
    "QT_QPA_PLATFORM" = "wayland";
    "QT_QPA_PLATFORMTHEME" = "gtk3";
    "SDL_VIDEODRIVER" = "wayland";
    "GDK_BACKEND" = "wayland";
  } // lib.optionalAttrs (!isLenuwu) {
    "LIBVA_DRIVER_NAME" = "nvidia";
    "GBM_BACKEND" = "nvidia-drm";
    "__GLX_VENDOR_LIBRARY_NAME" = "nvidia";
    "WLR_NO_HARDWARE_CURSORS" = "1";
  };

  laptopOutputs = {
    "eDP-1" = {
      mode = {
        width = 1920;
        height = 1200;
        refresh = 60.010;
      };
      scale = 1.0;
      position = {
        x = 0;
        y = 0;
      };
      focus-at-startup = true;
    };
  };

  dockOutputs = {
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

  noctaliaLockOnStartup = pkgs.writeShellScriptBin "noctalia-lock-on-startup" ''
    set -eu

    attempts=120
    attempt=1

    while [ "$attempt" -le "$attempts" ]; do
      if noctalia-shell ipc call lockScreen lock >/dev/null 2>&1; then
        exit 0
      fi

      attempt=$((attempt + 1))
      sleep 0.1
    done

    echo "noctalia-lock-on-startup: Noctalia lock IPC did not become available; ending niri session" >&2

    niri msg action quit --skip-confirmation >/dev/null 2>&1 || true
    systemctl --user stop niri.service >/dev/null 2>&1 || true

    exit 1
  '';

  internalPointerToggle = pkgs.writeShellScriptBin "niri-toggle-internal-pointer" ''
    set -eu

    config_home="''${XDG_CONFIG_HOME:-''${HOME:-/home/krieger}/.config}"
    config_file="$config_home/niri/config.kdl"

    notify() {
      ${pkgs.libnotify}/bin/notify-send "Niri" "$1" >/dev/null 2>&1 || true
    }

    if [ ! -f "$config_file" ]; then
      notify "Internal pointer toggle failed: Niri config not found"
      exit 1
    fi

    action="$(
      ${pkgs.gawk}/bin/awk '
        function trim(s) {
          sub(/^[ \t]+/, "", s)
          sub(/[ \t]+$/, "", s)
          return s
        }

        function brace_delta(s,    open_count, close_count, i, ch) {
          open_count = 0
          close_count = 0

          for (i = 1; i <= length(s); i++) {
            ch = substr(s, i, 1)

            if (ch == "{") {
              open_count++
            } else if (ch == "}") {
              close_count++
            }
          }

          return open_count - close_count
        }

        BEGIN {
          depth = 0
        }

        {
          line = $0
          stripped = trim(line)
          previous_depth = depth

          if (!in_input && stripped ~ /^input[ \t]*\{/) {
            in_input = 1
            input_depth = previous_depth + brace_delta(line)
          } else if (in_input && !in_target && previous_depth == input_depth && stripped ~ /^(touchpad|trackpoint)[ \t]*\{/) {
            target = stripped
            sub(/[ \t]*\{.*/, "", target)
            seen[target] = 1
            in_target = 1
            target_depth = previous_depth + brace_delta(line)
          } else if (in_target && previous_depth == target_depth && stripped == "off") {
            has_off[target] = 1
          }

          depth += brace_delta(line)

          if (in_target && depth < target_depth) {
            in_target = 0
            target = ""
          }

          if (in_input && depth < input_depth) {
            in_input = 0
          }
        }

        END {
          if (seen["touchpad"] && seen["trackpoint"] && has_off["touchpad"] && has_off["trackpoint"]) {
            print "enable"
          } else {
            print "disable"
          }
        }
      ' "$config_file"
    )"

    tmp="$(${pkgs.coreutils}/bin/mktemp)"
    trap '${pkgs.coreutils}/bin/rm -f "$tmp"' EXIT

    ${pkgs.gawk}/bin/awk -v action="$action" '
      function trim(s) {
        sub(/^[ \t]+/, "", s)
        sub(/[ \t]+$/, "", s)
        return s
      }

      function indent_of(s) {
        match(s, /^[ \t]*/)
        return substr(s, RSTART, RLENGTH)
      }

      function brace_delta(s,    open_count, close_count, i, ch) {
        open_count = 0
        close_count = 0

        for (i = 1; i <= length(s); i++) {
          ch = substr(s, i, 1)

          if (ch == "{") {
            open_count++
          } else if (ch == "}") {
            close_count++
          }
        }

        return open_count - close_count
      }

      function print_missing_target(name) {
        print input_indent "    " name " {"
        print input_indent "        off"
        print input_indent "    }"
      }

      BEGIN {
        depth = 0
      }

      {
        line = $0
        stripped = trim(line)
        previous_depth = depth

        if (!in_input && stripped ~ /^input[ \t]*\{/) {
          in_input = 1
          input_indent = indent_of(line)
          input_depth = previous_depth + brace_delta(line)
          print line
          depth += brace_delta(line)
          next
        }

        if (in_input && !in_target && previous_depth == input_depth && stripped ~ /^(touchpad|trackpoint)[ \t]*\{/) {
          target = stripped
          sub(/[ \t]*\{.*/, "", target)
          seen[target] = 1
          target_indent = indent_of(line)
          target_has_off = 0
          in_target = 1
          target_depth = previous_depth + brace_delta(line)
          print line
          depth += brace_delta(line)
          next
        }

        if (in_target && previous_depth == target_depth && stripped == "off") {
          target_has_off = 1

          if (action == "enable") {
            depth += brace_delta(line)
            next
          }
        }

        if (in_target && previous_depth == target_depth && stripped ~ /^\}/) {
          if (action == "disable" && !target_has_off) {
            print target_indent "    off"
          }

          print line
          depth += brace_delta(line)

          if (depth < target_depth) {
            in_target = 0
            target = ""
          }

          next
        }

        if (in_input && !in_target && previous_depth == input_depth && stripped ~ /^\}/) {
          if (action == "disable") {
            if (!seen["touchpad"]) {
              print_missing_target("touchpad")
            }

            if (!seen["trackpoint"]) {
              print_missing_target("trackpoint")
            }
          }

          print line
          depth += brace_delta(line)

          if (depth < input_depth) {
            in_input = 0
          }

          next
        }

        print line
        depth += brace_delta(line)

        if (in_target && depth < target_depth) {
          in_target = 0
          target = ""
        }

        if (in_input && depth < input_depth) {
          in_input = 0
        }
      }
    ' "$config_file" > "$tmp"

    if ! ${lib.getExe pkgs.niri} validate -c "$tmp" >/dev/null 2>&1; then
      notify "Internal pointer toggle failed: generated config is invalid"
      exit 1
    fi

    ${pkgs.coreutils}/bin/mv "$tmp" "$config_file"
    trap - EXIT

    runtime_dir="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
    socket="$(${pkgs.findutils}/bin/find "$runtime_dir" -maxdepth 1 -type s -name 'niri*.sock' | ${pkgs.coreutils}/bin/head -n 1 || true)"

    if [ -n "$socket" ]; then
      NIRI_SOCKET="$socket" ${lib.getExe pkgs.niri} msg action load-config-file >/dev/null 2>&1 || true
    fi

    if [ "$action" = "disable" ]; then
      notify "Internal pointers disabled"
    else
      notify "Internal pointers enabled"
    fi
  '';
in

{
  # Niri packages and tools
  home.packages = with pkgs; [
    # === Clipboard (Noctalia launcher) ===
    wtype                     # Types selected clipboard entries into the active window
    cliphist                  # Clipboard history backend used by Noctalia
    # === Screenshots ===
    grim                      # Screenshot tool
    slurp                     # Area selector
    swappy                    # Screenshot editor      

    # === XWayland ===
    xwayland-satellite        # XWayland support for Niri

    # === Internal pointer toggle ===
    internalPointerToggle     # Toggle touchpad + TrackPoint buttons through Niri
  ];
  # Niri compositor configuration using niri-flake settings
  programs.niri = {
    settings = {
      
      
      # === Environment Variables ===
      environment = waylandEnvironment;

      # === Startup Applications ===
      spawn-at-startup = [
        { command = [ "noctalia-shell" ]; }
        { command = [ "${noctaliaLockOnStartup}/bin/noctalia-lock-on-startup" ]; }
        { command = [ "xwayland-satellite" ]; }
        {
          command = [
            "ghostty"
            "--initial-window=false"
            "--quit-after-last-window-closed=false"
          ];
        }
      ];

      # === Monitor Configuration ===
      outputs = if isLenuwu then laptopOutputs else dockOutputs;

      # === Input Configuration ===
      input = {
        keyboard = {
          xkb = {
            layout = if hostname == "lenuwu-nix" then "de" else "ch";
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
      } // lib.optionalAttrs isLenuwu {
        # Trackpoint is separate from `mouse` in Niri; defaults use accel-speed 0.2.
        trackpoint = {
          accel-profile = "flat";
          accel-speed = -0.35;
        };
      };

      # === Gestures ===
      # Prevent opening overview by moving cursor to top-left screen corner.
      gestures.hot-corners.enable = false;

      # === Hotkey Overlay ===
      # Don't show the built-in important hotkeys popup at session startup.
      hotkey-overlay.skip-at-startup = true;

      # === Layout Configuration ===
      layout = {
        gaps = 3;

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
      ];

      # === Keybindings ===
      binds = {
        # === Window Management ===
        "Super+Q".action.close-window = [];
        "Super+F".action.maximize-column = [];
        "Super+T".action.toggle-window-floating = [];  # Toggle floating mode
        "Super+Ctrl+T".action.spawn = ["${internalPointerToggle}/bin/niri-toggle-internal-pointer"];
        
        
        
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
        "Super+Return".action.spawn = ["ghostty" "+new-window"];
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
