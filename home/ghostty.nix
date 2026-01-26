# Ghostty terminal configuration

{ config, pkgs, lib, ... }:

{
  programs.ghostty = {
    enable = true;
    
    settings = {
      # === Transparency ===
      background-opacity = 0.0s;
      
      # === Font Settings ===
      # font-family = "JetBrains Mono";
      # font-size = 12;
      
      # === Window Behavior ===
      window-padding-x = 8;
      window-padding-y = 8;
      window-decoration = true;
      
      # === Cursor ===
      cursor-style = "block";
      cursor-style-blink = true;
      
      # === Scrollback ===
      scrollback-limit = 10000;
      
      # === Misc ===
      copy-on-select = true;
      confirm-close-surface = false;
    };
  };
}
