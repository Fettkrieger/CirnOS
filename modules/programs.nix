# System-wide packages (available to all users)
{ pkgs, ... }:

{
  # Fonts (needed for waybar and other UI elements)
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    noto-fonts
    noto-fonts-color-emoji
  ];

  # Chromium browser
  programs.chromium.enable = true;

  # Keychron keyboard WebHID access (for launcher.keychron.com)
  services.udev.extraRules = ''
    # Keychron keyboards - allow WebHID access
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3434", MODE="0660", TAG+="uaccess"
  '';

  environment.systemPackages = with pkgs; [
    # === Essential Tools ===
    vim
    wget
    curl
    git
    python3
    chromium
    qbittorrent
    popsicle
    haruna
    logiops


    # === Window Management ===
    wmctrl

    # === GNOME Utilities ===
    dconf-editor
    
    # === Communication ===
    discord
  ];
}
