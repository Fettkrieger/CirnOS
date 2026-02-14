# Noctalia shell - desktop bar, notifications, and control center
#
# To update settings:
#   1. Change settings in noctalia GUI
#   2. Copy ~/.config/noctalia/settings.json to home/noctalia-settings.json
#   3. Run rebuild
{ inputs, hostname, ... }:

{
  imports = [ inputs.noctalia.homeModules.default ];

  programs.noctalia-shell = {
    enable = true;
    systemd.enable = true;
    settings = builtins.fromJSON (builtins.readFile ./noctalia-settings.json);
  };
}
