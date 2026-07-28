{
  description = "Nix configuration";

  inputs = {
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";

    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # sops-nix decrypts secrets/secrets.yaml (age key in modules/sops/age, NOT
    # in the store) at home-manager activation. Only the HM module is used —
    # every secret consumer here is user-level, so one wiring covers darwin
    # and the standalone Linux configs alike.
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

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
    homebrew-nikitabobko = {
      url = "github:nikitabobko/homebrew-tap";
      flake = false;
    };
    homebrew-claude-history = {
      url = "github:raine/homebrew-claude-history";
      flake = false;
    };
    homebrew-claude-usage = {
      url = "github:hamed-elfayome/homebrew-claude-usage";
      flake = false;
    };
    homebrew-fuse-t = {
      url = "github:macos-fuse-t/homebrew-cask";
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
      sops-nix,
      sqlit,
      ...
    }:
    let
      darwinSystem = "aarch64-darwin";
      # arm64 everywhere is the primary Linux target; x86_64 is kept so the
      # occasional Intel box (and an emulated CI leg) stay buildable. Both are
      # produced from one mkLinuxHome helper (below) to stay DRY.
      linuxSystems = [
        "aarch64-linux"
        "x86_64-linux"
      ];
      defaultLinuxSystem = "aarch64-linux";

      # Non-sensitive eval-time settings, tracked in-tree — this is what keeps
      # the flake pure (no --impure anywhere). Sensitive values live in
      # secrets/secrets.yaml (sops-encrypted, also tracked) and are decrypted
      # at activation by sops-nix, never at eval.
      private = import ./secrets/settings.nix;
      user = private.user.username;

      homeManagerModules = [
        sops-nix.homeManagerModules.sops
        nix-index-database.homeModules.nix-index
        { programs.nix-index-database.comma.enable = true; }
        nixvim.homeModules.nixvim
        catppuccin.homeModules.catppuccin
      ];

      # Overlays shared by every platform. Applying them on Linux too is what makes
      # the standalone home-manager build work: packages.overlays.default is the only
      # source of mcp-granola/mcp-things/specify-cli, and the doCheck=false overrides
      # below are needed there as well (resticprofile's systemd test is Linux-only-broken).
      sharedOverlays = [
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

      mkPkgs =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = sharedOverlays;
        };

      # Standalone home-manager (Ubuntu/Linux), one config per supported arch.
      mkLinuxHome =
        system:
        home-manager.lib.homeManagerConfiguration {
          pkgs = mkPkgs system;
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
    in
    {
      # Darwin configuration (macOS)
      darwinConfigurations.${user} = darwin.lib.darwinSystem {
        system = darwinSystem;
        pkgs = mkPkgs darwinSystem;
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

      # Home-manager standalone configurations for Ubuntu/Linux. The bare `${user}`
      # name is the arm64 default (used by `hs` / `home-manager switch .#${user}`);
      # arch-suffixed names (`${user}-aarch64-linux`, `${user}-x86_64-linux`) let the
      # build script and CI target a specific arch.
      homeConfigurations = {
        ${user} = mkLinuxHome defaultLinuxSystem;
      }
      // builtins.listToAttrs (
        map (system: {
          name = "${user}-${system}";
          value = mkLinuxHome system;
        }) linuxSystems
      );
    };
}
