{ config, pkgs, ... }:

{
  # Import additional configuration modules
  imports = [
    ./keybindings.nix  # Keyboard shortcuts
    ./shellAliases.nix # Shell aliases
  ];

  # Home Manager needs a bit of information about you and the paths it should manage
  home.username = "krieger";
  home.homeDirectory = "/home/krieger";

  # This value determines the Home Manager release that your configuration is compatible with
  # You should not change this value, even if you update Home Manager
  home.stateVersion = "24.11";

  # Import user packages from programs.nix
  home.packages = (import ./programs.nix { inherit pkgs; }).userPackages;

  # Home Manager environment variables
  home.sessionVariables = {
    EDITOR = "vim";
    VISUAL = "vim";
  };

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # Git configuration
  programs.git = {
    enable = true;
    settings = {
      user.name = "Krieger";
      user.email = "your.email@example.com"; # CHANGE THIS to your actual email
      init.defaultBranch = "main";
      pull.rebase = false;
    };
  };

  # Bash configuration
  programs.bash = {
    enable = true;
    
    # Custom bash initialization
    bashrcExtra = ''
      # Custom prompt with color
      PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
      
      # Display system info on new terminal (optional, comment out if annoying)
      # neofetch
    '';
  };

  # GNOME-specific settings using dconf
  dconf.settings = {
    # GNOME shell favorite apps (pinned to dash/dock)
    "org/gnome/shell" = {
      favorite-apps = [
        "firefox.desktop"
        "org.gnome.Nautilus.desktop"
        "org.gnome.Terminal.desktop"
        "code.desktop"
        "discord.desktop"
        "org.gnome.Settings.desktop"
      ];
    };

    # GNOME desktop interface settings
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark"; # Use dark theme
      enable-hot-corners = false; # Disable hot corners
      clock-show-weekday = true;
      clock-show-seconds = false;
      show-battery-percentage = true;
    };

    # Window manager preferences
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
      num-workspaces = 4;
    };

    # Nautilus (file manager) preferences
    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "list-view";
      search-filter-time-type = "last_modified";
      show-hidden-files = false;
    };

    # Mouse settings
    "org/gnome/desktop/peripherals/mouse" = {
      natural-scroll = false;
      speed = 0.0;
      accel-profile = "flat"; # Disable mouse acceleration for gaming
    };

    # Power settings
    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-type = "nothing"; # Never sleep when plugged in
      power-button-action = "interactive"; # Ask what to do on power button
    };
  };

  # GTK theme configuration
  gtk = {
    enable = true;
    
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
    
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
    
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };

  # Cursor theme
  home.pointerCursor = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
    gtk.enable = true;
  };
}
