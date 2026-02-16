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
    secondary="$primary"
    outline="#21215f"
    cursor_theme="catppuccin-mocha-blue-cursors"

    if [ -r "$colors_file" ]; then
      read_color() {
        local key="$1"
        ${pkgs.jq}/bin/jq -r --arg key "$key" '.[$key] // empty' "$colors_file" 2>/dev/null || true
      }

      maybe_primary="$(read_color mPrimary)"
      maybe_secondary="$(read_color mSecondary)"
      maybe_outline="$(read_color mOutline)"

      if [ -n "$maybe_primary" ]; then
        primary="$maybe_primary"
      fi
      if [ -n "$maybe_secondary" ]; then
        secondary="$maybe_secondary"
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

    case "$secondary" in
      \#*) ;;
      *) secondary="#$secondary" ;;
    esac

    normalize_hex() {
      local value
      value="$(printf '%s' "$1" | ${pkgs.coreutils}/bin/tr '[:upper:]' '[:lower:]')"
      value="''${value#\#}"

      if printf '%s\n' "$value" | ${pkgs.gnugrep}/bin/grep -Eq '^[0-9a-f]{6}$'; then
        printf '%s' "$value"
      else
        printf '89b4fa'
      fi
    }

    sq_distance() {
      local c1="$1"
      local c2="$2"
      local r1 g1 b1 r2 g2 b2 dr dg db

      r1=$((16#''${c1:0:2}))
      g1=$((16#''${c1:2:2}))
      b1=$((16#''${c1:4:2}))

      r2=$((16#''${c2:0:2}))
      g2=$((16#''${c2:2:2}))
      b2=$((16#''${c2:4:2}))

      dr=$((r1 - r2))
      dg=$((g1 - g2))
      db=$((b1 - b2))

      printf '%s' $((dr * dr + dg * dg + db * db))
    }

    secondary_hex="$(normalize_hex "$secondary")"
    best_variant="blue"
    best_distance=""

    for candidate in \
      "rosewater:f5e0dc" \
      "flamingo:f2cdcd" \
      "pink:f5c2e7" \
      "mauve:cba6f7" \
      "red:f38ba8" \
      "maroon:eba0ac" \
      "peach:fab387" \
      "yellow:f9e2af" \
      "green:a6e3a1" \
      "teal:94e2d5" \
      "sky:89dceb" \
      "sapphire:74c7ec" \
      "blue:89b4fa" \
      "lavender:b4befe"
    do
      variant="''${candidate%%:*}"
      hex="''${candidate#*:}"
      distance="$(sq_distance "$secondary_hex" "$hex")"

      if [ -z "$best_distance" ] || [ "$distance" -lt "$best_distance" ]; then
        best_distance="$distance"
        best_variant="$variant"
      fi
    done

    cursor_theme="catppuccin-mocha-''${best_variant}-cursors"

    ${pkgs.gawk}/bin/awk -v active="$primary" -v inactive="$outline" -v cursor_theme="$cursor_theme" '
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

        if (!in_cursor && trimmed ~ /^cursor[ \t]*\{/) {
          in_cursor = 1
          cursor_found = 1
          cursor_indent = indent_of(line)
          has_xcursor_theme = 0
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

        if (in_cursor) {
          if (trimmed ~ /^xcursor-theme[ \t]+/) {
            print cursor_indent "    xcursor-theme \"" cursor_theme "\""
            has_xcursor_theme = 1
            next
          }

          if (trimmed ~ /^\}/) {
            if (!has_xcursor_theme) {
              print cursor_indent "    xcursor-theme \"" cursor_theme "\""
            }
            print line
            in_cursor = 0
            next
          }
        }

        print line
      }

      END {
        if (!cursor_found) {
          print "cursor {"
          print "    xcursor-theme \"" cursor_theme "\""
          print "}"
        }
      }
    ' "$config_file" > "$temp_file"

    mv "$temp_file" "$config_file"
  '';

  refreshFocusRing = pkgs.writeShellScript "noctalia-refresh-niri-focus-ring" ''
    set -eu

    config_file="${niriConfigFile}"

    ${syncFocusRing}

    cursor_theme="$(${pkgs.gawk}/bin/awk '
      /^[ \t]*xcursor-theme[ \t]+/ {
        gsub(/"/, "", $2)
        print $2
        exit
      }
    ' "$config_file" 2>/dev/null || true)"

    if [ -n "$cursor_theme" ]; then
      ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface cursor-theme "$cursor_theme" >/dev/null 2>&1 || true
    fi

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
  # Keep niri config writable so focus-ring and cursor visuals can be patched live.
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
      Description = "Refresh Niri focus ring and cursor theme from Noctalia";
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
