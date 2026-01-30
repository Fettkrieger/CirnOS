# Per-workspace wallpaper daemon for Niri
# Based on 0xwal/niri-scripts wallpaper-per-workspace logic
# https://github.com/0xwal/niri-scripts
{ config, pkgs, lib, ... }:

{
  # Dependencies
  home.packages = with pkgs; [ jq ];

  # Install the wallpaper daemon script
  home.file.".local/bin/niri-wallpaper-daemon" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # niri-wallpaper-daemon - Per-workspace wallpapers for Niri
      # Based on 0xwal/niri-scripts logic
      #
      # Wallpaper structure:
      #   ~/CirnOS/wallpapers/1        - Workspace 1 (no extension!)
      #   ~/CirnOS/wallpapers/2        - Workspace 2
      #   ~/CirnOS/wallpapers/FALLBACK - Default fallback

      WALLPAPER_DIR="''${1:-$HOME/CirnOS/wallpapers}"
      CURRENT_WS=""

      change_wallpaper() {
          local ws="$1"
          local output="$2"
          local ws_wallpaper="$WALLPAPER_DIR/$ws"
          local fallback="$WALLPAPER_DIR/FALLBACK"

          local target=""
          if [[ -f "$ws_wallpaper" ]]; then
              target="$ws_wallpaper"
          elif [[ -f "$fallback" ]]; then
              target="$fallback"
          else
              return
          fi

          swww img "$target" -o "$output" --transition-type fade --transition-duration 0.4
      }

      get_workspace_info() {
          local id="$1"
          niri msg --json workspaces | jq -r --argjson id "$id" '.[] | select(.id == $id) | "\(.idx) \(.output)"'
      }

      # Wait for swww daemon
      sleep 2

      # Listen for WorkspaceActivated events
      niri msg --json event-stream | while read -r event; do
          # Check if this is a WorkspaceActivated event
          ws_id=$(echo "$event" | jq -r '.WorkspaceActivated.id // empty')

          if [[ -n "$ws_id" ]]; then
              # Get workspace info (idx and output)
              info=$(get_workspace_info "$ws_id")
              if [[ -n "$info" ]]; then
                  ws_idx=$(echo "$info" | cut -d' ' -f1)
                  output=$(echo "$info" | cut -d' ' -f2)

                  # Only change if workspace changed
                  if [[ "$ws_idx" != "$CURRENT_WS" ]]; then
                      CURRENT_WS="$ws_idx"
                      change_wallpaper "$ws_idx" "$output"
                  fi
              fi
          fi
      done
    '';
  };

  # Systemd user service
  systemd.user.services.niri-wallpaper = {
    Unit = {
      Description = "Niri per-workspace wallpaper daemon";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "%h/.local/bin/niri-wallpaper-daemon %h/CirnOS/wallpapers";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
