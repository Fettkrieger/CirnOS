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
  };
  
  # Bash functions and custom initialization
  programs.bash.bashrcExtra = ''
    # Custom prompt with color
    PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
    
    # Display system info on new terminal (optional, comment out if annoying)
    # neofetch
    
    # Git commit and push function for CirnOS
    # Usage: gcpCirnOS "your commit message"
    gcpCirnOS() {
      if [ -z "$1" ]; then
        echo "Error: Please provide a commit message"
        echo "Usage: gcpCirnOS \"your commit message\""
        return 1
      fi
      cd /home/krieger/CirnOS && git add . && git commit -m "$*" && git push
    }
  '';
}
