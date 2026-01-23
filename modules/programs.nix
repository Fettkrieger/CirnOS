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

  environment.systemPackages = with pkgs; [
    # === Essential Tools ===
    vim
    wget
    curl
    git

    # === System Monitoring ===
    htop
    nvtopPackages.full

    # === Window Management ===
    wmctrl

    # === GNOME Utilities ===
    gnome-tweaks
    dconf-editor
  ];
}
