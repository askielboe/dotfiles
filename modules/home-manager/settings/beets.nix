{ pkgs, lib, ... }:
let
  beets-dynamicrange = pkgs.fetchFromGitHub {
    owner = "auchter";
    repo = "beets-dynamicrange";
    rev = "62fc157f85293d1d2dcc36b5afa33d5322cc8c5f";
    hash = "sha256-ALNGrpZOKdUE3g4np8Ms+0s8uWi6YixF2IVHSgaQVj4=";
  };
in
{
  programs.beets = {
    enable = true;
    settings = {
      directory = "~/annex/beets/music";
      plugins = [
        "musicbrainz"
        "chroma"
        "dynamicrange"
      ];
      pluginpath = [ "${beets-dynamicrange}/beetsplug" ];
      dynamicrange = {
        auto = true; # compute during import
        command = lib.getExe pkgs.dr14_tmeter;
      };
      match.preferred.media = [ "CD" ];
    };
  };
}
