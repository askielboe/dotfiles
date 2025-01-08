# This secrets.nix file is not imported into your NixOS configuration. It's
# only used for the agenix CLI tool (example below) to know which public keys
# to use for encryption.
# https://github.com/ryantm/agenix?tab=readme-ov-file#tutorial
let
  user = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFnR+/By643WRc+CguO23Xj8JHkxiGycAkgs5pVLa4K6";
in
{
  "anthropic.age".publicKeys = [ user ];
  "rclone.age".publicKeys = [ user ];
}
