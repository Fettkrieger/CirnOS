# Ghostty terminal configuration

{ config, pkgs, lib, ... }:

{
  programs.ghostty = {
    enable = true;
    settings = {
      # === Appearance ===
      "background-opacity" = 0.8;  # Transparency level (0.0 = fully transparent, 1.0 = opaque)
      "background-color" = "#1e1e2e";  # Background color
      "foreground-color" = "#cdd6f4";  # Text color
      "cursor-color" = "#89b4fa";      # Cursor color
      "selection-color" = "#45475a";   # Selection highlight color
      "font-family" = "JetBrainsMono Nerd Font";  # Font family
      "font-size" = 14;  # Font size in points




      # === Advanced ===
      "scrollback-lines" = 10000;  # Number of lines to keep in scrollback
      "bell" = false;             # Disable terminal bell
      "hide-decorations" = false; # Show window decorations
      "padding" = 10;             # Padding around text in pixels
    };
  };
}
