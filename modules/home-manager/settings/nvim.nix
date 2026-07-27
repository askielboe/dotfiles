# Prebuilt standalone nixvim. The nvim/ child flake (own flake.lock) is built
# by the hs / build-and-switch pre-step into a gc-rooted out-link under
# .gc-roots/; here we only reference the RESULT as a store path, which keeps
# nixvim's ~11s module-system eval off every rebuild. If no usable gc-root
# exists (fresh machine, `just check-linux` for a foreign arch, GC'd root
# without the pre-step) we fall back to evaluating the same module tree
# in-process via the nixvim flake input — slow but always correct.
{
  pkgs,
  lib,
  nixvim,
  private,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  u = private.user.username;
  # Same resolution order as privateFile in flake.nix: $HOME first (any user,
  # e.g. CI), then the two known machines. getEnv is "" under pure eval, which
  # skips that candidate; the parent eval is --impure on every real entry point.
  envHome = builtins.getEnv "HOME";
  candidates =
    lib.optional (envHome != "") "${envHome}/.config/nix/.gc-roots/nvim-${system}"
    ++ [
      "/Users/${u}/.config/nix/.gc-roots/nvim-${system}"
      "/home/${u}/.config/nix/.gc-roots/nvim-${system}"
    ];
  # Probe THROUGH the symlink for the binary: pathExists on the out-link itself
  # returns true even when the root dangles after a GC (verified), which would
  # send builtins.storePath into a hard "no substituter" error instead of the
  # fallback. bin/nvim only resolves when the store path is actually alive.
  gcRoot = lib.findFirst (p: builtins.pathExists "${p}/bin/nvim") null candidates;
  nvim =
    if gcRoot != null then
      # builtins.storePath resolves the out-link to its /nix/store target and
      # returns it with string context (types.package coerces it) — no nixvim
      # eval happens on this branch. Only legal under --impure, which is the
      # only mode that can see the gc-root candidates in the first place.
      builtins.storePath gcRoot
    else
      # In-eval fallback: same module tree the child flake builds, evaluated
      # against the parent's pkgs. The laziness of this `if` is load-bearing —
      # don't refactor it into an eagerly-evaluated attrset.
      nixvim.legacyPackages.${system}.makeNixvimWithModule {
        inherit pkgs;
        module = ../../../nvim;
      };
in
{
  home.packages = [ nvim ];
}
