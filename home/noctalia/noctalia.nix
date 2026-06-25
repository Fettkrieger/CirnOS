# Noctalia v5 shell - desktop bar, notifications, control center, and dock.
#
# v5 uses declarative TOML at ~/.config/noctalia/config.toml. Runtime edits made
# from Noctalia's UI are stored under ~/.local/state/noctalia and are no longer
# symlinked back into this repository.
{ config, inputs, pkgs, ... }:

{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  programs.noctalia = {
    enable = true;
    systemd.enable = false;
    package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;

    settings = {
      shell = {
        ui_scale = 1.05;
        telemetry_enabled = false;
        setup_wizard_enabled = false;
        polkit_agent = true;
        clipboard_auto_paste = "auto";
        avatar_path = "${config.home.homeDirectory}/Pictures/cirnos.gif";
      };

      theme = {
        mode = "dark";
        source = "builtin";
        builtin = "Catppuccin";
        templates = {
          enable_builtin_templates = true;
          builtin_ids = [
            "ghostty"
            "gtk3"
            "gtk4"
            "qt"
            "btop"
          ];
          enable_community_templates = false;
          community_ids = [ ];
        };
      };

      wallpaper = {
        enabled = true;
        fill_mode = "crop";
        transition_on_startup = false;
        directory = "${config.home.homeDirectory}/Pictures/Wallpapers";
        automation.enabled = false;
      };

      dock = {
        enabled = true;
        position = "bottom";
        active_monitor_only = true;
        icon_size = 48;
        background_opacity = 0.88;
        margin_edge = 8;
        show_running = true;
        auto_hide = false;
        reserve_space = false;
        magnification = true;
        launcher_position = "end";
        pinned = [
          "firefox"
          "org.gnome.Nautilus"
          "code"
          "spotify"
          "com.discordapp.Discord"
        ];
      };
    };
  };
}
