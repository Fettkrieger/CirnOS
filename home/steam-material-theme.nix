# Material-Theme for Steam (Millennium) + Noctalia matugen.css sync.
#
# Deploys the full Material-Theme skin, preserves Noctalia's matugen.css under steamui/skins,
# and sets Millennium to use Material-Theme with Color = Matugen.
{ config, lib, pkgs, ... }:

let
  materialTheme = pkgs.fetchFromGitHub {
    owner = "kuska1";
    repo = "Material-Theme";
    rev = "b661d69f028a53ca1ff294772c34a55ef402b52c";
    hash = "sha256-rAAUO38wDKsCV2IiE5wBrmMnKvHVOHzQCXv1IKOiLmI=";
  };

  steamPath = "${config.home.homeDirectory}/.local/share/Steam";
  millenniumThemeDir = "${steamPath}/millennium/themes/Material-Theme";
  matugenCss = "${steamPath}/steamui/skins/Material-Theme/css/main/colors/matugen.css";
  millenniumConfig = "${config.xdg.configHome}/millennium/config.json";
  noctaliaColors = "${config.xdg.configHome}/noctalia/colors.json";

  syncMaterialTheme = pkgs.writeShellScript "sync-steam-material-theme" ''
    set -eu

    theme_dir="${millenniumThemeDir}"
    matugen_css="${matugenCss}"
    matugen_backup=""

    if [ -f "$matugen_css" ]; then
      matugen_backup="$(${pkgs.coreutils}/bin/mktemp)"
      ${pkgs.coreutils}/bin/cp "$matugen_css" "$matugen_backup"
    fi

    ${pkgs.coreutils}/bin/mkdir -p "$(dirname "$theme_dir")"
    ${pkgs.coreutils}/bin/rm -rf "$theme_dir"
    # --no-preserve=mode: nix store sources are read-only; Millennium may write metadata.json
    ${pkgs.coreutils}/bin/cp -r --no-preserve=mode ${materialTheme} "$theme_dir"
    chmod -R u+rwX "$theme_dir"

    ${pkgs.coreutils}/bin/mkdir -p "$(dirname "$matugen_css")"
    if [ -n "$matugen_backup" ]; then
      ${pkgs.coreutils}/bin/cp "$matugen_backup" "$matugen_css"
      ${pkgs.coreutils}/bin/rm -f "$matugen_backup"
    elif [ ! -f "$matugen_css" ]; then
      ${pkgs.coreutils}/bin/touch "$matugen_css"
    fi
  '';

  configureMillennium = pkgs.writeShellScript "configure-millennium-material-theme" ''
    set -eu

    config_file="${millenniumConfig}"
    ${pkgs.coreutils}/bin/mkdir -p "$(dirname "$config_file")"

    if [ ! -f "$config_file" ]; then
      ${pkgs.jq}/bin/jq -n '{
        general: {
          injectJavascript: true,
          injectCSS: true,
          checkForMillenniumUpdates: true,
          checkForPluginAndThemeUpdates: true,
          onMillenniumUpdate: 1,
          millenniumUpdateChannel: "beta",
          shouldShowThemePluginUpdateNotifications: true,
          accentColor: "DEFAULT_ACCENT_COLOR"
        },
        misc: { hasShownWelcomeModal: true },
        themes: {
          activeTheme: "Material-Theme",
          allowedStyles: true,
          allowedScripts: true,
          conditions: {
            "Material-Theme": { Color: "Matugen" }
          }
        },
        notifications: {
          showNotifications: true,
          showUpdateNotifications: true,
          showPluginNotifications: true
        }
      }' > "$config_file"
    else
      tmp="$(${pkgs.coreutils}/bin/mktemp)"
      ${pkgs.jq}/bin/jq '
        .themes.activeTheme = "Material-Theme"
        | .themes.conditions = ((.themes.conditions // {}) + {"Material-Theme": ((.themes.conditions["Material-Theme"] // {}) + {Color: "Matugen"})})
        | .themes.allowedStyles = (.themes.allowedStyles // true)
        | .themes.allowedScripts = (.themes.allowedScripts // true)
      ' "$config_file" > "$tmp"
      ${pkgs.coreutils}/bin/mv "$tmp" "$config_file"
    fi
  '';

  verifyMatugenSync = pkgs.writeShellScript "verify-noctalia-steam-matugen" ''
    set -eu

    colors_file="${noctaliaColors}"
    matugen_file="${matugenCss}"

    if [ ! -f "$colors_file" ] || [ ! -f "$matugen_file" ]; then
      echo "steam-matugen: skip verify (colors or matugen.css missing)" >&2
      exit 0
    fi

    hex="$(${pkgs.jq}/bin/jq -r '.mPrimary // empty' "$colors_file" | ${pkgs.coreutils}/bin/tr '[:upper:]' '[:lower:]' | ${pkgs.gnused}/bin/sed 's/^#//')"
    if [ -z "$hex" ] || [ "$(printf '%s' "$hex" | wc -c)" -ne 6 ]; then
      echo "steam-matugen: skip verify (invalid mPrimary)" >&2
      exit 0
    fi

    r=$((16#''${hex:0:2}))
    g=$((16#''${hex:2:2}))
    b=$((16#''${hex:4:2}))
    expected="rgb($r, $g, $b)"

    if ${pkgs.gnugrep}/bin/grep -qF -- "--md-sys-color-primary: $expected;" "$matugen_file"; then
      echo "steam-matugen: verified mPrimary matches matugen.css ($expected)" >&2
    else
      echo "steam-matugen: warning — matugen.css primary does not match Noctalia mPrimary ($expected); toggle a color scheme in Noctalia and restart Steam" >&2
    fi
  '';

  restartSteam = pkgs.writeShellScript "restart-steam-after-millennium" ''
    set -eu
    if ${pkgs.procps}/bin/pgrep -x steam >/dev/null 2>&1; then
      echo "steam-matugen: shutting down Steam for Millennium/Material-Theme apply..." >&2
      ${pkgs.steam}/bin/steam -shutdown || true
      sleep 2
    fi
  '';
in
{
  # Noctalia spawns `steam` when the window is closed but Steam stays in the tray;
  # cirnos-steam writes steam://open/library to ~/.steam/steam.pipe (no second process).
  xdg.desktopEntries.steam = {
    name = "Steam";
    comment = "Application for managing and playing games on Steam";
    exec = "/run/current-system/sw/bin/cirnos-steam %U";
    icon = "steam";
    terminal = false;
    categories = [ "Network" "FileTransfer" "Game" ];
    mimeType = [
      "x-scheme-handler/steam"
      "x-scheme-handler/steamlink"
    ];
  };

  home.activation = {
    syncSteamMaterialTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${syncMaterialTheme}
    '';
    configureMillenniumMaterialTheme = lib.hm.dag.entryAfter [ "syncSteamMaterialTheme" ] ''
      $DRY_RUN_CMD ${configureMillennium}
    '';
    verifyNoctaliaSteamMatugen = lib.hm.dag.entryAfter [ "configureMillenniumMaterialTheme" ] ''
      $DRY_RUN_CMD ${verifyMatugenSync}
    '';
    restartSteamAfterMillennium = lib.hm.dag.entryAfter [ "verifyNoctaliaSteamMatugen" ] ''
      $DRY_RUN_CMD ${restartSteam}
    '';
  };
}
