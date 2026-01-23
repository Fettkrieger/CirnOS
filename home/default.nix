# Home Manager configuration for user krieger
{ config, pkgs, inputs, hostname, enableGaming, ... }:

{
  imports = [
    # Catppuccin Home Manager module
    inputs.catppuccin.homeModules.catppuccin
    
    ./keybindings.nix
    ./shellAliases.nix
    ./default-apps.nix
    ./themes.nix
  ] ++ (if enableGaming then [ ./gaming.nix ] else []);

  home.username = "krieger";
  home.homeDirectory = "/home/krieger";
  home.stateVersion = "24.11";

  # User packages
  home.packages = with pkgs; [
    # === Development ===
    vscode

    # === CLI Tools & Utilities ===
    fastfetch
    tree
    ripgrep
    fd
    yt-dlp
    fragments

    # === File Management ===
    ranger
    nautilus
    unzip
    zip
    p7zip

    # === Media & Graphics ===
    ffmpegthumbnailer
    gthumb

    # === Communication ===
    discord
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
  
  # Ghostty terminal
  programs.ghostty = {
    enable = true;
  };

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

  # Enable Catppuccin theming globally
  # Available flavors: "latte", "frappe", "macchiato", "mocha"
  # Available accents: "rosewater", "flamingo", "pink", "mauve", "red",
  #                    "maroon", "peach", "yellow", "green", "teal",
  #                    "sky", "sapphire", "blue", "lavender"
  catppuccin = {
    enable = true;
    flavor = "mocha";   # dark themes: mocha (darkest), macchiato, frappe | light: latte
    accent = "mauve";    # accent color for highlights
    
    # Cursor theme
    cursors = {
      enable = true;
      accent = "mauve";
    };
    
    # GTK icon theme (Papirus with catppuccin colors)
    gtk.icon.enable = true;
  };

  # GNOME settings via dconf
  dconf.settings = {
    "org/gnome/shell" = {
      favorite-apps = [
        "firefox.desktop"
        "org.gnome.Nautilus.desktop"
        "com.mitchellh.ghostty.desktop"
        "code.desktop"
        "discord.desktop"
        "org.gnome.Settings.desktop"
      ];
    };

    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      enable-hot-corners = false;
      clock-show-weekday = true;
      clock-show-seconds = false;
      show-battery-percentage = true;
    };

    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
      num-workspaces = 4;
    };

    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "list-view";
      search-filter-time-type = "last_modified";
      show-hidden-files = false;
    };

    "org/gnome/desktop/peripherals/mouse" = {
      natural-scroll = false;
      speed = 0.0;
      accel-profile = "flat";
    };

    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-type = "nothing";
      power-button-action = "interactive";
    };
  };
}
