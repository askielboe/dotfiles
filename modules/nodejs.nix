{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nodejs_22
    nodePackages.npm
    nodePackages.prettier
  ];
}

