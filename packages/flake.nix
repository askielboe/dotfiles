{
  description = "MCP server packages";

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
  };

  outputs =
    {
      nixpkgs,
      mcp-bear,
      mcp-granola,
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
      };
    };
}
