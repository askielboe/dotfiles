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

echo "Building home-manager configuration (${TARGET})..."
# env -i for a clean, reproducible build env; HOME is preserved so the flake can
# locate the gitignored secrets/private.nix under $HOME (see privateFile in flake.nix).
env -i NIXPKGS_ALLOW_UNFREE=1 HOME="$HOME" USER="${USER:-$(id -un)}" PATH="$PATH" \
  nix --extra-experimental-features "nix-command flakes" build "$TARGET" --impure

echo "Switching to new home-manager configuration..."
./result/activate
