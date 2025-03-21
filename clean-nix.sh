#!/usr/bin/env bash

sudo rm -f /usr/local/bin/determinate-nixd

sudo rm -f /etc/bashrc
sudo rm -f /etc/zshrc

sudo rm -f /etc/zshrc.backup-before-nix
sudo rm -f /etc/bashrc.backup-before-nix
sudo rm -f /etc/bash.backup-before-nix
sudo rm -f /etc/profile.d/nix.sh.backup-before-nix
sudo rm -f /etc/bash.bashrc.backup-before-nix
sudo rm -f /etc/zsh/zshrc.backup-before-nix

sudo rm -f /etc/ssl/certs/ca-certificates.crt

sudo launchctl unload /Library/LaunchDaemons/org.nixos.nix-daemon.plist &> /dev/null
sudo rm -f /Library/LaunchDaemons/org.nixos.nix-daemon.plist
sudo launchctl unload /Library/LaunchDaemons/org.nixos.darwin-store.plist &> /dev/null
sudo rm -f /Library/LaunchDaemons/org.nixos.darwin-store.plist

sudo rm -rf /etc/nix

echo "Done!"
