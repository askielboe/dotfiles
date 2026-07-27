#!/usr/bin/env bash

set -euo pipefail

# Target home-manager configuration. Defaults to the current user (which matches
# private.user.username on a real box); override with an explicit name as $1.
NAME="${1:-${USER:-$(id -un)}}"

case "$(uname -m)" in
aarch64 | arm64) ARCH="aarch64-linux" ;;
x86_64) ARCH="x86_64-linux" ;;
*)
  echo "Unsupported architecture: $(uname -m)" >&2
  exit 1
  ;;
esac

# The flake produces an arch-suffixed config for every supported Linux arch.
TARGET=".#homeConfigurations.${NAME}-${ARCH}.activationPackage"

# Prebuild the standalone nixvim child flake into a gc-rooted out-link so the
# main eval consumes a store path (settings/nvim.nix) instead of re-running
# nixvim's ~11s module eval. Pure build (no --impure) so its eval cache can hit;
# path: ref so only nvim/ contents key that cache.
echo "Prebuilding standalone nixvim (${ARCH})..."
mkdir -p "$HOME/.config/nix/.gc-roots"
nix --extra-experimental-features "nix-command flakes" build \
  "path:$PWD/nvim" --out-link "$HOME/.config/nix/.gc-roots/nvim-${ARCH}"

echo "Building home-manager configuration (${TARGET})..."
# env -i for a clean, reproducible build env. Pure eval: secrets/settings.nix and
# the sops-encrypted secrets/secrets.yaml are tracked in-tree, and allowUnfree is
# set at every in-flake nixpkgs import.
env -i HOME="$HOME" USER="${USER:-$(id -un)}" PATH="$PATH" \
  nix --extra-experimental-features "nix-command flakes" build "$TARGET"

echo "Switching to new home-manager configuration..."
./result/activate
