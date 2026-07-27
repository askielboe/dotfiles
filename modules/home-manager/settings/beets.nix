{ pkgs, lib, ... }:
let
  beets-dynamicrange = pkgs.fetchFromGitHub {
    owner = "auchter";
    repo = "beets-dynamicrange";
    rev = "62fc157f85293d1d2dcc36b5afa33d5322cc8c5f"; # current HEAD
    hash = "sha256-ALNGrpZOKdUE3g4np8Ms+0s8uWi6YixF2IVHSgaQVj4=";
  };
in
{
  # Beets music library manager, configured declaratively. Home Manager renders
  # `settings` below to $XDG_CONFIG_HOME/beets/config.yaml as a read-only symlink
  # into the Nix store — so config lives HERE, not in the file. `beet config -e`
  # and other in-place edits won't work; change the config by editing this module
  # and running `hs`.
  programs.beets = {
    enable = true;
    settings = {
      plugins = [
        "chroma"
        "dynamicrange"
      ];
      # dynamicrange is a third-party plugin (not bundled with nixpkgs' beets),
      # loaded from a pinned checkout rather than the default plugin search path.
      pluginpath = [ "${beets-dynamicrange}/beetsplug" ];
      dynamicrange = {
        auto = true; # compute during import
        command = lib.getExe pkgs.dr14_tmeter; # store path, no PATH dependency
      };
    };
  };
}
