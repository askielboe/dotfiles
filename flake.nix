{
  description = "nix configuration of askielboe";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";

    catppuccin.url = "github:catppuccin/nix";
    catppuccin.inputs.nixpkgs.follows = "nixpkgs";
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
          inherit system;
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
              users.${user}.imports = [
                sops-nix.homeManagerModules.sops
                nix-index-database.hmModules.nix-index
                { programs.nix-index-database.comma.enable = true; }
                nixvim.homeManagerModules.nixvim
                catppuccin.homeModules.catppuccin
                ./modules/home-manager
              ];
            };
          }
        ];
      };
    };
}
