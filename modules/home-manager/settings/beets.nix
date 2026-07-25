{ ... }:
{
  # Beets music library manager, configured declaratively. Home Manager renders
  # `settings` below to $XDG_CONFIG_HOME/beets/config.yaml as a read-only symlink
  # into the Nix store — so config lives HERE, not in the file. `beet config -e`
  # and other in-place edits won't work; change the config by editing this module
  # and running `hs`.
  #
  # `plugins` only tells beets which plugins to LOAD. The default nixpkgs `beets`
  # package already bundles every builtin plugin's Python deps (it enables all
  # non-deprecated plugins at build time), so fetchart (beautifulsoup4, langdetect,
  # pillow, requests) and lyrics (beautifulsoup4, langdetect, requests) load with
  # no import errors and no package override. Add more from that set freely.
  programs.beets = {
    enable = true;

    settings = {
      # Where beets files imported music. beets expands ~ itself.
      directory = "~/Music";
      # SQLite library database.
      library = "~/Music/beets.db";
      plugins = [
        "fetchart" # download album art during import
        "lyrics" # fetch song lyrics
      ];
    };
  };
}
