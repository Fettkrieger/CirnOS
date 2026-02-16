# Common NixOS configuration shared across all hosts
{ config, pkgs, lib, inputs, hostname, ... }:

let
  sddmBlackBackground = pkgs.writeText "sddm-black-background.svg" ''
    <svg xmlns="http://www.w3.org/2000/svg" width="1920" height="1080" viewBox="0 0 1920 1080">
      <rect width="1920" height="1080" fill="#000000"/>
    </svg>
  '';

  sddmTheme = pkgs.catppuccin-sddm.override {
    flavor = "mocha";
    accent = "blue";
    font = "Noto Sans";
    fontSize = "10";
    background = sddmBlackBackground;
    clockEnabled = false;
    userIcon = false;
    loginBackground = true;
  };
in
{
  imports = [
    ./firewall.nix
    ./programs.nix
  ];

  # Set hostname from flake
  networking.hostName = hostname;

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable networking
  networking.networkmanager.enable = true;

  # Firmware updates via LVFS (includes UEFI/BIOS when supported)
  services.fwupd.enable = true;

  # Set your time zone
  time.timeZone = "Europe/Zurich";

  # Internationalisation
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_CH.UTF-8";
    LC_IDENTIFICATION = "de_CH.UTF-8";
    LC_MEASUREMENT = "de_CH.UTF-8";
    LC_MONETARY = "de_CH.UTF-8";
    LC_NAME = "de_CH.UTF-8";
    LC_NUMERIC = "de_CH.UTF-8";
    LC_PAPER = "de_CH.UTF-8";
    LC_TELEPHONE = "de_CH.UTF-8";
    LC_TIME = "de_CH.UTF-8";
  };

  # SDDM Display Manager
  services.xserver.enable = true;
  services.displayManager = {
    gdm.enable = false;
    sddm = {
      enable = true;
      theme = "catppuccin-mocha-blue";
      wayland.enable = true;
    };
  };

  # Install the selected SDDM theme so it is available in ThemeDir.
  environment.systemPackages = [ sddmTheme ];

  # Enable Niri compositor (niri-flake module handles session registration)
  programs.niri.enable = true;
  # niri-flake also starts a KDE polkit agent by default; disable it because
  # we use lxqt-policykit in Home Manager and multiple agents conflict.
  systemd.user.services.niri-flake-polkit.enable = false;

  # XDG Desktop Portal for Niri (file dialogs, screen sharing)
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome  # For ScreenCast/RemoteDesktop support
    ];
    # Override Niri's default portal ordering so apps that need file pickers
    # (e.g. Steam chat image upload) use GTK first.
    config.niri = {
      default = [ "gtk" "gnome" ];
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      # Keep GNOME backend for interfaces GTK does not implement.
      "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
      "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
      "org.freedesktop.impl.portal.RemoteDesktop" = [ "gnome" ];
      "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
    };
  };

  # Power management (can be overridden by hosts using TLP)
  services.power-profiles-daemon.enable = lib.mkDefault true;

  # GNOME Keyring for credential storage (used by apps like VS Code, browsers)
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.sddm.enableGnomeKeyring = true;

  # GVFS for Nautilus (trash, network mounts, MTP devices)
  services.gvfs.enable = true;


  # Configure keymap
  services.xserver.xkb = {
    layout = "ch";
    variant = "";
  };
  console.keyMap = "sg";

  # Enable CUPS printing
  services.printing.enable = true;

  # Enable sound with PipeWire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # User account
  users.users.krieger = {
    isNormalUser = true;
    description = "Krieger";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" ];
    packages = with pkgs; [];
  };

  # Firefox
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Allow insecure packages (qtwebengine-5 needed by teamspeak3)
  nixpkgs.config.permittedInsecurePackages = [
    "qtwebengine-5.15.19"
  ];

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Nix path
  nix.nixPath = [ "nixpkgs=/etc/channels/nixpkgs" ];

  # Automatic garbage collection (30 days retention)
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Optimize nix store
  nix.settings.auto-optimise-store = true;

  # Enable SSH daemon
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;  # Set to false after setting up SSH keys
    };
  };

  # Automatic system updates
  system.autoUpgrade = {
    enable = true;
    flake = "/home/krieger/CirnOS#${hostname}";
    dates = "weekly";
    allowReboot = false;  # Set to true if you want automatic reboots
  };

  # System state version
  system.stateVersion = "24.11";
}
