#!/usr/bin/env bash

set -e

# Prebuild the standalone nixvim child flake (see settings/nvim.nix). Without
# this the build still works via the slow in-eval fallback.
mkdir -p "$HOME/.config/nix/.gc-roots"
nix --extra-experimental-features "nix-command flakes" build \
  "path:$PWD/nvim" --out-link "$HOME/.config/nix/.gc-roots/nvim-aarch64-darwin"

nix --extra-experimental-features "nix-command flakes" build '.#darwinConfigurations.askielboe.system'

sudo rm -f /etc/bashrc
sudo rm -f /etc/zshrc

./result/sw/bin/darwin-rebuild switch --flake ~/.config/nix/'.#askielboe'
