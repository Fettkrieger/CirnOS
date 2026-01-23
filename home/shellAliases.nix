# Shell aliases for bash
{ config, ... }:

{
  programs.bash = {
    shellAliases = {
      # Navigation
      ll = "ls -la";
      la = "ls -A";
      l = "ls -CF";
      
      # NixOS specific - dynamic hostname detection
      rebuild = "sudo nixos-rebuild switch --flake ${config.home.homeDirectory}/CirnOS#$(hostname)";
      update = "cd ${config.home.homeDirectory}/CirnOS && sudo nix flake update && sudo nixos-rebuild switch --flake .#$(hostname)";
      cleanup = "sudo nix-collect-garbage -d && nix-collect-garbage -d";
      
      # Git shortcuts for CirnOS
      gaaCirnOS = "cd ${config.home.homeDirectory}/CirnOS && git add .";
      gcCirnOS = "cd ${config.home.homeDirectory}/CirnOS && git commit";
      gpCirnOS = "cd ${config.home.homeDirectory}/CirnOS && git push";
      gsCirnOS = "cd ${config.home.homeDirectory}/CirnOS && git status";
      
      # Git shortcuts (general)
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git log --oneline --graph";
      gd = "git diff";
      
      # System info
      sysinfo = "fastfetch";
      
      # Better ls with eza
      ls = "eza";
      
      # Better cat with bat
      cat = "bat";
    };
  };
}
