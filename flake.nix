{
  description = "CirnOS - Multi-host NixOS configuration with Home Manager";

  inputs = {
    # NixOS unstable channel for latest packages and NVIDIA drivers
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    # Home Manager for user-level configuration
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Catppuccin theming for NixOS and Home Manager
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Niri scrollable tiling Wayland compositor
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, catppuccin, niri, ... }@inputs:
    let
      system = "x86_64-linux";
      
      # Shared configuration function for all hosts
      mkHost = { hostname, hostConfig, enableGaming ? true }: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs hostname enableGaming; };
        
        modules = [
          # Catppuccin NixOS module
          catppuccin.nixosModules.catppuccin

          # Niri compositor NixOS module (includes home-manager integration)
          niri.nixosModules.niri
          { nixpkgs.overlays = [ niri.overlays.niri ]; }
          
          # Common configuration shared across all hosts
          ./modules/common.nix
          
          # Host-specific configuration
          hostConfig
          
          # Home Manager as a NixOS module
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
              extraSpecialArgs = { inherit inputs hostname enableGaming; };
              users.krieger = import ./home;
            };
          }
        ];
      };
    in
    {
      nixosConfigurations = {
        # Desktop PC (NZXT case with NVIDIA RTX 5070 Ti + AMD 7800X3D)
        nzxt-nix = mkHost {
          hostname = "nzxt-nix";
          hostConfig = ./hosts/nzxt-nix;
          enableGaming = true;
        };
        
        # HP Convertible Laptop (placeholder - configure hardware-configuration.nix after install)
        hp-laptop = mkHost {
          hostname = "hp-laptop";
          hostConfig = ./hosts/hp-laptop;
          enableGaming = false;  # Change to true if needed
        };
      };
    };
}
