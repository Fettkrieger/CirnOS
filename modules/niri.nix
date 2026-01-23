# Niri Wayland compositor - system-level configuration
{ config, pkgs, lib, ... }:

{
  # Enable niri compositor (from niri-flake)
  programs.niri.enable = true;

  # Required services for niri
  security.polkit.enable = true;
  
  # XDG Desktop Portal for screen sharing, file dialogs, etc.
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];
  };

  # Enable dbus for communication
  services.dbus.enable = true;

  # Keyring for password management
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.gdm.enableGnomeKeyring = true;

  # System packages needed for niri session
  environment.systemPackages = with pkgs; [
    # Wayland essentials
    wayland
    wl-clipboard
    cliphist       # Clipboard history
    
    # Screenshot & screen recording
    grim           # Screenshot utility
    slurp          # Region selection
    
    # Notification daemon
    mako
    libnotify
    
    # App launcher
    fuzzel
    
    # Status bar
    waybar
    
    # Wallpaper
    swaybg
    
    # Screen locking
    swaylock
    swayidle
    
    # Brightness & volume control
    brightnessctl
    pamixer
    playerctl
    
    # Authentication agent
    polkit_gnome
    
    # File manager that works well with Wayland
    nautilus
    
    # Network management applet
    networkmanagerapplet
    
    # Bluetooth
    blueman
  ];

  # Environment variables for Wayland
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";  # Electron apps on Wayland
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
    GDK_BACKEND = "wayland,x11";
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";
    XDG_SESSION_TYPE = "wayland";
  };
}
