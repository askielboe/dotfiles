{
  description = "nix configuration of askielboe";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    nixvim.url = "github:nix-community/nixvim/nixos-25.05";
    # nixvim uses it's own nixpkgs, see https://nix-community.github.io/nixvim/#recent-breaking-changes

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    catppuccin.url = "github:catppuccin/nix/release-25.05";
    catppuccin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      darwin,
      nix-index-database,
      nixvim,
      catppuccin,
      ...
    }:
    let
      darwinSystem = "aarch64-darwin";
      linuxSystem = "x86_64-linux";
      user = "askielboe";

      homeManagerModules = [
        nix-index-database.homeModules.nix-index
        { programs.nix-index-database.comma.enable = true; }
        nixvim.homeManagerModules.nixvim
        catppuccin.homeModules.catppuccin
      ];
    in
    {
      # Darwin configuration (macOS)
      darwinConfigurations.${user} = darwin.lib.darwinSystem {
        system = darwinSystem;
        pkgs = import nixpkgs {
          system = darwinSystem;
          config.allowUnfree = true;
        };
        modules = [
          ./modules/darwin
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit nixvim nixpkgs-unstable; };
              users.${user}.imports = homeManagerModules ++ [
                ./modules/home-manager
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
        extraSpecialArgs = { inherit nixvim nixpkgs-unstable; };
        modules = homeManagerModules ++ [
          ./modules/home-manager
          ./modules/home-manager/linux-specific.nix
        ];
      };
    };
}
