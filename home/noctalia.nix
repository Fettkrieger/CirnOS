# Noctalia shell - desktop bar, notifications, and control center
#
# Settings are stored in a git-tracked file so UI edits are versioned.
{ config, inputs, lib, ... }:

let
  repoSettingsFile = "${config.home.homeDirectory}/CirnOS/home/noctalia-settings.json";
  legacySettingsFile = "${config.home.homeDirectory}/.config/noctalia/settings.json";
in

{
  imports = [ inputs.noctalia.homeModules.default ];

  programs.noctalia-shell = {
    enable = true;
    systemd.enable = true;
  };

  # Make Noctalia read/write the repository-backed settings file.
  systemd.user.services.noctalia-shell.Service.Environment = [
    "NOCTALIA_SETTINGS_FILE=${repoSettingsFile}"
  ];

  # One-time migration: if the repo file doesn't exist yet, seed it from the
  # current ~/.config/noctalia/settings.json so existing UI settings are kept.
  home.activation.noctaliaSettingsBootstrap = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -e "${repoSettingsFile}" ] && [ -e "${legacySettingsFile}" ]; then
      cp "${legacySettingsFile}" "${repoSettingsFile}"
      chmod u+rw "${repoSettingsFile}"
    fi
  '';
}
