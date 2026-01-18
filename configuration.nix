# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Kernel - use latest for best hardware support (NVIDIA 5070 Ti and AMD 7800X3D)
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Kernel parameters for NVIDIA
  boot.kernelParams = [ 
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1" # For suspend/resume support
    "nvidia_drm.modeset=1" # Enable modesetting for Wayland
  ];

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Zurich";

  # Select internationalisation properties.
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

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "ch";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "sg";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;
    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # NVIDIA GPU configuration
  services.xserver.videoDrivers = [ "nvidia" ];

  # Enable OpenGL and graphics support
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Enable 32-bit support for gaming and compatibility
  };

  hardware.nvidia = {
    # Modesetting is required for Wayland compositors
    modesetting.enable = true;

    # Enable power management (set to false for desktops usually)
    powerManagement.enable = false;
    powerManagement.finegrained = false;

    # Use the proprietary NVIDIA driver (open source version not ready for RTX 5070 Ti yet)
    open = true;

    # Enable the NVIDIA settings menu (accessible via `nvidia-settings` command)
    nvidiaSettings = true;

    # Select the appropriate driver version
    # Using beta for newest GPU support (RTX 5070 Ti)
    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };

  # CPU microcode updates for AMD Ryzen 7800X3D
  hardware.cpu.amd.updateMicrocode = true;

  # GDM Wayland support with NVIDIA
  services.xserver.displayManager.gdm.wayland = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.krieger = {
    isNormalUser = true;
    description = "Krieger";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" ];
    packages = with pkgs; [
    #  thunderbird
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages (required for NVIDIA drivers)
  nixpkgs.config.allowUnfree = true;

  # Enable flakes and the new nix command (modern NixOS features)
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Automatic garbage collection to keep disk usage down
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # Optimize nix store automatically
  nix.settings.auto-optimise-store = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Text editor
    wget # Download utility
    curl # Transfer data utility
    git # Version control
    htop # Process viewer
    
    # GNOME utilities
    gnome-tweaks # Additional GNOME settings
    dconf-editor # Low-level GNOME settings editor
    
    # NVIDIA tools
    nvtopPackages.full # GPU monitoring tool (like htop for GPU)
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
