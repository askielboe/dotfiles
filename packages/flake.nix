{
  description = "Custom packages";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    mcp-bear = {
      url = "github:jkawamoto/mcp-bear";
      flake = false;
    };
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
      mcp-bear,
      mcp-granola,
      mcp-things,
      ...
    }:
    let
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          mcp-bear = import ./mcp-bear.nix {
            inherit pkgs;
            src = mcp-bear;
          };
          mcp-granola = import ./mcp-granola.nix {
            inherit pkgs;
            src = mcp-granola;
          };
          mcp-things = import ./mcp-things.nix {
            inherit pkgs;
            src = mcp-things;
          };
          openclaw = import ./openclaw.nix { inherit pkgs; };
        }
      );
      overlays.default = final: _prev: {
        mcp-bear = import ./mcp-bear.nix {
          pkgs = final;
          src = mcp-bear;
        };
        mcp-granola = import ./mcp-granola.nix {
          pkgs = final;
          src = mcp-granola;
        };
        mcp-things = import ./mcp-things.nix {
          pkgs = final;
          src = mcp-things;
        };
        openclaw = import ./openclaw.nix { pkgs = final; };
      };
    };
}
