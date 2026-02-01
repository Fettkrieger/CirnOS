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
    # === Development ===
    vscode

    # === CLI Tools & Utilities ===
    fastfetch
    tree
    ripgrep
    fd
    yt-dlp
    libreoffice-fresh
    claude-code
    # Footage wrapped to use X11 (crashes on Wayland with NVIDIA due to Vulkan bug)
    (pkgs.symlinkJoin {
      name = "footage-x11";
      paths = [ pkgs.footage ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/footage --set GDK_BACKEND x11
      '';
    })
    ffmpeg

    # === GStreamer plugins (needed for Footage and video apps) ===
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
    

    

    # === File Management ===
    nautilus
    unzip
    zip
    p7zip

    # === Media & Graphics ===
    ffmpegthumbnailer
    gthumb
    inkscape

    # === System Utilities (replacing GNOME apps) ===
    pavucontrol                # Audio control (replaces GNOME sound settings)
    wdisplays                  # Display configuration for Wayland

    # === Communication ===

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
