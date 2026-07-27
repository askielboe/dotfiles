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
      format_album = "$tech $albumartist – $album ($year)";
      plugins = [
        "musicbrainz"
        "chroma"
        "dynamicrange"
        "inline"
      ];
      # Fixed-width tech prefix for format_album, e.g. "16/44.1   DR9 (8–10)".
      # Computed from the album's tracks by the inline plugin; distinct values
      # are joined with "/" (a mixed album becomes "16/24/44.1/96"), the DR
      # min–max range collapses when all tracks match, and albums without
      # dynamicrange data yet show "DR?".
      album_fields.tech = ''
        srs = sorted({i.samplerate for i in items if i.samplerate})
        bds = sorted({i.bitdepth for i in items if i.bitdepth})
        q = "/".join([*(str(b) for b in bds), *(f"{s / 1000:g}" for s in srs)]) or "?"
        try:
            dr = f"DR{dr_avg}" + (f" ({dr_min}–{dr_max})" if dr_min != dr_max else "")
        except NameError:
            dr = "DR?"
        return f"{q:<9} {dr:<12}"
      '';
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
