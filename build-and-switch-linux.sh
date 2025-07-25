#!/usr/bin/env bash

set -e

echo "Building home-manager configuration..."
env -i NIXPKGS_ALLOW_UNFREE=1 PATH="$PATH" nix --extra-experimental-features "nix-command flakes" build '.#homeConfigurations.askielboe.activationPackage' --impure

echo "Switching to new home-manager configuration..."
./result/activate