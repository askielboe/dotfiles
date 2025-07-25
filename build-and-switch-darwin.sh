#!/usr/bin/env bash

set -e

nix --extra-experimental-features "nix-command flakes" build '.#darwinConfigurations.askielboe.system'

sudo rm -f /etc/bashrc
sudo rm -f /etc/zshrc

./result/sw/bin/darwin-rebuild switch --flake ~/.config/nix/'.#askielboe'
