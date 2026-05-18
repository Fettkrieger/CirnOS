# Live-sync Papirus folder tint and reload GTK/Nautilus when Noctalia colors change.
#
# Papirus-Dark symlinks into ../Papirus, so we use a Papirus-Dark-Noctalia overlay
# (Inherits=Papirus-Dark) with folder symlinks into the store theme. Noctalia
# rewrites noctalia.css on scheme change, but GTK apps need gtk-refresh + an icon
# theme nudge to repaint; inotify also watches settings.json (scheme picks).
{ config, lib, pkgs, ... }:
let
  baseIconTheme = "Papirus-Dark";
  overlayIconTheme = "Papirus-Dark-Noctalia";
  colorsFile = "${config.xdg.configHome}/noctalia/colors.json";
  settingsFile = "${config.xdg.configHome}/noctalia/settings.json";
  stateFile = "${config.xdg.configHome}/noctalia/papirus-folder-color";
  overlayThemeDir = "${config.home.homeDirectory}/.icons/${overlayIconTheme}";
  storeThemeDir = "${pkgs.papirus-icon-theme}/share/icons/${baseIconTheme}";
  gtkRefreshScript =
    "${config.programs.noctalia-shell.package}/share/noctalia-shell/Scripts/python/src/theming/gtk-refresh.py";
  # Nautilus grid medium+ zoom requests 96x96/128x128; missing sizes inherit Papirus-Dark blue folders.
  iconSizeCandidates = [
    "16x16"
    "16x16@2x"
    "22x22"
    "22x22@2x"
    "24x24"
    "24x24@2x"
    "32x32"
    "32x32@2x"
    "48x48"
    "48x48@2x"
    "64x64"
    "64x64@2x"
    "96x96"
    "128x128"
  ];
  iconSizes = lib.filter (size:
    lib.pathExists "${storeThemeDir}/${size}/places"
  ) iconSizeCandidates;

  overlayIndexTheme = pkgs.writeText "${overlayIconTheme}-index.theme" ''
    [Icon Theme]
    Name=${overlayIconTheme}
    Comment=Papirus-Dark folder tint synced from Noctalia
    Inherits=${baseIconTheme},hicolor
    Example=folder

    ${lib.concatStringsSep "\n" (map (s: "Directories=${s}") iconSizes)}
  '';

  refreshAppearance = pkgs.writeShellScript "noctalia-refresh-appearance" ''
    set -eu

    colors_file="${colorsFile}"
    settings_file="${settingsFile}"
    state_file="${stateFile}"
    overlay_theme="${overlayThemeDir}"
    store_theme="${storeThemeDir}"
    legacy_theme="${config.home.homeDirectory}/.icons/${baseIconTheme}"
    gtk_refresh="${gtkRefreshScript}"

    remove_legacy_theme() {
      if [ ! -e "$legacy_theme" ]; then
        return 0
      fi

      ${pkgs.coreutils}/bin/chmod -R u+w "$legacy_theme" 2>/dev/null || true
      ${pkgs.coreutils}/bin/rm -rf "$legacy_theme" 2>/dev/null || true

      if [ -e "$legacy_theme" ]; then
        broken="''${legacy_theme}.broken.$(${pkgs.coreutils}/bin/date +%s)"
        ${pkgs.coreutils}/bin/mv "$legacy_theme" "$broken" 2>/dev/null || true
      fi
    }

    ensure_overlay_theme() {
      mkdir -p "$overlay_theme"
      ${pkgs.coreutils}/bin/install -m 0644 "${overlayIndexTheme}" "$overlay_theme/index.theme"

      for size in ${lib.concatStringsSep " " iconSizes}; do
        mkdir -p "$overlay_theme/$size/places"
      done
    }

    apply_folder_color() {
      local color="$1"
      local size prefix file_path file_name symlink_name target

      for size in ${lib.concatStringsSep " " iconSizes}; do
        for prefix in "folder-$color" "user-$color"; do
          for file_path in "$store_theme/$size/places/$prefix"{-*,}.svg; do
            [ -f "$file_path" ] || continue

            file_name="''${file_path##*/}"
            symlink_name="''${file_name/-$color/}"
            target="$overlay_theme/$size/places/$symlink_name"

            ${pkgs.coreutils}/bin/ln -sf "$file_path" "$target"
          done
        done
      done
    }

    # Papirus-Dark aliases (inode-directory, folder-publicshare, …) point at other
    # place icons. GTK resolves those inside the inherited theme and never sees
    # overlay folder.svg / folder-image-people.svg unless we mirror the aliases.
    link_place_aliases() {
      local size store_places overlay_places link link_target base_name normalized

      for size in ${lib.concatStringsSep " " iconSizes}; do
        store_places="$store_theme/$size/places"
        overlay_places="$overlay_theme/$size/places"

        for link in "$store_places"/*.svg; do
          [ -L "$link" ] || continue
          link_target="$(${pkgs.coreutils}/bin/readlink "$link")"
          [[ "$link_target" == *"/"* ]] && continue

          base_name="''${link##*/}"
          [ -e "$overlay_places/$base_name" ] && continue

          normalized="$link_target"
          case "$link_target" in
            folder-blue*)
              normalized="''${link_target/-blue/}"
              ;;
            user-blue*)
              normalized="''${link_target/-blue/}"
              ;;
          esac

          if [ -e "$overlay_places/$normalized" ]; then
            ${pkgs.coreutils}/bin/ln -sf "$normalized" "$overlay_places/$base_name"
          fi
        done
      done
    }

    delete_icon_caches() {
      ${pkgs.coreutils}/bin/rm -f \
        "${config.home.homeDirectory}/.cache/icon-cache.kcache" \
        "/var/tmp/kdecache-$(${pkgs.coreutils}/bin/id -u)/icon-cache.kcache" \
        2>/dev/null || true
    }

    update_icon_caches() {
      local theme_dir

      delete_icon_caches

      ${pkgs.coreutils}/bin/rm -f "$overlay_theme/icon-theme.cache"
      ${pkgs.gtk3}/bin/gtk-update-icon-cache -qf "$overlay_theme" 2>/dev/null || true

      for theme_dir in \
        "$store_theme" \
        "${pkgs.papirus-icon-theme}/share/icons/Papirus-Light" \
        "${config.home.homeDirectory}/.local/share/icons/${baseIconTheme}" \
        "${config.home.homeDirectory}/.icons/${baseIconTheme}"
      do
        [ -d "$theme_dir" ] || continue
        ${pkgs.gtk3}/bin/gtk-update-icon-cache -qf "$theme_dir" 2>/dev/null || true
      done
    }

    nudge_nautilus() {
      ${pkgs.procps}/bin/pkill -HUP -x nautilus 2>/dev/null || true
    }

    reload_icon_theme() {
      ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface icon-theme "" 2>/dev/null || true
      ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface icon-theme "${overlayIconTheme}" 2>/dev/null || true
    }

    reload_gtk_appearance() {
      local gtk_mode="dark"

      if [ -r "$settings_file" ]; then
        case "$(${pkgs.jq}/bin/jq -r '.colorSchemes.darkMode // true' "$settings_file" 2>/dev/null || true)" in
          false|0) gtk_mode="light" ;;
        esac
      fi

      if [ -f "$gtk_refresh" ]; then
        ${pkgs.python3}/bin/python3 "$gtk_refresh" "$gtk_mode" >/dev/null 2>&1 || true
      fi

      # Nudge gtk-theme so GTK4 apps reload noctalia.css (not just gsettings color-scheme).
      local gtk_theme="adw-gtk3-''${gtk_mode}"
      ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3" 2>/dev/null || true
      ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme" 2>/dev/null || true
    }

    remove_legacy_theme
    ensure_overlay_theme

    primary="#89b4fa"

    if [ -r "$colors_file" ]; then
      maybe_primary="$(${pkgs.jq}/bin/jq -r '.mPrimary // empty' "$colors_file" 2>/dev/null || true)"
      if [ -n "$maybe_primary" ]; then
        primary="$maybe_primary"
      fi
    fi

    case "$primary" in
      \#*) ;;
      *) primary="#$primary" ;;
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

    primary_hex="$(normalize_hex "$primary")"
    best_color="blue"
    best_distance=""

    for candidate in \
      "adwaita:3a87e5" \
      "black:3f3f3f" \
      "blue:4877b1" \
      "bluegrey:4d646f" \
      "breeze:147eb8" \
      "brown:957552" \
      "carmine:7a0002" \
      "cyan:0096aa" \
      "darkcyan:35818a" \
      "deeporange:e95420" \
      "green:60924b" \
      "grey:727272" \
      "indigo:3f51b5" \
      "magenta:b259b8" \
      "nordic:5e81ac" \
      "orange:dd772f" \
      "palebrown:bea389" \
      "paleorange:c89e6b" \
      "pink:ec407a" \
      "red:bf4b4b" \
      "teal:12806a" \
      "violet:5d399b" \
      "white:cccccc" \
      "yaru:973552" \
      "yellow:e19d00"
    do
      color="''${candidate%%:*}"
      hex="''${candidate#*:}"
      distance="$(sq_distance "$primary_hex" "$hex")"

      if [ -z "$best_distance" ] || [ "$distance" -lt "$best_distance" ]; then
        best_distance="$distance"
        best_color="$color"
      fi
    done

    new_state="''${best_color}:''${primary_hex}"
    folder_changed=1
    if [ -f "$state_file" ] && [ "$(cat "$state_file")" = "$new_state" ]; then
      folder_changed=0
    fi

    # Re-apply when large-size slots or place aliases are missing (post-upgrade).
    if [ "$folder_changed" -eq 0 ] && {
      [ ! -e "$overlay_theme/96x96/places/folder.svg" ] ||
        [ ! -e "$overlay_theme/48x48/places/inode-directory.svg" ] ||
        [ ! -e "$overlay_theme/48x48/places/folder-publicshare.svg" ];
    }; then
      folder_changed=1
    fi

    if [ "$folder_changed" -eq 1 ]; then
      apply_folder_color "$best_color"
      link_place_aliases
      update_icon_caches
      mkdir -p "$(dirname "$state_file")"
      printf '%s\n' "$new_state" > "$state_file"
      reload_icon_theme
      nudge_nautilus
    fi

    reload_gtk_appearance
  '';

  watchAppearance = pkgs.writeShellScript "noctalia-watch-appearance" ''
    set -eu

    colors_file="${colorsFile}"
    watch_dir="$(dirname "$colors_file")"
    lock_file="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}/noctalia-appearance.lock"

    mkdir -p "$watch_dir"
    [ -f "$colors_file" ] || touch "$colors_file"

    schedule_refresh() {
      ${pkgs.util-linux}/bin/flock -n "$lock_file" -c "
        sleep 0.25
        ${refreshAppearance}
      " 2>/dev/null || true
    }

    ${refreshAppearance}

    ${pkgs.inotify-tools}/bin/inotifywait -m \
      -e close_write,modify,moved_to,attrib \
      --format '%f' \
      "$watch_dir" \
      | while read -r changed; do
          case "$changed" in
            colors.json|settings.json)
              schedule_refresh &
              ;;
          esac
        done
  '';
in
{
  home.activation.noctaliaPapirusFoldersInit = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${refreshAppearance}
  '';

  systemd.user.services.noctalia-papirus-folders-live = {
    Unit = {
      Description = "Sync Papirus folders and reload GTK when Noctalia colors change";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${watchAppearance}";
      Restart = "always";
      RestartSec = 1;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
