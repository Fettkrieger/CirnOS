# Theme configuration (GTK, Qt, Cursors)
# Note: Most theming is handled by the catppuccin module in default.nix
{ config, pkgs, lib, ... }:

{
  # Theme packages
  home.packages = with pkgs; [
    adwaita-qt
    adwaita-qt6
    qgnomeplatform
    qgnomeplatform-qt6
    gnome-themes-extra
    libsForQt5.qtstyleplugin-kvantum  # Kvantum for Qt5
    kdePackages.qtstyleplugin-kvantum # Kvantum for Qt6
  ];

  # GTK configuration (let catppuccin handle the theme)
  gtk = {
    enable = true;
    
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
    
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };

  # Qt configuration with Catppuccin via Kvantum
  qt = {
    enable = true;
    platformTheme.name = "kvantum";
    style.name = "kvantum";
  };
}
