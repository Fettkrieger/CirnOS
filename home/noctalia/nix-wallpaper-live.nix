{ config, lib, pkgs, ... }:
let
  colorsFile = "${config.xdg.configHome}/noctalia/colors.json";
  wallpaperFile = "${config.home.homeDirectory}/Pictures/Wallpapers/nix.svg";
  noctaliaShell = "${config.programs.noctalia-shell.package}/bin/noctalia-shell";

  syncNixWallpaper = pkgs.writeShellScript "noctalia-sync-nix-wallpaper" ''
    set -eu

    colors_file="${colorsFile}"
    wallpaper_file="${wallpaperFile}"

    if [ ! -f "$wallpaper_file" ]; then
      exit 0
    fi

    read_color() {
      local key="$1"
      if [ -r "$colors_file" ]; then
        ${pkgs.jq}/bin/jq -r --arg key "$key" '.[$key] // empty' "$colors_file" 2>/dev/null || true
      fi
    }

    normalize_hex() {
      local value="$1"
      local fallback="$2"

      value="$(printf '%s' "$value" | ${pkgs.coreutils}/bin/tr '[:upper:]' '[:lower:]')"
      value="''${value#\#}"

      if printf '%s\n' "$value" | ${pkgs.gnugrep}/bin/grep -Eq '^[0-9a-f]{6}([0-9a-f]{2})?$'; then
        printf '#%s' "$value"
      else
        printf '%s' "$fallback"
      fi
    }

    bar_color="$(normalize_hex "$(read_color mSurface)" "#1e1e2e")"
    primary="$(normalize_hex "$(read_color mPrimary)" "#313244")"
    secondary="$(normalize_hex "$(read_color mSecondary)" "#45475a")"

    temp_file="$(${pkgs.coreutils}/bin/mktemp --tmpdir="$(dirname "$wallpaper_file")" ".nix.svg.XXXXXX")"

    NOCTALIA_BAR_COLOR="$bar_color" \
    NOCTALIA_PRIMARY="$primary" \
    NOCTALIA_SECONDARY="$secondary" \
      ${pkgs.perl}/bin/perl -0pe '
        my $bar = $ENV{"NOCTALIA_BAR_COLOR"};
        my $primary = $ENV{"NOCTALIA_PRIMARY"};
        my $secondary = $ENV{"NOCTALIA_SECONDARY"};

        sub with_fill {
          my ($style, $color) = @_;

          if ($style =~ /(^|;)\s*fill\s*:/) {
            $style =~ s/(^|;)\s*fill\s*:\s*#[0-9A-Fa-f]{3,8}/$1 . "fill:" . $color/ge;
          } else {
            $style .= ";fill:$color";
          }

          return $style;
        }

        s{(<rect\b(?=[^>]*\bid="rect3019")[^>]*\bstyle=")([^"]*)(")}{$1 . with_fill($2, $bar) . $3}eg;

        s{(<path\b(?=[^>]*\bid="path4260)[^>]*\bstyle=")([^"]*)(")}{$1 . with_fill($2, $primary) . $3}eg;
        s{(<use\b(?=[^>]*(?:xlink:)?href="#path4260)[^>]*\bstyle=")([^"]*)(")}{$1 . with_fill($2, $primary) . $3}eg;

        s{(<path\b(?=[^>]*\bid="path3336)[^>]*\bstyle=")([^"]*)(")}{$1 . with_fill($2, $secondary) . $3}eg;
        s{(<use\b(?=[^>]*(?:xlink:)?href="#path3336)[^>]*\bstyle=")([^"]*)(")}{$1 . with_fill($2, $secondary) . $3}eg;
      ' "$wallpaper_file" > "$temp_file"

    if ${pkgs.diffutils}/bin/cmp -s "$wallpaper_file" "$temp_file"; then
      rm -f "$temp_file"
    else
      mv "$temp_file" "$wallpaper_file"
      # Noctalia's image cache keys include mtime in whole seconds.
      ${pkgs.coreutils}/bin/touch -d "@$(( $(${pkgs.coreutils}/bin/date +%s) + 1 ))" "$wallpaper_file"
    fi
  '';

  refreshNixWallpaper = pkgs.writeShellScript "noctalia-refresh-nix-wallpaper" ''
    set -eu

    ${syncNixWallpaper}
    ${noctaliaShell} ipc call wallpaper reload all >/dev/null 2>&1 || true
  '';

  watchNixWallpaper = pkgs.writeShellScript "noctalia-watch-nix-wallpaper" ''
    set -eu

    colors_file="${colorsFile}"
    watch_dir="$(dirname "$colors_file")"
    watch_name="$(basename "$colors_file")"

    mkdir -p "$watch_dir"
    [ -f "$colors_file" ] || touch "$colors_file"

    ${refreshNixWallpaper}

    ${pkgs.inotify-tools}/bin/inotifywait -m -e close_write,move,create --format '%f' "$watch_dir" \
      | while read -r changed; do
          if [ "$changed" = "$watch_name" ]; then
            ${refreshNixWallpaper}
          fi
        done
  '';
in
{
  home.activation.noctaliaNixWallpaperInit = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${syncNixWallpaper}
  '';

  systemd.user.services.noctalia-nix-wallpaper-live = {
    Unit = {
      Description = "Refresh Nix SVG wallpaper from Noctalia colors";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${watchNixWallpaper}";
      Restart = "always";
      RestartSec = 1;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
