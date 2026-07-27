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
        # In beets 2.x, MusicBrainz matching became an opt-in plugin. Without it
        # there is NO metadata backend: chroma fingerprints fine but has nothing
        # to resolve AcoustID hits against, so every import reports
        # "No matching release found". chroma is inert unless musicbrainz is on.
        "musicbrainz"
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
      # Bias candidate ranking toward plain CD releases. Chroma's AcoustID hits
      # otherwise surface DVD-Audio / SACD 5.1-mix editions that match a stereo
      # CD rip poorly (every track title differs by "(5.1 mix)"). This is an
      # ordered preference fed to match's add_priority: CD scores 0 on the
      # `media` field, everything else (DVD-Audio, SACD, Vinyl, Digital Media)
      # takes the full media penalty — a tiebreaker, not a hard filter, so
      # non-CD still matches when nothing better exists. If you start importing
      # digital-only releases, extend the list, e.g. [ "CD" "Digital Media" ],
      # so those aren't pushed to the floor too.
      match.preferred.media = [ "CD" ];
    };
  };
}
