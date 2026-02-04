# Home Manager configuration for user krieger
{ config, pkgs, inputs, hostname, enableGaming, ... }:

{
  imports = [
    # Catppuccin Home Manager module
    inputs.catppuccin.homeModules.catppuccin
    
    ./shellAliases.nix
    ./default-apps.nix
    ./themes.nix
    ./ghostty.nix
    ./niri.nix
    ./niri-wallpaper.nix
    ./waybar-niri.nix
  ] ++ (if enableGaming then [ ./gaming.nix ./comfyui.nix ] else [])
    ++ (if hostname == "nzxt-nix" then [ ./defaultwindows.nix ] else []);

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

  # === Catppuccin-themed Applications ===

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

  # MPV media player
  programs.mpv = {
    enable = true;
  };

  # Bash
  programs.bash.enable = true;

  # Force dark mode system-wide (GNOME apps, portals, freedesktop apps)
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "Adwaita-dark";
    };
  };
}
