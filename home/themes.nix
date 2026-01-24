# Theme configuration (GTK, Qt, Cursors, Catppuccin)
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

  # Catppuccin theming
  # Available flavors: "latte", "frappe", "macchiato", "mocha"
  # Available accents: "rosewater", "flamingo", "pink", "mauve", "red",
  #                    "maroon", "peach", "yellow", "green", "teal",
  #                    "sky", "sapphire", "blue", "lavender"
  catppuccin = {
    enable = true;
    flavor = "mocha";   # dark themes: mocha (darkest), macchiato, frappe | light: latte
    accent = "lavender";    # accent color for highlights
    
    # Cursor theme
    cursors = {
      enable = true;
      accent = "lavender";
    };
    
    # GTK icon theme (Papirus with catppuccin colors)
    gtk.icon.enable = true;
  };
}
