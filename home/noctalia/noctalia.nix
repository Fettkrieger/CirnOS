# Noctalia shell - desktop bar, notifications, and control center
#
# Settings are stored in a git-tracked file so UI edits are versioned.
{ config, inputs, lib, pkgs, ... }:

let
  repoSettingsFile = "${config.home.homeDirectory}/CirnOS/home/noctalia/noctalia-settings.json";
  legacySettingsFile = "${config.home.homeDirectory}/.config/noctalia/settings.json";
  repoPluginsFile = "${config.home.homeDirectory}/CirnOS/home/noctalia/noctalia-plugins.json";
  legacyPluginsFile = "${config.home.homeDirectory}/.config/noctalia/plugins.json";
  repoTailscaleSettingsFile = "${config.home.homeDirectory}/CirnOS/home/noctalia/tailscale-settings.json";
  tailscaleSettingsFile = "${config.xdg.configHome}/noctalia/plugins/tailscale/settings.json";
  batteryThresholdServiceFile = "${config.home.homeDirectory}/CirnOS/home/noctalia/battery-threshold/BatteryThresholdService.qml";
  patchedNoctaliaPackage = (inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default).overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      # Fix clipboard auto-paste focus race by waiting briefly before sending paste keys.
      substituteInPlace Services/Keyboard/ClipboardService.qml \
        --replace-fail \
          'const cmd = `cliphist decode ''${id} | wl-copy''${typeArg} && ''${pasteKeys}`;' \
          'const cmd = `cliphist decode ''${id} | wl-copy''${typeArg} && ''${isImage ? "sleep 0.12 && " : ""}''${pasteKeys}`;'

      # Papirus-Dark ships Nautilus as `nautilus`, while GNOME Files exports
      # the reverse-DNS icon name `org.gnome.Nautilus`. Teach Noctalia's shared
      # icon resolver to retry with the theme-native alias so workspace icons,
      # the dock, and other app surfaces all render it consistently.
      oldThemeIconsIconFromName="$(cat <<'EOF'
  function iconFromName(iconName, fallbackName) {
    const fallback = fallbackName || "application-x-executable";
    try {
      if (iconName && typeof Quickshell !== 'undefined' && Quickshell.iconPath) {
        const p = Quickshell.iconPath(iconName, fallback);
        if (p && p !== "")
          return p;
      }
    } catch (e) {}

    try {
      return Quickshell.iconPath ? (Quickshell.iconPath(fallback, true) || "") : "";
    } catch (e2) {
      return "";
    }
  }
EOF
)"
      newThemeIconsIconFromName="$(cat <<'EOF'
  function iconFromName(iconName, fallbackName) {
    const fallback = fallbackName || "application-x-executable";
    const normalizedIconName = (iconName || "").toLowerCase();
    var aliasName = "";

    if (normalizedIconName === "org.gnome.nautilus" || normalizedIconName === "org.gnome.files")
      aliasName = "nautilus";

    try {
      if (iconName && typeof Quickshell !== 'undefined' && Quickshell.iconPath) {
        const p = Quickshell.iconPath(iconName, fallback);
        if (p && p !== "")
          return p;

        if (aliasName) {
          const aliasPath = Quickshell.iconPath(aliasName, fallback);
          if (aliasPath && aliasPath !== "")
            return aliasPath;
        }
      }
    } catch (e) {}

    try {
      return Quickshell.iconPath ? (Quickshell.iconPath(fallback, true) || "") : "";
    } catch (e2) {
      return "";
    }
  }
EOF
)"
      substituteInPlace Commons/ThemeIcons.qml \
        --replace-fail \
          "$oldThemeIconsIconFromName" \
          "$newThemeIconsIconFromName"

      # Let external color-sync services force a redraw when the wallpaper file
      # changed but the selected wallpaper path stayed the same.
      substituteInPlace Services/Control/IPCService.qml \
        --replace-fail \
          '    function toggleAutomation() {' \
          $'    function reload(screen: string) {\n      if (!screen || screen === "all" || screen.trim().length === 0) {\n        for (var i = 0; i < Quickshell.screens.length; i++) {\n          var name = Quickshell.screens[i].name;\n          WallpaperService.wallpaperChanged(name, WallpaperService.getWallpaper(name) ?? "");\n        }\n        return;\n      }\n\n      var found = Quickshell.screens.find(s => s.name === screen);\n      if (!found) {\n        Logger.w("IPC", "wallpaper reload: unknown screen: " + screen);\n        return;\n      }\n\n      WallpaperService.wallpaperChanged(screen, WallpaperService.getWallpaper(screen) ?? "");\n    }\n\n    function toggleAutomation() {'
    '';
  });
in

{
  imports = [
    inputs.noctalia.homeModules.default
    ./niri-focus-ring-live.nix
    ./nix-wallpaper-live.nix
    ./papirus-folders-live.nix
  ];

  programs.noctalia-shell = {
    enable = true;
    package = patchedNoctaliaPackage;
  };

  # Keep Noctalia on default config paths, but point them to repository-tracked
  # files so UI edits are committed naturally.
  home.activation.noctaliaSettingsBootstrap = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$(dirname "${repoSettingsFile}")"
    mkdir -p "$(dirname "${legacySettingsFile}")"
    mkdir -p "$(dirname "${repoPluginsFile}")"
    mkdir -p "$(dirname "${legacyPluginsFile}")"

    if [ ! -e "${repoSettingsFile}" ]; then
      if [ -e "${legacySettingsFile}" ] && [ ! -L "${legacySettingsFile}" ]; then
        cp "${legacySettingsFile}" "${repoSettingsFile}"
      else
        printf '{}\n' > "${repoSettingsFile}"
      fi
      chmod u+rw "${repoSettingsFile}"
    fi

    if [ ! -e "${repoPluginsFile}" ]; then
      if [ -e "${legacyPluginsFile}" ] && [ ! -L "${legacyPluginsFile}" ]; then
        cp "${legacyPluginsFile}" "${repoPluginsFile}"
      else
        printf '{"version":2,"sources":[],"states":{}}\n' > "${repoPluginsFile}"
      fi
      chmod u+rw "${repoPluginsFile}"
    fi

    ln -sfn "${repoSettingsFile}" "${legacySettingsFile}"
    ln -sfn "${repoPluginsFile}" "${legacyPluginsFile}"
  '';

  home.activation.noctaliaTailscaleSettingsBootstrap = lib.hm.dag.entryAfter [ "noctaliaSettingsBootstrap" ] ''
    mkdir -p "$(dirname "${repoTailscaleSettingsFile}")"
    mkdir -p "$(dirname "${tailscaleSettingsFile}")"

    if [ ! -e "${repoTailscaleSettingsFile}" ]; then
      if [ -e "${tailscaleSettingsFile}" ] && [ ! -L "${tailscaleSettingsFile}" ]; then
        cp "${tailscaleSettingsFile}" "${repoTailscaleSettingsFile}"
      else
        printf '{}\n' > "${repoTailscaleSettingsFile}"
      fi
      chmod u+rw "${repoTailscaleSettingsFile}"
    fi

    ln -sfn "${repoTailscaleSettingsFile}" "${tailscaleSettingsFile}"
  '';

  # The upstream battery-threshold plugin only writes the stop threshold. On
  # ThinkPads, the start threshold must be updated too or a 100% stop limit can
  # still leave the battery stuck in pending-charge around the old start limit.
  home.activation.noctaliaBatteryThresholdPluginPatch = lib.hm.dag.entryAfter [ "noctaliaSettingsBootstrap" ] ''
    pluginService="${config.xdg.configHome}/noctalia/plugins/battery-threshold/BatteryThresholdService.qml"
    if [ -f "$pluginService" ] && [ -f "${batteryThresholdServiceFile}" ]; then
      ${pkgs.coreutils}/bin/install -m 0644 "${batteryThresholdServiceFile}" "$pluginService"
    fi
  '';
}
