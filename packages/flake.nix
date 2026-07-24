{
  description = "Custom packages";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    mcp-granola = {
      url = "github:proofgeist/granola-ai-mcp-server";
      flake = false;
    };
    mcp-things = {
      url = "github:hald/things-mcp";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      mcp-granola,
      mcp-things,
      ...
    }:
    let
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems f;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          mcp-granola = import ./mcp-granola.nix {
            inherit pkgs;
            src = mcp-granola;
          };
          mcp-things = import ./mcp-things.nix {
            inherit pkgs;
            src = mcp-things;
          };
          specify-cli = import ./specify-cli.nix {
            inherit pkgs;
          };
        }
      );
      overlays.default = final: _prev: {
        mcp-granola = import ./mcp-granola.nix {
          pkgs = final;
          src = mcp-granola;
        };
        mcp-things = import ./mcp-things.nix {
          pkgs = final;
          src = mcp-things;
        };
        specify-cli = import ./specify-cli.nix {
          pkgs = final;
        };
      };
    };
}
