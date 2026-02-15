# Noctalia shell - desktop bar, notifications, and control center
#
# Settings are stored in a git-tracked file so UI edits are versioned.
{ config, inputs, lib, pkgs, ... }:

let
  repoSettingsFile = "${config.home.homeDirectory}/CirnOS/home/noctalia/noctalia-settings.json";
  legacySettingsFile = "${config.home.homeDirectory}/.config/noctalia/settings.json";
  repoPluginsFile = "${config.home.homeDirectory}/CirnOS/home/noctalia/noctalia-plugins.json";
  legacyPluginsFile = "${config.home.homeDirectory}/.config/noctalia/plugins.json";
  patchedNoctaliaPackage = (inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default).overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      # Fix clipboard auto-paste focus race by waiting briefly before sending paste keys.
      substituteInPlace Services/Keyboard/ClipboardService.qml \
        --replace-fail \
          'const cmd = `cliphist decode ''${id} | wl-copy''${typeArg} && ''${pasteKeys}`;' \
          'const cmd = `cliphist decode ''${id} | wl-copy''${typeArg} && ''${isImage ? "sleep 0.12 && " : ""}''${pasteKeys}`;'
    '';
  });
in

{
  imports = [ inputs.noctalia.homeModules.default ];

  programs.noctalia-shell = {
    enable = true;
    systemd.enable = true;
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
}
