# System-wide packages (available to all users)
{ pkgs, ... }:

{
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
