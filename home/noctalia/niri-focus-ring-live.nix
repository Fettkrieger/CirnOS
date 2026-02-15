{ config, lib, pkgs, ... }:
let
  niriConfigFile = "${config.xdg.configHome}/niri/config.kdl";
  colorsFile = "${config.xdg.configHome}/noctalia/colors.json";
  niriBaseConfig =
    if config.programs.niri.finalConfig == null then
      ""
    else
      config.programs.niri.finalConfig;

  syncFocusRing = pkgs.writeShellScript "noctalia-sync-niri-focus-ring" ''
    set -eu

    config_file="${niriConfigFile}"
    colors_file="${colorsFile}"
    temp_file="$(mktemp)"

    mkdir -p "$(dirname "$config_file")"
    [ -f "$config_file" ] || touch "$config_file"

    primary="#fff59b"
    outline="#21215f"

    if [ -r "$colors_file" ]; then
      read_color() {
        local key="$1"
        ${pkgs.jq}/bin/jq -r --arg key "$key" '.[$key] // empty' "$colors_file" 2>/dev/null || true
      }

      maybe_primary="$(read_color mPrimary)"
      maybe_outline="$(read_color mOutline)"

      if [ -n "$maybe_primary" ]; then
        primary="$maybe_primary"
      fi
      if [ -n "$maybe_outline" ]; then
        outline="$maybe_outline"
      fi
    fi

    case "$primary" in
      \#*) ;;
      *) primary="#$primary" ;;
    esac

    case "$outline" in
      \#*) ;;
      *) outline="#$outline" ;;
    esac

    ${pkgs.gawk}/bin/awk -v active="$primary" -v inactive="$outline" '
      function indent_of(s) {
        match(s, /^[ \t]*/)
        return substr(s, RSTART, RLENGTH)
      }

      {
        line = $0
        trimmed = line
        sub(/^[ \t]+/, "", trimmed)

        if (!in_focus && trimmed ~ /^focus-ring[ \t]*\{/) {
          in_focus = 1
          focus_indent = indent_of(line)
          has_active = 0
          has_inactive = 0
          print line
          next
        }

        if (in_focus) {
          if (trimmed ~ /^active-color[ \t]+/) {
            print focus_indent "    active-color \"" active "\""
            has_active = 1
            next
          }

          if (trimmed ~ /^inactive-color[ \t]+/) {
            print focus_indent "    inactive-color \"" inactive "\""
            has_inactive = 1
            next
          }

          if (trimmed ~ /^\}/) {
            if (!has_active) {
              print focus_indent "    active-color \"" active "\""
            }
            if (!has_inactive) {
              print focus_indent "    inactive-color \"" inactive "\""
            }
            print line
            in_focus = 0
            next
          }
        }

        print line
      }
    ' "$config_file" > "$temp_file"

    mv "$temp_file" "$config_file"
  '';

  refreshFocusRing = pkgs.writeShellScript "noctalia-refresh-niri-focus-ring" ''
    set -eu

    ${syncFocusRing}

    runtime_dir="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
    socket="$(${pkgs.findutils}/bin/find "$runtime_dir" -maxdepth 1 -type s -name 'niri*.sock' | ${pkgs.coreutils}/bin/head -n 1 || true)"

    if [ -n "$socket" ]; then
      NIRI_SOCKET="$socket" ${lib.getExe pkgs.niri} msg action load-config-file >/dev/null 2>&1 || true
    fi
  '';

  watchFocusRing = pkgs.writeShellScript "noctalia-watch-niri-focus-ring" ''
    set -eu

    colors_file="${colorsFile}"
    watch_dir="$(dirname "$colors_file")"
    watch_name="$(basename "$colors_file")"

    mkdir -p "$watch_dir"
    [ -f "$colors_file" ] || touch "$colors_file"

    ${refreshFocusRing}

    ${pkgs.inotify-tools}/bin/inotifywait -m -e close_write,move,create --format '%f' "$watch_dir" \
      | while read -r changed; do
          if [ "$changed" = "$watch_name" ]; then
            ${refreshFocusRing}
          fi
        done
  '';
in
{
  # Keep niri config writable so only focus-ring colors can be patched live.
  xdg.configFile."niri-config".enable = lib.mkForce false;

  # Recreate niri config from Home Manager on every switch.
  home.activation.noctaliaNiriConfigBootstrap = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$(dirname "${niriConfigFile}")"
    printf '%s\n' ${lib.escapeShellArg niriBaseConfig} > "${niriConfigFile}"
    chmod u+rw "${niriConfigFile}"
  '';

  # Apply current Noctalia colors immediately after config is written.
  home.activation.noctaliaNiriFocusRingInit = lib.hm.dag.entryAfter [ "noctaliaNiriConfigBootstrap" ] ''
    ${syncFocusRing}
  '';

  systemd.user.services.noctalia-niri-focus-ring-live = {
    Unit = {
      Description = "Refresh Niri focus ring colors from Noctalia";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${watchFocusRing}";
      Restart = "always";
      RestartSec = 1;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
