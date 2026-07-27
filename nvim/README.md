# nvim — standalone nixvim child flake

Inspired by <https://github.com/elythh/nixvim>.

Nixvim options search: <https://nix-community.github.io/nixvim/search/>.

This directory is its own flake (own `flake.lock`, pinned independently of the
parent) built via nixvim's standalone `makeNixvimWithModule`. Options use
nixvim's bare tree — no `programs.nixvim.` prefix, and no `enable` (that option
only exists in the home-manager/NixOS wrappers).

Why: the nixvim module system costs ~11s of single-threaded eval. As a pure
child flake it is built by a pre-step (`just build-nvim`, run automatically by
`hs` and the build-and-switch scripts) into a gc-rooted out-link under
`.gc-roots/`, and the parent home-manager config consumes only the prebuilt
store path — so the 11s is paid only when files in this directory (or
`flake.lock` here) change. Without a gc-root the parent falls back to
evaluating this module in-process (slow but always correct).

Build/update:

- `just build-nvim` — build + refresh the gc-root (automatic in `hs`)
- `just update-nvim` — bump this flake's own nixvim/nixpkgs pins, then rebuild
- `nix build path:$PWD/nvim` — manual build (`path:` keeps the eval cache keyed
  on this directory only; a bare `./nvim` would key on the whole repo)
