{
  description = "Nix configuration";

  inputs = {
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";

    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    nixvim.url = "github:nix-community/nixvim/nixos-26.05";
    # nixvim uses it's own nixpkgs, see https://nix-community.github.io/nixvim/#recent-breaking-changes

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    catppuccin.url = "github:catppuccin/nix/release-26.05";

    packages.url = "path:./packages";
    packages.inputs.nixpkgs.follows = "nixpkgs";

    # sqlit: terminal UI for SQL databases. Its flake exposes lib.makeSqlit;
    # clickhouse-connect is added via an override in packages.nix.
    sqlit.url = "github:Maxteabag/sqlit";
    sqlit.inputs.nixpkgs.follows = "nixpkgs";

    # nix-homebrew: manage the Homebrew installation itself and pin the third-party
    # taps to flake.lock. Inputs must be declared here (flake rule); the module config
    # that consumes them lives in modules/darwin/settings/nix-homebrew.nix, reached via
    # specialArgs. homebrew-core/homebrew-cask are intentionally NOT inputs: they stay on
    # Homebrew's JSON API (matched to the installed brew) to avoid cask-DSL skew against
    # nix-homebrew's lagging brew. See that module for the full rationale.
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # Third-party taps (small, low-churn). `flake = false` raw checkouts, symlinked into
    # the Homebrew prefix; they move only on `nix flake update` (`hu`). Keep in sync with
    # the short-form `taps` list in modules/darwin/settings/homebrew.nix (Brewfile + trust).
    homebrew-herald = {
      url = "github:herald-email/homebrew-herald";
      flake = false;
    };
    homebrew-joncrangle = {
      url = "github:joncrangle/homebrew-tap";
      flake = false;
    };
    homebrew-nikitabobko = {
      url = "github:nikitabobko/homebrew-tap";
      flake = false;
    };
    homebrew-claude-history = {
      url = "github:raine/homebrew-claude-history";
      flake = false;
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      darwin,
      nix-index-database,
      nixvim,
      catppuccin,
      packages,
      sqlit,
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
              resticprofile = prev.resticprofile.overrideAttrs (old: {
                doCheck = false;
              }); # systemd subpkg is linux-only + a duration test asserts a stale Go stdlib error string
              pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
                (pyfinal: pyprev: {
                  pylint = pyprev.pylint.overridePythonAttrs (old: {
                    doCheck = false;
                  }); # parallel-execution test times out in the Nix sandbox
                  mcp = pyprev.mcp.overridePythonAttrs (old: {
                    doCheck = false;
                  }); # server integration tests can't bind ports in the Nix sandbox
                  portalocker = pyprev.portalocker.overridePythonAttrs (old: {
                    doCheck = false;
                  }); # multiprocess lock test times out in the Nix sandbox
                  pydantic-monty = pyprev.pydantic-monty.overridePythonAttrs (old: {
                    doCheck = false;
                  }); # test_limits gets killed (resource/timeout) in the Nix sandbox
                  cfn-lint = pyprev.cfn-lint.overridePythonAttrs (old: {
                    doCheck = false;
                  }); # quickstart-template integration tests assert stale exit codes
                  aiobotocore = pyprev.aiobotocore.overridePythonAttrs (old: {
                    doCheck = false;
                  }); # aiohttp test server can't bind in the Nix sandbox
                })
              ];
            })
            packages.overlays.default
          ];
        };
        specialArgs = { inherit private inputs; };
        modules = [
          ./modules/darwin
          inputs.determinate.darwinModules.default
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
                  sqlit
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
            sqlit
            ;
        };
        modules = homeManagerModules ++ [
          ./modules/home-manager
          ./modules/home-manager/linux-specific.nix
        ];
      };
    };
}
