{ pkgs, ... }:
{
  home.packages = with pkgs; [
    (python312.withPackages (ps: with ps; [
      ipython
      jupyter
      matplotlib
      numpy
      requests
      ruff
      scipy
      torch
      uv
    ]))
  ];
}

