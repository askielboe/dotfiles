# nix-homebrew: manage the Homebrew installation itself and pin the third-party
# taps to flake.lock. This module owns "which revision of each third-party tap";
# the Brewfile (settings/homebrew.nix) owns "which packages". Input declarations
# live in flake.nix (the only place flake inputs can be declared) and reach this
# module via specialArgs (`inputs`).
#
# autoMigrate takes over the existing /opt/homebrew install in place. mutableTaps
# = true leaves homebrew-core/homebrew-cask on Homebrew's JSON API, which serves
# formula/cask definitions matched to the installed brew. We deliberately do NOT
# pin core/cask: nix-homebrew ships a lagging brew (6.0.9), but cask HEAD adopts
# new cask-DSL as soon as it lands on brew master, so a pinned cask races ahead of
# the brew and breaks `brew bundle` (e.g. proxyman's delete_keychain_certificate).
# The three third-party taps ARE pinned (small, low-churn, the real supply-chain
# surface). Their KEYS use Homebrew's on-disk repo form (owner/homebrew-<name>);
# the short-form Brewfile refs in settings/homebrew.nix resolve to the same dirs.
{ inputs, private, ... }:
{
  imports = [ inputs.nix-homebrew.darwinModules.nix-homebrew ];

  nix-homebrew = {
    enable = true;
    enableRosetta = false;
    user = private.user.username;
    autoMigrate = true;
    mutableTaps = true;
    taps = {
      "hamed-elfayome/homebrew-claude-usage" = inputs.homebrew-claude-usage;
      "herald-email/homebrew-herald" = inputs.homebrew-herald;
      "macos-fuse-t/homebrew-cask" = inputs.homebrew-fuse-t;
      "nikitabobko/homebrew-tap" = inputs.homebrew-nikitabobko;
      "raine/homebrew-claude-history" = inputs.homebrew-claude-history;
    };
  };
}
