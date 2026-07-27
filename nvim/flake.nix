{
  description = "Standalone nixvim — prebuilt by the hs pre-step so its ~11s module eval stays off the rebuild hot path";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    # nixvim keeps its own internal nixpkgs pin for module evaluation; the
    # nixpkgs input above only supplies pkgs (extraPackages, vimPlugins, ...).
    nixvim.url = "github:nix-community/nixvim/nixos-26.05";
  };

  outputs =
    { nixpkgs, nixvim, ... }:
    let
      # Same three systems as the parent flake's darwin + Linux configurations.
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems f;
    in
    {
      packages = forAllSystems (system: rec {
        nvim = nixvim.legacyPackages.${system}.makeNixvimWithModule {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          module = ./default.nix;
        };
        default = nvim;
      });
    };
}
