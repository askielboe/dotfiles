{
  description = "nix configuration of askielboe";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    home-manager.url = "github:ttrssreal/home-manager/restic";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";

    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";

    catppuccin.url = "github:catppuccin/nix";
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      darwin,
      nix-index-database,
      agenix,
      nixvim,
      catppuccin,
      ...
    }:
    let
      system = "aarch64-darwin";
      user = "askielboe";
    in
    {
      darwinConfigurations.swaggermis = darwin.lib.darwinSystem {
        inherit system;
        pkgs = import nixpkgs {
          system = system;
          config.allowUnfree = true;
        };
        modules = [
          ./modules/darwin
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit agenix nixvim; };
              users.${user}.imports = [
                nix-index-database.hmModules.nix-index
                { programs.nix-index-database.comma.enable = true; }
                agenix.homeManagerModules.default
                nixvim.homeManagerModules.nixvim
                catppuccin.homeManagerModules.catppuccin
                ./modules/home-manager
              ];
            };
          }
        ];
      };
    };
}
