{ ... }:

{
  # Shell aliases for bash
  programs.bash.shellAliases = {
    # Navigation
    ll = "ls -la";
    la = "ls -A";
    l = "ls -CF";
    
    # NixOS specific - using flake from /home/krieger/CirnOS
    rebuild = "sudo nixos-rebuild switch --flake /home/krieger/CirnOS#nixos";
    update = "cd /home/krieger/CirnOS && sudo nix flake update && sudo nixos-rebuild switch --flake .#nixos";
    cleanup = "sudo nix-collect-garbage -d && nix-collect-garbage -d";
    
    # Git shortcuts
    gs = "git status";
    ga = "git add";
    gc = "git commit";
    gp = "git push";
    gl = "git log --oneline --graph";
    gd = "git diff";
    
    # System info
    sysinfo = "neofetch";
    
    # Better ls with eza
    ls = "eza";
    
    # Better cat with bat
    cat = "bat";
    
    # Add more aliases below as needed
    # Examples:
    # cl = "clear";
    # .. = "cd ..";
    # ... = "cd ../..";
    # mkdir = "mkdir -p";
    # df = "df -h";
    # free = "free -h";
  };
}
