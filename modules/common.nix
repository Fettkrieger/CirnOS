# Common NixOS configuration shared across all hosts
{ config, pkgs, inputs, hostname, ... }:

{
  imports = [
    ./firewall.nix
    ./programs.nix
    ./niri.nix
  ];

  # Set hostname from flake
  networking.hostName = hostname;

  # Catppuccin system-wide theming (for GDM login screen)
  # Available flavors: "latte", "frappe", "macchiato", "mocha"
  # Available accents: "rosewater", "flamingo", "pink", "mauve", "red",
  #                    "maroon", "peach", "yellow", "green", "teal",
  #                    "sky", "sapphire", "blue", "lavender"
  catppuccin = {
    enable = true;
    flavor = "mocha";   # dark themes: mocha (darkest), macchiato, frappe | light: latte
    accent = "mauve";    # accent color for highlights
    
    # Cursors for GDM
    cursors = {
      enable = true;
      accent = "mauve";
    };
    
    # Icons for GDM
    gtk.icon.enable = true;
  };

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

  # Enable X11 and GNOME
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

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
