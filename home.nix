{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should manage
  home.username = "krieger";
  home.homeDirectory = "/home/krieger";

  # This value determines the Home Manager release that your configuration is compatible with
  # You should not change this value, even if you update Home Manager
  home.stateVersion = "24.11";

  # Packages that should be installed to your user profile
  home.packages = with pkgs; [
    # Development tools
    vscode
    
    # Utilities
    neofetch
    tree
    unzip
    zip
    p7zip
    
    # System monitoring
    btop
    
    # Media
    vlc
    mpv
    
    # Communication
    discord
    
    # Terminal tools
    ripgrep # Fast search tool (rg command)
    fd # Fast find alternative
    eza # Modern ls replacement
    bat # Cat with syntax highlighting
    
    # File management
    ranger # Terminal file manager
    
    # Add more packages as you need them
  ];

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
      user.email = "leandro.tiziani@protonmail.com"; # CHANGE THIS to your actual email
      init.defaultBranch = "main";
      pull.rebase = false;
    };
  };

  # Bash configuration with useful aliases
  programs.bash = {
    enable = true;
    
    shellAliases = {
      # Navigation
      ll = "ls -la";
      la = "ls -A";
      l = "ls -CF";
      
      # NixOS specific - using flake from /home/krieger/CirnOS
      rebuild = "sudo nixos-rebuild switch --flake /home/krieger/CirnOS#nixos";
      update = "cd /home/krieger/CirnOS && sudo nix flake update && sudo nixos-rebuild switch --flake .#nixos";
      cleanup = "sudo nix-collect-garbage -d && nix-collect-garbage -d";
      
      # Git shortcuts
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git log --oneline --graph";
      
      # System info
      sysinfo = "neofetch";
      
      # Better ls with eza
      ls = "eza";
      
      # Better cat with bat
      cat = "bat";
    };
    
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

    # Keyboard shortcuts
    "org/gnome/desktop/wm/keybindings" = {
      close = ["<Super>q"];
      switch-to-workspace-1 = ["<Super>1"];
      switch-to-workspace-2 = ["<Super>2"];
      switch-to-workspace-3 = ["<Super>3"];
      switch-to-workspace-4 = ["<Super>4"];
      move-to-workspace-1 = ["<Super><Shift>1"];
      move-to-workspace-2 = ["<Super><Shift>2"];
      move-to-workspace-3 = ["<Super><Shift>3"];
      move-to-workspace-4 = ["<Super><Shift>4"];
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
