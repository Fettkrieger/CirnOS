# Default window placement for Niri session startup
# This file controls which apps open on login and where they appear
#
# HOW IT WORKS:
# 1. spawn-at-startup: Launches apps when Niri starts
# 2. window-rules with at-startup=true: ONLY places startup windows on specific monitors
#    (windows opened later are NOT affected by these rules)
#
# CUSTOMIZING:
# - To add an app: Add to spawn-at-startup AND create a matching window-rule with at-startup=true
# - To find an app's app-id: Run 'niri msg --json event-stream' while launching it
# - Sleep delays ensure apps launch in the correct order
#
# YOUR MONITORS:
# - DP-5: Left (vertical) - Nautilus
# - DP-4: Center (primary) - Discord
# - DP-6: Right - Firefox
#
{ config, pkgs, lib, ... }:

{
  programs.niri.settings = {

    # ============================================================
    # STARTUP APPLICATIONS
    # ============================================================
    # Apps launched when you log into Niri
    # Sleep delays control launch order (earlier = launches first)

    spawn-at-startup = [

      # --- CENTER MONITOR (DP-4) - Workspace 1 ---
      # Discord launches first (no delay)
      { command = [ "discord" ]; }

      # --- LEFT MONITOR (DP-5) - Workspace 1 ---
      # Nautilus file manager (0.6s delay)
      { command = [ "sh" "-c" "sleep 0.6 && nautilus --new-window" ]; }

      # --- RIGHT MONITOR (DP-6) - Workspace 1 ---
      { command = [ "sh" "-c" "sleep 0.5 && firefox" ]; }
    ];

    # ============================================================
    # WINDOW RULES (STARTUP ONLY)
    # ============================================================
    # These rules ONLY apply to windows spawned at startup (at-startup=true)
    # Windows opened manually later will open on whatever monitor has focus
    #
    # matches: Which windows this rule applies to (by app-id, at-startup)
    # open-on-output: Which monitor to open on (DP-4, DP-5, DP-6)
    # open-on-workspace: Which workspace number (1-9, per-monitor)
    # open-maximized: true = fullscreen width, false/omit = half-screen

    window-rules = [

      # --- Discord: Center monitor (DP-4), Workspace 1 ---
      {
        matches = [{ app-id = "^discord$"; at-startup = true; }];
        open-on-output = "DP-4";
        open-on-workspace = "1";
        open-maximized = true;
      }

      # --- Nautilus: Left monitor (DP-5), Workspace 1 ---
      {
        matches = [{ app-id = "^org\\.gnome\\.Nautilus$"; at-startup = true; }];
        open-on-output = "DP-5";
        open-on-workspace = "1";
        open-maximized = true;
      }

      # --- Firefox: Right monitor (DP-6), Workspace 1 ---
      {
        matches = [{ app-id = "^firefox$"; at-startup = true; }];
        open-on-output = "DP-6";
        open-on-workspace = "1";
        open-maximized = true;
      }
    ];
  };
}
