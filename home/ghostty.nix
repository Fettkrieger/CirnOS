# Ghostty terminal configuration

{ config, pkgs, lib, ... }:

{
  programs.ghostty = {
    enable = true;
    settings = {
      # Transparency + blur
      background-opacity = 0.8;  # 0.0 = transparent, 1.0 = opaque
      background-blur = true;

      # Noctalia default dark colors
      background = "070722";
      foreground = "f3edf7";
      cursor-color = "fff59b";
      cursor-text = "070722";
      selection-background = "21215F";
      selection-foreground = "f3edf7";

      # Terminal 16-color palette (Noctalia aligned)
      palette = [
        "0=#070722"
        "1=#FD4663"
        "2=#9BFECE"
        "3=#fff59b"
        "4=#a9aefe"
        "5=#a9aefe"
        "6=#9BFECE"
        "7=#f3edf7"
        "8=#21215F"
        "9=#FD4663"
        "10=#9BFECE"
        "11=#fff59b"
        "12=#c4c8ff"
        "13=#c4c8ff"
        "14=#d8d4e6"
        "15=#ffffff"
      ];
    };

  };
}
