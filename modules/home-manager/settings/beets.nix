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
      # Keep duplicate albums (same albumartist + album, e.g. a remaster next
      # to the original) side by side instead of prompting at import.
      import.duplicate_action = "keep";
      # Directory suffix for such duplicates — first listed field that differs
      # across all versions wins, and a version with an empty value gets no
      # suffix: hand-set "version" flex field (beet modify -a <query>
      # version='2020 remaster 24bit'), else the MB disambiguation comment
      # ("remaster", "deluxe edition"), else year.
      aunique.disambiguators = "version albumdisambig year label";
    };
  };
}
