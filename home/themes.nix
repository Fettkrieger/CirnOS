# Theme configuration (Noctalia-default aligned GTK, Qt, and cursors)
{ config, pkgs, lib, ... }:

{
  # Theme packages
  home.packages = with pkgs; [
    adwaita-qt
    adwaita-qt6
    adwaita-icon-theme
    qgnomeplatform
    qgnomeplatform-qt6
    gnome-themes-extra
    swaybg
    swww
  ];

  # GTK configuration (dark defaults compatible with Noctalia default scheme)
  gtk = {
    enable = true;

    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };

    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };

    cursorTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
      size = 24;
    };
    
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
    
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };

  # Qt configuration matching GTK dark style
  qt = {
    enable = true;
    platformTheme.name = "gnome";
    style.name = "adwaita-dark";
  };
}
