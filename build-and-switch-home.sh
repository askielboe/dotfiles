#!/usr/bin/env bash

set -e

echo "Building home-manager configuration..."
nix --extra-experimental-features "nix-command flakes" build '.#homeConfigurations.askielboe.activationPackage'

echo "Switching to new home-manager configuration..."
./result/activate