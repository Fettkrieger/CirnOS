# Theme configuration (Noctalia-default aligned GTK, Qt, and cursors)
{ pkgs, ... }:

let
  # Ship all mocha cursor variants so runtime switching can pick the closest color.
  catppuccinMochaCursorThemes = pkgs.symlinkJoin {
    name = "catppuccin-mocha-cursors";
    paths = [
      pkgs.catppuccin-cursors.mochaRosewater
      pkgs.catppuccin-cursors.mochaFlamingo
      pkgs.catppuccin-cursors.mochaPink
      pkgs.catppuccin-cursors.mochaMauve
      pkgs.catppuccin-cursors.mochaRed
      pkgs.catppuccin-cursors.mochaMaroon
      pkgs.catppuccin-cursors.mochaPeach
      pkgs.catppuccin-cursors.mochaYellow
      pkgs.catppuccin-cursors.mochaGreen
      pkgs.catppuccin-cursors.mochaTeal
      pkgs.catppuccin-cursors.mochaSky
      pkgs.catppuccin-cursors.mochaSapphire
      pkgs.catppuccin-cursors.mochaBlue
      pkgs.catppuccin-cursors.mochaLavender
    ];
  };
in
{
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
      name = "catppuccin-mocha-blue-cursors";
      package = catppuccinMochaCursorThemes;
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
    platformTheme.name = "adwaita";
    style.name = "adwaita-dark";
  };
}
