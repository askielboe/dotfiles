#!/usr/bin/env bash

# NixOS deployment script for remote server
# Usage: ./deploy-nixos.sh [hostname]

set -euo pipefail

HOSTNAME=${1:-nixos-server}
USER="askielboe"

echo "Deploying NixOS configuration to $HOSTNAME..."

# Make sure we have the latest hardware configuration
echo "Please ensure you have updated nixos/hardware-configuration.nix with the actual hardware config from your server"
echo "You can generate it on the target server with: nixos-generate-config --root /mnt"
echo "Press Enter to continue or Ctrl+C to abort..."
read -r

# Copy the flake to the server
echo "Copying configuration to server..."
rsync -av --exclude='.git' --exclude='result' . "$USER@$HOSTNAME":~/.config/nix/

# Build and switch on the server
echo "Building and switching to new configuration..."
ssh "$USER@$HOSTNAME" "cd ~/.config/nix && sudo nixos-rebuild switch --flake .#$HOSTNAME"

echo "Deployment complete!"
echo "You may need to log out and back in for shell changes to take effect."