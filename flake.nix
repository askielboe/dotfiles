{
  description = "nix configuration of askielboe";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    darwin.url = "github:nix-darwin/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    catppuccin.url = "github:catppuccin/nix";
    catppuccin.inputs.nixpkgs.follows = "nixpkgs";

    cachix.url = "github:cachix/cachix";
    cachix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      darwin,
      sops-nix,
      nix-index-database,
      nixvim,
      catppuccin,
      cachix,
      ...
    }:
    let
      darwinSystem = "aarch64-darwin";
      linuxSystem = "x86_64-linux";
      user = "askielboe";
      
      homeManagerModules = [
        sops-nix.homeManagerModules.sops
        nix-index-database.hmModules.nix-index
        { programs.nix-index-database.comma.enable = true; }
        nixvim.homeManagerModules.nixvim
        catppuccin.homeModules.catppuccin
        ./modules/shared
      ];
    in
    {
      # Darwin configuration (macOS)
      darwinConfigurations.swaggermis = darwin.lib.darwinSystem {
        system = darwinSystem;
        pkgs = import nixpkgs {
          system = darwinSystem;
          config.allowUnfree = true;
        };
        modules = [
          ./modules/darwin
          home-manager.darwinModules.home-manager
          sops-nix.darwinModules.sops
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit sops-nix nixvim; };
              users.${user}.imports = homeManagerModules ++ [
                ./modules/home-manager/darwin-specific.nix
              ];
            };
          }
        ];
      };

      # Home-manager standalone configuration for Ubuntu/Linux
      homeConfigurations.${user} = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = linuxSystem;
          config.allowUnfree = true;
        };
        extraSpecialArgs = { inherit sops-nix nixvim; };
        modules = homeManagerModules ++ [
          ./modules/home-manager/linux-specific.nix
        ];
      };
    };
}
