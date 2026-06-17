{ lib, private, ... }:

# pi-mlx-models' `/mlx-init` finds its Python interpreter by probing a hardcoded
# list of absolute paths (it ignores $PATH and exposes no override env var):
#   /opt/homebrew/bin/python3.{13,12,11,10}, /opt/homebrew/bin/python3,
#   /usr/local/bin/python3, /usr/bin/python3
# and accepts the first that reports version 3.10–3.13. On this machine only
# /usr/bin/python3 exists, and it's macOS's 3.9.6 (too old); our nix python 3.12
# lives at /etc/profiles/per-user/<user>/bin and is never checked.
#
# So expose the nix python at one of the probed paths. /usr/local/bin is the
# only non-Homebrew, non-system candidate, so symlink the user-profile python3
# there. This reuses the interpreter from settings/python.nix — no second,
# brew-managed Python. The target is the stable per-user profile path (not a
# store path), so it survives python upgrades without re-pointing.
let
  nixPython = "/etc/profiles/per-user/${private.user.username}/bin/python3";
in
{
  # nix-darwin only executes a fixed set of activation-script keys; a custom key
  # would be silently dropped, so hook into the supported `postActivation`.
  # mkAfter keeps it composable with any other module's postActivation text.
  system.activationScripts.postActivation.text = lib.mkAfter ''
    mkdir -p /usr/local/bin
    ln -sfn ${nixPython} /usr/local/bin/python3
  '';
}
