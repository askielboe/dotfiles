{
  description = "Nix configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    nixvim.url = "github:nix-community/nixvim/nixos-25.11";
    # nixvim uses it's own nixpkgs, see https://nix-community.github.io/nixvim/#recent-breaking-changes

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    catppuccin.url = "github:catppuccin/nix/release-25.11";
    catppuccin.inputs.nixpkgs.follows = "nixpkgs";

    packages.url = "path:./packages";
    packages.inputs.nixpkgs.follows = "nixpkgs";

    addy-skills = {
      url = "github:addyosmani/agent-skills";
      flake = false;
    };
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
      packages,
      addy-skills,
      ...
    }:
    let
      darwinSystem = "aarch64-darwin";
      linuxSystem = "x86_64-linux";

      privateFile =
        let
          darwinPath = /Users/askielboe/.config/nix/secrets/private.nix;
          linuxPath = /home/askielboe/.config/nix/secrets/private.nix;
        in
        if builtins.pathExists darwinPath then
          darwinPath
        else if builtins.pathExists linuxPath then
          linuxPath
        else
          null;
      private =
        if privateFile != null then
          import privateFile
        else
          throw "Missing secrets/private.nix - copy from secrets/private.example.nix and fill in your values";
      user = private.user.username;

      homeManagerModules = [
        nix-index-database.homeModules.nix-index
        { programs.nix-index-database.comma.enable = true; }
        nixvim.homeModules.nixvim
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
          overlays = [
            (final: prev: {
              direnv = prev.direnv.overrideAttrs (old: {
                doCheck = false;
              }); # fish tests get killed in Nix sandbox on macOS
            })
            packages.overlays.default
          ];
        };
        specialArgs = { inherit private; };
        modules = [
          ./modules/darwin
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {
                inherit
                  nixvim
                  nixpkgs-unstable
                  private
                  addy-skills
                  ;
              };
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
        extraSpecialArgs = {
          inherit
            nixvim
            nixpkgs-unstable
            private
            addy-skills
            ;
        };
        modules = homeManagerModules ++ [
          ./modules/home-manager
          ./modules/home-manager/linux-specific.nix
        ];
      };
    };
}
