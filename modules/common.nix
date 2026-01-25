# Common NixOS configuration shared across all hosts
{ config, pkgs, lib, inputs, hostname, ... }:

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

  # GDM Display Manager
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;

  # Enable Niri compositor (niri-flake module handles session registration)
  programs.niri.enable = true;

  # XDG Desktop Portal for Niri (file dialogs, screen sharing)
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome  # For file picker dialogs
    ];
  };

  # Power management (can be overridden by hosts using TLP)
  services.power-profiles-daemon.enable = lib.mkDefault true;

  # GNOME Keyring for credential storage (used by apps like VS Code, browsers)
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.gdm.enableGnomeKeyring = true;

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
