{ config, pkgs, ... }:

{
  # === Theme Packages ===
  home.packages = with pkgs; [
    # Adwaita (default GNOME theme)
    adwaita-qt         # Adwaita theme for Qt5
    adwaita-qt6        # Adwaita theme for Qt6
    qgnomeplatform     # Qt5 platform theme for GNOME
    qgnomeplatform-qt6 # Qt6 platform theme for GNOME
    gnome-themes-extra # Extra GNOME themes

    # Popular dark themes
    dracula-theme      # Dracula dark theme
    catppuccin         # Catppuccin theme collection
    catppuccin-cursors # Catppuccin cursor theme
    yaru-theme         # Ubuntu Yaru theme
    
    # Icon themes
    papirus-icon-theme # Papirus icon theme
    papirus-folders    # Folder icons for Papirus
  ];

  # === GTK Theme Configuration ===
  gtk = {
    enable = true;
    
    theme = {
      name = "Catppuccin-Mocha";
      package = pkgs.catppuccin;
    };
    
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };

  # === Cursor Theme ===
  home.pointerCursor = {
    name = "catppuccin-frappe-blue-cursors";
    package = pkgs.catppuccin-cursors;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # === Qt Theming for GNOME Integration ===
  qt = {
    enable = true;
    platformTheme.name = "gtk3";
    style.name = "gtk2";
  };

  # === GNOME Desktop Interface Theming ===
  dconf.settings = {
    # Color scheme - dark theme
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };
}
