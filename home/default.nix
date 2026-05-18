# Home Manager configuration for user krieger
{ config, pkgs, inputs, hostname, enableGaming, ... }:

{
  imports = [
    ./shellAliases.nix
    ./default-apps.nix
    ./themes.nix
    ./ghostty.nix
    ./syncthing.nix
    ./niri.nix
    ./noctalia/noctalia.nix
  ] ++ (if enableGaming then [ ./gaming.nix ] else [])
    ++ (if builtins.elem hostname [ "hp-nix" "lenuwu-nix" ] then [ ./workspaces-hp.nix ] else []);

  home.username = "krieger";
  home.homeDirectory = "/home/krieger";
  home.stateVersion = "24.11";

  # User packages
  home.packages = with pkgs; [
    
  ];

 

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # Git configuration
  programs.git = {
    enable = true;
    signing.format = "openpgp";
    settings = {
      user.name = "Krieger";
      user.email = "leandro.tiziani@protonmail.com";
      init.defaultBranch = "main";
      pull.rebase = false;
    };
  };

  # Direnv
  programs.direnv = {
    enable = true;
    silent = true;
  };

  # === Themed Applications ===

  # Btop system monitor
  programs.btop = {
    enable = true;
  };

  # Bat (cat replacement with syntax highlighting)
  programs.bat = {
    enable = true;
  };

  # Eza (ls replacement)
  programs.eza = {
    enable = true;
    icons = "auto";
    git = true;
  };

  # Fzf (fuzzy finder)
  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
  };

  # Yazi terminal file manager
  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
    shellWrapperName = "y";
  };

  # MPV media player
  programs.mpv = {
    enable = true;
  };

  # Bash
  programs.bash.enable = true;

  # Force dark mode system-wide (GNOME apps, portals, freedesktop apps).
  # `gtk-theme` matches home/themes.nix so portal hosts (file-chooser,
  # screencast permission dialogs) and any GTK4 app reading gsettings
  # render with the same baseline as the static theme. Noctalia's GTK
  # template overrides accent colors at runtime via gtk.css imports.
  # `icon-theme` matches home/themes.nix so GNOME/portal hosts and any
  # toolkit that consults gsettings (instead of gtkrc) get the same
  # Papirus-Dark-Noctalia overlay resolution chain as Quickshell-based Noctalia.
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "adw-gtk3-dark";
      icon-theme = "Papirus-Dark-Noctalia";
      cursor-theme = "catppuccin-mocha-blue-cursors";
      cursor-size = 24;
      enable-hot-corners = false;
    };
  };
}
