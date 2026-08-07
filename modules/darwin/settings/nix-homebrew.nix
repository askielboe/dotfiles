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
#
# REMOVING a tap here needs a manual follow-up. nix-homebrew places taps as
# root-owned read-only trees, and with mutableTaps = true it does NOT delete one
# you drop from this attrset — the directory stays behind, unmanaged. The next
# activation's `brew bundle --cleanup` then tries to untap it as the user and dies
# with "Permission denied @ apply2files", failing the whole switch. So after
# deleting an entry here (and its flake input), also run:
#   sudo rm -rf /opt/homebrew/Library/Taps/<owner>/homebrew-<name>
# Hit 2026-08-07 by three stale taps at once: hamed-elfayome, herald-email, joncrangle.
#
# Removing the tap directory is only half of it: any formula still INSTALLED from
# that tap is now unresolvable, and `brew bundle --force-cleanup` errors out rather
# than uninstalling it — "No available formula with the name <owner>/<tap>/<name>.
# This command requires the tap <owner>/<tap>." — which again fails the switch. So
# uninstall the tap's packages BEFORE (or right after) dropping it:
#   brew uninstall --force <name>
# `brew leaves` is the check: every entry must be a formula the Brewfile declares.
# Hit 2026-08-07 by herald (herald-email) and sketchybar-system-stats (joncrangle),
# left behind when those taps went away.
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
      "macos-fuse-t/homebrew-cask" = inputs.homebrew-fuse-t;
      "nikitabobko/homebrew-tap" = inputs.homebrew-nikitabobko;
      "raine/homebrew-claude-history" = inputs.homebrew-claude-history;
    };
  };
}
