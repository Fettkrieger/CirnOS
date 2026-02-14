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

  # Keep Noctalia on its default settings path, but point that path to a
  # repository-tracked file so UI edits are committed naturally.
  home.activation.noctaliaSettingsBootstrap = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$(dirname "${repoSettingsFile}")"
    mkdir -p "$(dirname "${legacySettingsFile}")"

    if [ ! -e "${repoSettingsFile}" ]; then
      if [ -e "${legacySettingsFile}" ] && [ ! -L "${legacySettingsFile}" ]; then
        cp "${legacySettingsFile}" "${repoSettingsFile}"
      else
        printf '{}\n' > "${repoSettingsFile}"
      fi
      chmod u+rw "${repoSettingsFile}"
    fi

    ln -sfn "${repoSettingsFile}" "${legacySettingsFile}"
  '';
}
