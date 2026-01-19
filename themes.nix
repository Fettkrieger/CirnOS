{ config, pkgs, ... }:

{
  # === GTK Theme Configuration ===
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
    
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };

  # === Cursor Theme ===
  home.pointerCursor = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
    gtk.enable = true;
  };

  # === Qt Theming for GNOME Integration ===
  qt = {
    enable = true;
    platformTheme.name = "adwaita";
    style.name = "adwaita-dark";
  };

  # === GNOME Desktop Interface Theming ===
  dconf.settings = {
    # Color scheme - dark theme
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };
}
