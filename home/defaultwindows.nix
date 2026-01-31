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

      # Firefox launches second (0.5s delay to ensure Discord opens first)
      { command = [ "sh" "-c" "sleep 0.5 && firefox" ]; }

      # --- CENTER MONITOR (DP-4) - Workspace 2 ---
      # VS Code (1s delay)
      { command = [ "sh" "-c" "sleep 1 && code" ]; }

      # Ghostty terminal (1.5s delay to open after VS Code)
      { command = [ "sh" "-c" "sleep 1.5 && ghostty" ]; }

      # --- LEFT MONITOR (DP-5) - Workspace 1 ---
      # Nautilus file manager (2s delay)
      { command = [ "sh" "-c" "sleep 2 && nautilus --new-window" ]; }

      # --- RIGHT MONITOR (DP-6) - Workspace 1 ---
      # Second Firefox with custom class so window-rules can distinguish it
      # --class sets the app-id to "firefox-right" instead of "firefox"
      { command = [ "sh" "-c" "sleep 2.5 && firefox --class firefox-right" ]; }
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
        open-on-workspace = 1;          # First workspace
        open-maximized = true;          # Full width (maximized column)
      }

      # --- Firefox (main): Workspace 1, Fullscreen ---
      # app-id "firefox" - standard Firefox window
      {
        matches = [{ app-id = "^firefox$"; }];
        open-on-output = "DP-4";       # Center monitor
        open-on-workspace = 1;          # First workspace
        open-maximized = true;          # Full width
      }

      # --- VS Code: Workspace 2, Fullscreen ---
      # app-id "code" - Visual Studio Code
      {
        matches = [{ app-id = "^code$"; }];
        open-on-output = "DP-4";       # Center monitor
        open-on-workspace = 2;          # Second workspace
        open-maximized = true;          # Full width
      }

      # --- Ghostty: Workspace 2, Half-screen ---
      # app-id "com.mitchellh.ghostty" - Ghostty terminal
      {
        matches = [{ app-id = "^com\\.mitchellh\\.ghostty$"; }];
        open-on-output = "DP-4";       # Center monitor
        open-on-workspace = 2;          # Second workspace
        # No open-maximized = uses default half-screen width
      }

      # ============================================================
      # LEFT MONITOR (DP-5, vertical)
      # ============================================================

      # --- Nautilus: Workspace 1, Fullscreen ---
      # app-id "org.gnome.Nautilus" - GNOME Files
      {
        matches = [{ app-id = "^org\\.gnome\\.Nautilus$"; }];
        open-on-output = "DP-5";       # Left vertical monitor
        open-on-workspace = 1;          # First workspace
        open-maximized = true;          # Full width
      }

      # ============================================================
      # RIGHT MONITOR (DP-6)
      # ============================================================

      # --- Firefox (right): Workspace 1, Fullscreen ---
      # app-id "firefox-right" - Firefox launched with --class firefox-right
      {
        matches = [{ app-id = "^firefox-right$"; }];
        open-on-output = "DP-6";       # Right monitor
        open-on-workspace = 1;          # First workspace
        open-maximized = true;          # Full width
      }
    ];
  };
}
