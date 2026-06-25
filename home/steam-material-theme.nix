# Material-Theme for Steam (Millennium).
#
# Deploys the full Material-Theme skin, preserves any existing matugen.css under
# steamui/skins, and sets Millennium to use Material-Theme with Color = Matugen.
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
    restartSteamAfterMillennium = lib.hm.dag.entryAfter [ "configureMillenniumMaterialTheme" ] ''
      $DRY_RUN_CMD ${restartSteam}
    '';
  };
}
