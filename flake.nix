{
  description = "CirnOS - NixOS configuration with Home Manager";

  inputs = {
    # NixOS unstable channel for latest packages and NVIDIA drivers
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    # Home Manager for user-level configuration
    home-manager = {
      url = "github:nix-community/home-manager";
      # Make home-manager use the same nixpkgs as the system
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin.url = "github:catppuccin/nix";


  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      # System architecture (x86_64 for your AMD/NVIDIA setup)
      system = "x86_64-linux";
      
      # Import nixpkgs with configuration
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true; # Allow proprietary packages like NVIDIA drivers
      };
    in
    {
      # NixOS system configuration
      nixosConfigurations = {
        # Your hostname (must match networking.hostName in configuration.nix)
        nixos = nixpkgs.lib.nixosSystem {
          inherit system;
          
          modules = [
            # Main system configuration (located in /home/krieger/CirnOS/)
            ./configuration.nix
            
            # Home Manager as a NixOS module
            home-manager.nixosModules.home-manager
            {
              # Use system-level pkgs for home-manager
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              
              # Point to your home manager configuration (located in /home/krieger/CirnOS/)
              home-manager.users.krieger = import ./home.nix;
            }
          ];
        };
      };
    };
}
