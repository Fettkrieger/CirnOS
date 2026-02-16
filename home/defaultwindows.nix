# Startup window placement for Niri.
#
# IMPORTANT:
# `open-on-workspace` only works with named workspaces declared under `workspaces`.
# Without named workspaces, Niri falls back to the currently focused workspace.
#
# This file intentionally does NOT force `open-maximized` for startup apps because
# it can produce confusing sizing behavior for `Super+F` toggling.
# App-specific maximize rules (like VS Code) are still safe to define here.
#
# To find an app-id: `niri msg --json event-stream` while launching the app.
#
{ ... }:

let
  startupApps = [
    {
      appId = "^discord$";
      output = "DP-4";
      workspace = "A2";
    }
    {
      appId = "^org\\.gnome\\.Nautilus$";
      output = "DP-5";
      workspace = "A1";
    }
  ];

  letters = [ "A" "B" "C" "D" "E" "F" "G" ];
  mkLane = suffix: output:
    builtins.listToAttrs
      (builtins.map
        (letter: {
          name = "${letter}${suffix}";
          value = { open-on-output = output; };
        })
        letters);
in
{
  programs.niri.settings = {
    # Named workspaces are persistent and are required for open-on-workspace rules.
    workspaces =
      # Left/vertical monitor lane.
      mkLane "1" "DP-5"
      # Middle monitor lane.
      // mkLane "2" "DP-4"
      # Right monitor lane.
      // mkLane "3" "DP-6";

    # Ordered startup sequence:
    # 1) Middle screen first (Discord)
    # 2) Firefox on A3 (maximized)
    # 3) Left-screen Nautilus flow last (2 windows, stack, maximize)
    # 4) Discord maximize happens last
    spawn-at-startup = [
      # Middle screen (A2 / DP-4)
      { command = [ "discord" ]; }

      # Right screen main Firefox (A3 / DP-6).
      # Keep Firefox out of startupApps rules so launcher launches are not pinned to A3.
      {
        command = [
          "sh"
          "-c"
          "sleep 0.9; timeout 1s niri msg action focus-workspace A3 >/dev/null 2>&1 || true; firefox"
        ];
      }

      # Left screen (A1 / DP-5): Nautilus flow last.
      {
        command = [
          "sh"
          "-c"
          "sleep 4.8; pkill -x nautilus >/dev/null 2>&1 || true; timeout 1s niri msg action focus-workspace A1 >/dev/null 2>&1 || true; sleep 0.5; nautilus --new-window"
        ];
      }
      {
        command = [
          "sh"
          "-c"
          "sleep 5.9; timeout 1s niri msg action focus-workspace A1 >/dev/null 2>&1 || true; nautilus --new-window"
        ];
      }
      {
        command = [
          "sh"
          "-c"
          "sleep 6.7; timeout 1s niri msg action focus-workspace A1 >/dev/null 2>&1 || true; timeout 1s niri msg action consume-window-into-column >/dev/null 2>&1 || true; timeout 1s niri msg action maximize-column >/dev/null 2>&1 || true; timeout 1s niri msg action focus-workspace A2 >/dev/null 2>&1 || true"
        ];
      }
      # Late safety pass for delayed Nautilus startup after logout/login.
      

      # Discord maximize last.
      {
        command = [
          "sh"
          "-c"
          "sleep 7.6; timeout 1s niri msg action focus-workspace A2 >/dev/null 2>&1 || true; timeout 1s niri msg action maximize-column >/dev/null 2>&1 || true"
        ];
      }
    ];

    # Place only startup-spawned windows in their target workspace/output.
    window-rules =
      (map
        (app: {
          matches = [{ app-id = app.appId; at-startup = true; }];
          open-on-output = app.output;
          open-on-workspace = app.workspace;
          open-focused = false;
          open-maximized = app.maximize or false;
        })
        startupApps)
      ++ [
        {
          matches = [{ app-id = "^(firefox|org\\.mozilla\\.firefox)$"; }];
          open-maximized = true;
        }
        {
          matches = [{ app-id = "^code$"; }];
          open-maximized = true;
        }
      ];
  };
}
