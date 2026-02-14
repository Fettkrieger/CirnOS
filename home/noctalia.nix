# Noctalia shell - desktop bar, notifications, and control center
#
# Settings are managed directly by Noctalia in ~/.config/noctalia/settings.json
{ inputs, hostname, ... }:

{
  imports = [ inputs.noctalia.homeModules.default ];

  programs.noctalia-shell = {
    enable = true;
    systemd.enable = true;
  };
}
