{
  description = "Home Manager configuration of askielboe";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/master";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin.url = "github:catppuccin/nix";
  };

  outputs = { nixpkgs, home-manager, nix-index-database, agenix, catppuccin, ... }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      homeConfigurations."askielboe" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        modules = [
          ./home.nix
          nix-index-database.hmModules.nix-index
          { programs.nix-index-database.comma.enable = true; }
          agenix.homeManagerModules.default
          catppuccin.homeManagerModules.catppuccin
        ];

        extraSpecialArgs = {
          inherit agenix;
        };
      };
    };
}
