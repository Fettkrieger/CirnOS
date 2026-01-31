# Default window placement for Niri session startup
# This file controls which apps open on login and where they appear
#
# HOW IT WORKS:
# 1. spawn-at-startup: Launches apps when Niri starts
# 2. window-rules: Places windows on specific monitors/workspaces based on app-id
#
# CUSTOMIZING:
# - To add an app: Add to spawn-at-startup AND create a matching window-rule
# - To find an app's app-id: Run 'niri msg --json event-stream' while launching it
# - Sleep delays ensure apps launch in the correct order
#
# YOUR MONITORS:
# - DP-5: Left (vertical) - Nautilus
# - DP-4: Center (primary) - Discord, Firefox, VS Code, Ghostty
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
    # WINDOW RULES
    # ============================================================
    # Rules that place windows on specific monitors and workspaces
    #
    # matches: Which windows this rule applies to (by app-id or title)
    # open-on-output: Which monitor to open on (DP-4, DP-5, DP-6)
    # open-on-workspace: Which workspace number (1-9, per-monitor)
    # open-maximized: true = fullscreen width, false/omit = half-screen

    window-rules = [

      # ============================================================
      # CENTER MONITOR (DP-4)
      # ============================================================

      # --- Discord: Workspace 1, Fullscreen ---
      # app-id "discord" - the Discord desktop app
      {
        matches = [{ app-id = "^discord$"; }];
        open-on-output = "DP-4";       # Center monitor
        open-on-workspace = "1";          # First workspace
        open-maximized = true;          # Full width (maximized column)
      }

      

      

      

      # ============================================================
      # LEFT MONITOR (DP-5, vertical)
      # ============================================================

      # --- Nautilus: Workspace 1, Fullscreen ---
      # app-id "org.gnome.Nautilus" - GNOME Files
      {
        matches = [{ app-id = "^org\\.gnome\\.Nautilus$"; }];
        open-on-output = "DP-5";       # Left vertical monitor
        open-on-workspace = "1";          # First workspace
        open-maximized = true;          # Full width
      }

      # ============================================================
      # RIGHT MONITOR (DP-6)
      # ============================================================
      

      # --- Firefox (main): Workspace 1, Fullscreen ---
      # app-id "firefox" - standard Firefox window
      {
        matches = [{ app-id = "^firefox$"; }];
        open-on-output = "DP-6";       # Center monitor
        open-on-workspace = "1";          # First workspace
        open-maximized = true;          # Full width
      }

      
    ];
  };
}
