# Ghostty terminal configuration

{ config, pkgs, lib, ... }:

{
  programs.ghostty = {
    enable = true;
    settings = {
      background-opacity = 0.8;  # Background transparency (0.0 = fully transparent, 1.0 = opaque)
      # Optional: blur behind the terminal (if compositor supports it)
      # background-blur-radius = 20;
    };

  };
}
