# Central sops-nix wiring: every decrypted artifact is declared here.
# Secrets decrypt at ACTIVATION (launchd agent org.nix-community.home.sops-nix
# on darwin, a user systemd unit on Linux), so nothing sensitive ever enters
# the world-readable nix store — an improvement over the old private.nix era,
# where the rendered ssh/aws configs all sat in /nix/store in plaintext.
#
# Edit secrets with `sops secrets/secrets.yaml` from the repo root (the age
# recipient comes from .sops.yaml; SOPS_AGE_KEY_FILE is exported by
# darwin/settings/environment.nix and settings/shell.nix). Decrypted files are
# stable symlinks, so they must be edited here rather than in-app — an in-app
# save would replace the symlink.
{ config, ... }:
{
  sops = {
    defaultSopsFile = ../../../secrets/secrets.yaml; # in-tree, tracked → part of the pure flake source
    # Runtime string, NOT a nix path literal: the gitignored age key must never
    # be copied into the store. Same location on darwin and Linux.
    age.keyFile = "${config.home.homeDirectory}/.config/nix/modules/sops/age/keys.txt";

    secrets = {
      # ssh_config fragment with the private Host blocks; pulled in via
      # `Include config.d/private` from programs.ssh (settings/ssh.nix).
      "ssh-config".path = "${config.home.homeDirectory}/.ssh/config.d/private";
      # INI with credential_process (1Password item refs) + region for the
      # [default] and [work] profiles; aws CLI follows the symlink.
      "aws-credentials".path = "${config.home.homeDirectory}/.aws/credentials";
      # Consumed at use-time by path: OP_ACCOUNT export (settings/shell.nix)
      # and the `ch` clickhouse wrapper (settings/clickhouse.nix).
      "op-account" = { };
      "clickhouse-host" = { };
      "clickhouse-user" = { };
      "clickhouse-op-item" = { };
    };
  };
}
