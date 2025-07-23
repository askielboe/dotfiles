# Shared modules that work across both Darwin and NixOS
{
  imports = [
    ../sops
    ./nixvim
    ./shell.nix
    ./packages.nix
    ./home.nix
  ];
}