# Home Manager configuration for user krieger
{ config, pkgs, inputs, hostname, enableGaming, ... }:

{
  imports = [
    # Niri Home Manager module from niri-flake
    inputs.niri.homeModules.niri
    # Catppuccin Home Manager module
    inputs.catppuccin.homeModules.catppuccin
    
    ./keybindings.nix
    ./shellAliases.nix
    ./default-apps.nix
    ./themes.nix
    ./niri.nix
    ./waybar-niri.nix
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

    # === GNOME Extensions ===
    gnomeExtensions.caffeine
    gnomeExtensions.vitals
    gnomeExtensions.tiling-shell
    gnomeExtensions.clipboard-indicator

    # === Clipboard (for scripts/CLI) ===
    wl-clipboard
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
      enabled-extensions = [
        "caffeine@pataber.dev"
        "Vitals@CoreCoding.com"
        "tilingshell@ferrarodomenico.com"
        "clipboard-indicator@tudmotu.com"
      ];
    };

    # === Vitals Extension Settings ===
    "org/gnome/shell/extensions/vitals" = {
      hot-sensors = [
        "_temperature_gpu 0_"           # GPU temp (your 5070 Ti)
        "_temperature_processor 0_"     # CPU temp
        "_memory_usage_"                # RAM usage %
        "_network-rx_max_"              # Download speed
        "_network-tx_max_"              # Upload speed
      ];
      show-temperature = true;
      show-memory = true;
      show-network = true;
      show-processor = false;           # Disable CPU load (you want temp only)
      show-voltage = false;
      show-fan = false;
      show-storage = false;
      show-system = false;
      show-battery = false;
      show-gpu = true;
      position-in-panel = 2;            # 0=left, 1=center, 2=right
      update-time = 2;                  # Refresh every 2 seconds
      unit = 0;                         # 0=Celsius, 1=Fahrenheit
      network-speed-format = 0;         # 0=bytes, 1=bits
      alphabetize = false;
      hide-zeros = true;
      fixed-widths = true;
      hide-icons = false;
      include-static-gpu-info = false;
    };

    # === Caffeine Extension Settings ===
    "org/gnome/shell/extensions/caffeine" = {
      show-indicator = "always";        # "always", "only-active", "never"
      show-notifications = false;
    };

    # === Tiling Shell Extension Settings ===
    "org/gnome/shell/extensions/tilingshell" = {
      enable-tiling-system = true;
      show-indicator = true;            # Shows toggle in Quick Settings
    };

    # === Clipboard Indicator Extension Settings ===
    "org/gnome/shell/extensions/clipboard-indicator" = {
      toggle-menu = ["<Super>v"];
      history-size = 50;
      display-mode = 0;                 # 0=icon only
      disable-down-arrow = true;
      enable-keybindings = true;
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
